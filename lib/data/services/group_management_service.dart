import 'package:supabase_flutter/supabase_flutter.dart';

class GroupManagementService {
  final SupabaseClient _client;

  GroupManagementService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<void> updateTitle({required String conversationId, required String title}) async {
    final clean = title.trim();
    if (clean.isEmpty || clean.length > 100) {
      throw Exception('Group title must be between 1 and 100 characters.');
    }
    await _client.rpc('update_group_title', params: <String, dynamic>{
      'p_conversation_id': conversationId,
      'p_title': clean,
    });
  }

  Future<void> addMember({required String conversationId, required String userId}) async {
    if (userId.isEmpty) throw Exception('Choose a valid user.');
    await _client.rpc('add_group_member', params: <String, dynamic>{
      'p_conversation_id': conversationId,
      'p_user_id': userId,
    });
  }

  Future<void> leaveGroup(String conversationId) async {
    await _client.rpc('leave_group_conversation', params: <String, dynamic>{
      'p_conversation_id': conversationId,
    });
  }
}
