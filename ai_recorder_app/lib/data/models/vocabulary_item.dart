import 'package:isar/isar.dart';

part 'vocabulary_item.g.dart';

@collection
class VocabularyItem {
  Id id = Isar.autoIncrement;

  /// 关联到 User.id
  late int userId;

  /// 专属词汇
  late String word;
}

