import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/isar_service.dart';
import '../data/models/record_item.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  String _searchQuery = '';

  Future<List<RecordItem>> _loadRecords() async {
    final user = context.read<AppState>().currentUser;
    if (user == null) return [];
    final isar = await IsarService.open();

    // 无搜索词：直接按时间倒序返回
    if (_searchQuery.trim().isEmpty) {
      return isar.recordItems
          .filter()
          .userIdEqualTo(user.id)
          .sortByCreatedAtDesc()
          .findAll();
    }

    final keyword = _searchQuery.trim();

    // 1) 标题命中
    final titleMatches = await isar.recordItems
        .filter()
        .userIdEqualTo(user.id)
        .and()
        .titleContains(keyword, caseSensitive: false)
        .findAll();

    // 2) 转写全文命中
    final transcriptRecordIds = await isar.transcriptItems
        .filter()
        .textContentContains(keyword, caseSensitive: false)
        .recordIdProperty()
        .findAll();

    final transcriptMatches = transcriptRecordIds.isEmpty
        ? <RecordItem>[]
        : await isar.recordItems
            .filter()
            .userIdEqualTo(user.id)
            .and()
            .anyOf(transcriptRecordIds, (q, id) => q.idEqualTo(id))
            .findAll();

    // 合并去重
    final map = <int, RecordItem>{};
    for (final r in titleMatches) {
      map[r.id] = r;
    }
    for (final r in transcriptMatches) {
      map[r.id] = r;
    }

    final results = map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('全部录音'),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索文件名或转写内容...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          FutureBuilder<List<RecordItem>>(
            future: _loadRecords(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              var records = snapshot.data!;

              if (_searchQuery.isNotEmpty) {
                records = records
                    .where((r) =>
                        r.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              if (records.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        const Text('还没有任何录音'),
                        const SizedBox(height: 4),
                        const Text(
                          '点击底部中间的大麦克风按钮开始录音',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = records[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () {
                            context.go('/record/${record.id}');
                          },
                          title: Text(record.title),
                          subtitle: Text(
                            '${record.createdAt} • ${record.durationSeconds}s',
                          ),
                          trailing: Text(
                            record.status,
                            style: TextStyle(
                              color: record.status == 'completed'
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: records.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

