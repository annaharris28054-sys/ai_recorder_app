import 'package:isar/isar.dart';

import '../data/isar_service.dart';
import '../data/models/record_item.dart';
import '../data/models/transcript_item.dart';
import '../data/models/ai_summary_item.dart';

/// 本地 AI 引擎占位实现。
///
/// 当前版本使用简单规则生成转写与总结，方便联调 UI 与数据流。
/// 后续可按 sheji/development.md 中说明，将内部实现替换为
/// whisper_flutter_plus + fllama 的真实推理逻辑。
class LocalSttService {
  Future<void> transcribeRecord(int recordId) async {
    final isar = await IsarService.open();

    final record = await isar.recordItems.get(recordId);
    if (record == null) return;

    // 已完成的录音不再重复转写
    if (record.status == 'completed') return;

    final totalSeconds = record.durationSeconds;
    final segmentLength = totalSeconds ~/ 3 == 0 ? 10 : totalSeconds ~/ 3;

    final segments = <TranscriptItem>[];
    var start = 0;
    var index = 0;

    while (start < totalSeconds) {
      final end = (start + segmentLength).clamp(0, totalSeconds);
      final item = TranscriptItem()
        ..recordId = record.id
        ..speakerName = index == 0 ? '发言人A' : '发言人B'
        ..startTimeMs = start * 1000
        ..endTimeMs = end * 1000
        ..textContent = '占位转写片段 ${index + 1}，后续由 Whisper 本地模型生成真实文本。'
        ..tagType = null;
      segments.add(item);
      start = end;
      index++;
    }

    // 将手动打点时间与片段对齐，打上 manual_mark
    for (final mark in record.markSeconds) {
      for (final seg in segments) {
        if (mark * 1000 >= seg.startTimeMs && mark * 1000 < seg.endTimeMs) {
          seg.tagType = 'manual_mark';
          break;
        }
      }
    }

    await isar.writeTxn(() async {
      await isar.transcriptItems
          .filter()
          .recordIdEqualTo(record.id)
          .deleteAll();
      await isar.transcriptItems.putAll(segments);
      record.status = 'completed';
      await isar.recordItems.put(record);
    });
  }
}

class LocalSummaryService {
  Future<void> generateSummary(int recordId) async {
    final isar = await IsarService.open();
    final record = await isar.recordItems.get(recordId);
    if (record == null) return;

    final transcripts = await isar.transcriptItems
        .filter()
        .recordIdEqualTo(recordId)
        .findAll();

    if (transcripts.isEmpty) return;

    final fullText = transcripts.map((t) => t.textContent).join('\n');

    final tags = <String>[
      '会议记录',
      if (fullText.length > 50) '长文本',
    ];
    final conclusions = <String>[
      '该总结由本地占位逻辑生成，后续可替换为 LLM 模型输出。',
    ];
    final todos = <SummaryTodoItem>[
      SummaryTodoItem()..task = '根据录音内容补充真实待办事项'..done = false,
    ];

    final summary = AISummaryItem()
      ..recordId = recordId
      ..tags = tags
      ..conclusions = conclusions
      ..todos = todos;

    await isar.writeTxn(() async {
      await isar.aISummaryItems
          .filter()
          .recordIdEqualTo(recordId)
          .deleteAll();
      await isar.aISummaryItems.put(summary);
    });
  }
}

