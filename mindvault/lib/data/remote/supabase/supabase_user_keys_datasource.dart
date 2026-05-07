import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';

class UserKeyRecord {
  final String wrappedKey;
  final String salt;

  const UserKeyRecord({required this.wrappedKey, required this.salt});

  factory UserKeyRecord.fromJson(Map<String, dynamic> json) => UserKeyRecord(
        wrappedKey: json['wrapped_key'] as String,
        salt: json['salt'] as String,
      );
}

class SupabaseUserKeysDatasource {
  final SupabaseClient _client;

  SupabaseUserKeysDatasource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<UserKeyRecord?> fetchUserKey() async {
    final response = await _client
        .from(SupabaseConstants.userKeysTable)
        .select('wrapped_key, salt')
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) return null;
    return UserKeyRecord.fromJson(response);
  }

  Future<void> upsertUserKey({
    required String wrappedKey,
    required String salt,
  }) async {
    await _client.from(SupabaseConstants.userKeysTable).upsert({
      'user_id': _userId,
      'wrapped_key': wrappedKey,
      'salt': salt,
    });
  }
}
