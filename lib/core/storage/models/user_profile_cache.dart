import 'package:isar/isar.dart';

part 'user_profile_cache.g.dart';

@collection
class UserProfileCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId;
  late String name;
  late String email;
  late String phone;
  late String role;
  late DateTime lastSyncedAt;
}
