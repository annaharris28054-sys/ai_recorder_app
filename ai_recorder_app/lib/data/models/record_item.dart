import 'package:isar/isar.dart';

part 'record_item.g.dart';

@collection
class RecordItem {
  Id id = Isar.autoIncrement;

  /// 关联到 User.id
  late int userId;

  /// 录音标题
  late String title;

  /// 本地音频文件路径
  late String filePath;

  /// 时长（秒）
  late int durationSeconds;

   /// 手动打点时间（秒）列表，用于与转写片段对齐
   late List<int> markSeconds;

  /// 状态：recording / transcribing / completed
  late String status;

  /// 创建时间
  late DateTime createdAt;
}

