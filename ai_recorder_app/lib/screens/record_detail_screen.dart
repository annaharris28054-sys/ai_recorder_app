import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/isar_service.dart';
import '../data/models/record_item.dart';
import '../data/models/transcript_item.dart';
import '../data/models/ai_summary_item.dart';

class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final int recordId;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  late Future<RecordItem?> _recordFuture;
  late Future<List<TranscriptItem>> _transcriptsFuture;
  late Future<AISummaryItem?> _summaryFuture;
  final _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _isPlaying = false;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _recordFuture = _loadRecord();
    _transcriptsFuture = _loadTranscripts();
    _summaryFuture = _loadSummary();
    _player.onPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
    });
    _player.onDurationChanged.listen((d) {
      setState(() {
        _duration = d;
      });
    });
    _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<RecordItem?> _loadRecord() async {
    final isar = await IsarService.open();
    return isar.recordItems.get(widget.recordId);
  }

  Future<List<TranscriptItem>> _loadTranscripts() async {
    final isar = await IsarService.open();
    return isar.transcriptItems
        .filter()
        .recordIdEqualTo(widget.recordId)
        .sortByStartTimeMs()
        .findAll();
  }

  Future<AISummaryItem?> _loadSummary() async {
    final isar = await IsarService.open();
    return isar.aISummaryItems
        .filter()
        .recordIdEqualTo(widget.recordId)
        .findFirst();
  }

  Future<void> _togglePlay(RecordItem record) async {
    if (_isPlaying) {
      await _player.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _player.play(DeviceFileSource(record.filePath));
      await _player.setPlaybackRate(_speed);
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _seekRelative(int seconds) async {
    final newPosition = _position + Duration(seconds: seconds);
    await _player.seek(
      Duration(
        seconds: newPosition.inSeconds.clamp(0, _duration.inSeconds),
      ),
    );
  }

  void _toggleSpeed() async {
    if (_speed == 1.0) {
      _speed = 1.5;
    } else if (_speed == 1.5) {
      _speed = 2.0;
    } else {
      _speed = 1.0;
    }
    await _player.setPlaybackRate(_speed);
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<RecordItem?>(
      future: _recordFuture,
      builder: (context, snapshot) {
        final record = snapshot.data;
        if (record == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(record.title),
          ),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('AI 总结'),
                      selected: _activeTabIndex == 0,
                      onSelected: (_) {
                        setState(() {
                          _activeTabIndex = 0;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('全文转写'),
                      selected: _activeTabIndex == 1,
                      onSelected: (_) {
                        setState(() {
                          _activeTabIndex = 1;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _activeTabIndex == 0
                    ? _buildSummaryTab(theme)
                    : _buildTranscriptTab(theme),
              ),
              _buildPlayerBar(theme, record),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(ThemeData theme) {
    return FutureBuilder<AISummaryItem?>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        if (summary == null) {
          return const Center(
            child: Text('AI 总结生成中或尚未生成'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.tags
                  .map((t) => Chip(
                        label: Text('#$t'),
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.08),
                        labelStyle: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade500, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '核心结论',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...summary.conclusions.map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(c)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            color: Colors.orange.shade500, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '待办事项',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...summary.todos.map(
                      (t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: t.done,
                              onChanged: (_) {},
                            ),
                            Expanded(child: Text(t.task)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTranscriptTab(ThemeData theme) {
    return FutureBuilder<List<TranscriptItem>>(
      future: _transcriptsFuture,
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text('转写生成中或尚未生成'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final start =
                Duration(milliseconds: item.startTimeMs).inSeconds.toString();
            final isActive = _position.inMilliseconds >= item.startTimeMs &&
                _position.inMilliseconds < item.endTimeMs;

            Color? bg;
            if (item.tagType == 'manual_mark') {
              bg = Colors.yellow.shade50;
            } else if (item.tagType == 'ai_keypoint') {
              bg = Colors.purple.shade50;
            }

            return Container(
              decoration: BoxDecoration(
                color: isActive ? (bg ?? theme.highlightColor) : bg,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      start.padLeft(4, '0'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.speakerName,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (item.tagType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.tagType == 'manual_mark'
                                      ? Colors.yellow.shade100
                                      : Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.tagType == 'manual_mark'
                                      ? '手动打点'
                                      : 'AI 重点',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: item.tagType == 'manual_mark'
                                        ? Colors.orange.shade800
                                        : Colors.purple.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.textContent),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerBar(ThemeData theme, RecordItem record) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Expanded(
                child: Slider(
                  value: _duration.inMilliseconds == 0
                      ? 0
                      : _position.inMilliseconds
                          .clamp(0, _duration.inMilliseconds)
                          .toDouble(),
                  max: _duration.inMilliseconds == 0
                      ? 1
                      : _duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _player.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _toggleSpeed,
                child: Text('${_speed.toStringAsFixed(1)}x'),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _seekRelative(-15),
                    icon: const Icon(Icons.replay_10_rounded),
                  ),
                  GestureDetector(
                    onTap: () => _togglePlay(record),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _seekRelative(15),
                    icon: const Icon(Icons.forward_10_rounded),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  // TODO: 播放时打点并写回 Transcript
                },
                icon: const Icon(Icons.flag_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

