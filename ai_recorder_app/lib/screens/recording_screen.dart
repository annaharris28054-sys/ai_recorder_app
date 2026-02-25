import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../data/isar_service.dart';
import '../data/models/record_item.dart';
import '../state/app_state.dart';
import '../services/local_ai_engine.dart';
import 'package:provider/provider.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _recorder = AudioRecorder();
  final List<int> _marks = [];
  bool _isRecording = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有录音权限')),
      );
      Navigator.of(context).pop();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/recordings/${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
    });

    if (path == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final user = context.read<AppState>().currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final isar = await IsarService.open();
    int recordId;
    await isar.writeTxn(() async {
      final record = RecordItem()
        ..userId = user.id
        ..title = '新录音 ${DateTime.now().toLocal()}'
        ..filePath = path
        ..durationSeconds = _elapsedSeconds
        ..markSeconds = List<int>.from(_marks)
        ..status = 'transcribing'
        ..createdAt = DateTime.now();
      recordId = await isar.recordItems.put(record);
    });

    // 启动本地转写与总结流水线（当前为占位实现）
    // 实际项目中可替换为 Isolate + whisper_flutter_plus + fllama 调用
    // 并在通知栏或详情页展示进度。
    // 这里无需等待完成即可返回列表。
    // ignore: unawaited_futures
    LocalSttService().transcribeRecord(recordId).then((_) {
      // 完成转写后自动生成占位总结
      // ignore: unawaited_futures
      LocalSummaryService().generateSummary(recordId);
    });

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _togglePause() async {
    if (_isPaused) {
      await _recorder.resume();
    } else {
      await _recorder.pause();
    }
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _addMark() {
    setState(() {
      _marks.add(_elapsedSeconds);
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF15162B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'AI 智能记录中...',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const Text(
                    '深度降噪已开启',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(_elapsedSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: AudioWaveforms(
                enableGesture: false,
                size: const Size(double.infinity, 120),
                recorderController:
                    RecorderController()..updateFrequency = const Duration(milliseconds: 100),
                waveStyle: WaveStyle(
                  waveColor: theme.colorScheme.primary,
                  extendWaveform: true,
                  showMiddleLine: false,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_marks.isNotEmpty)
              Text(
                '已打点 ${_marks.length} 处关键节点',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundButton(
                    icon: Icons.flag_rounded,
                    label: '打点',
                    onTap: _addMark,
                  ),
                  GestureDetector(
                    onTap: _stopRecording,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.stop_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  _RoundButton(
                    icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause,
                    label: _isPaused ? '继续' : '暂停',
                    onTap: _togglePause,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

