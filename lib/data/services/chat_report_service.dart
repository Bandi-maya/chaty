import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists user-generated chat reports through the existing RLS-protected
/// `reports` table. Success is returned only after Supabase accepts the row.
class ChatReportService {
  final SupabaseClient _client;

  ChatReportService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<void> reportMessage({
    required String conversationId,
    required String messageId,
    String reason = 'user_report',
  }) async {
    final reporterId = _client.auth.currentUser?.id;
    if (reporterId == null) {
      throw Exception('Sign in before reporting a message.');
    }
    if (conversationId.isEmpty || messageId.isEmpty) {
      throw Exception('The message could not be identified for reporting.');
    }

    await _client.from('reports').insert(<String, dynamic>{
      'reporter_id': reporterId,
      'conversation_id': conversationId,
      'message_id': messageId,
      'reason': reason,
    });
  }
}
