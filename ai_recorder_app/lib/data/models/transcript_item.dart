import 'package:isar/isar.dart';

part 'transcript_item.g.dart';

@collection
class TranscriptItem {
  Id id = Isar.autoIncrement;

  /// 关联到 RecordItem.id
  late int recordId;

  /// 发言人名称
  late String speakerName;

  /// 起始时间（毫秒）
  late int startTimeMs;

  /// 结束时间（毫秒）
  late int endTimeMs;

  /// 转写内容
  late String textContent;

  /// 标签类型：null / manual_mark / ai_keypoint
  String? tagType;
}

