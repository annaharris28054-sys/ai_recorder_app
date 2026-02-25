import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  late String username;

  /// 存储加盐后的密码哈希
  late String passwordHash;
}

