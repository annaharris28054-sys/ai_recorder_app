import 'package:isar/isar.dart';

part 'ai_summary_item.g.dart';

@collection
class AISummaryItem {
  Id id = Isar.autoIncrement;

  /// 关联到 RecordItem.id
  late int recordId;

  /// 标签列表，如 ["产品规划", "AI升级"]
  late List<String> tags;

  /// 核心结论列表
  late List<String> conclusions;

  /// 待办事项列表
  late List<SummaryTodoItem> todos;
}

@embedded
class SummaryTodoItem {
  late String task;
  bool done = false;
}

