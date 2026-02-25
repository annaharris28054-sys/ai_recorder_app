import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/isar_service.dart';
import '../data/models/vocabulary_item.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _noiseMode = 'smart'; // off, smart, deep
  final _templateController = TextEditingController();
  final _vocabController = TextEditingController();
  List<VocabularyItem> _vocabularies = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _templateController.dispose();
    _vocabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = context.read<AppState>().currentUser;
    final isar = await IsarService.open();
    final vocabs = user == null
        ? <VocabularyItem>[]
        : await isar.vocabularyItems
            .filter()
            .userIdEqualTo(user.id)
            .findAll();
    setState(() {
      _noiseMode = prefs.getString('noise_mode') ?? 'smart';
      _vocabularies = vocabs;
    });
  }

  Future<void> _updateNoiseMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('noise_mode', mode);
    setState(() {
      _noiseMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '多模式降噪',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildNoiseTile(
                  id: 'off',
                  title: '关闭降噪',
                  subtitle: '保留环境原声',
                ),
                const Divider(height: 0),
                _buildNoiseTile(
                  id: 'smart',
                  title: '智能降噪（推荐）',
                  subtitle: '平衡人声与背景音',
                ),
                const Divider(height: 0),
                _buildNoiseTile(
                  id: 'deep',
                  title: '深度降噪',
                  subtitle: '嘈杂环境专用，极致人声提取',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '自定义总结模板（占位）',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前版本仅提供占位输入，实际模板逻辑由本地 LLM 使用时接入。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _templateController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '例如：请用项目背景 / 关键决策 / 待办三段结构输出会议纪要……',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '专属词库管理',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '添加行业术语、人名，用于提升转写准确率（后续接入 Whisper 热词功能）。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _vocabularies
                        .map(
                          (v) => Chip(
                            label: Text(v.word),
                            onDeleted: () => _removeVocab(v),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _vocabController,
                          decoration: const InputDecoration(
                            hintText: '输入专业词汇，例如：Qwen2、声纹聚类、客户A公司名…',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addVocab,
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoiseTile({
    required String id,
    required String title,
    required String subtitle,
  }) {
    return RadioListTile<String>(
      value: id,
      groupValue: _noiseMode,
      onChanged: (value) {
        if (value != null) {
          _updateNoiseMode(value);
        }
      },
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Future<void> _addVocab() async {
    final text = _vocabController.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AppState>().currentUser;
    if (user == null) return;

    final isar = await IsarService.open();
    final vocab = VocabularyItem()
      ..userId = user.id
      ..word = text;

    await isar.writeTxn(() async {
      await isar.vocabularyItems.put(vocab);
    });

    _vocabController.clear();
    _loadSettings();
  }

  Future<void> _removeVocab(VocabularyItem vocab) async {
    final isar = await IsarService.open();
    await isar.writeTxn(() async {
      await isar.vocabularyItems.delete(vocab.id);
    });
    _loadSettings();
  }
}

