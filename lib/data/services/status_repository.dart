import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/status_update.dart';

class StatusRepository extends ChangeNotifier {
  StatusRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final List<StatusUpdate> _items = <StatusUpdate>[];
  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _loading = false;
  String? _error;

  List<StatusUpdate> get items => List<StatusUpdate>.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
    _subscribe();
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _client
          .from('status_updates')
          .select()
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false);
      _items
        ..clear()
        ..addAll(
          (raw as List)
              .map(
                (row) => StatusUpdate.fromMap(
                  Map<String, dynamic>.from(row as Map),
                ),
              )
              .where((status) => !status.isExpired),
        );
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<StatusUpdate> create({
    required String content,
    required String mediaType,
    String? mediaPath,
    String? mimeType,
    String backgroundGradient = 'indigo_purple',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Authentication required.');
    if (content.trim().isEmpty && (mediaPath == null || mediaPath.isEmpty)) {
      throw Exception('Add text or media before publishing a status.');
    }

    final raw = await _client
        .from('status_updates')
        .insert(<String, dynamic>{
          'user_id': user.id,
          'content': content.trim(),
          'media_type': mediaType,
          'media_path': mediaPath,
          'mime_type': mimeType,
          'background_gradient': backgroundGradient,
        })
        .select()
        .single();
    final created = StatusUpdate.fromMap(Map<String, dynamic>.from(raw));
    await refresh();
    return created;
  }

  Future<void> markViewed(String statusId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('status_views').upsert(
      <String, dynamic>{
        'status_id': statusId,
        'viewer_id': user.id,
        'viewed_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'status_id,viewer_id',
    );
  }

  Future<void> delete(StatusUpdate status) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id != status.userId) {
      throw Exception('Only the status owner can delete this update.');
    }
    await _client.from('status_updates').delete().eq('id', status.id);
    await refresh();
  }

  void _subscribe() {
    final user = _client.auth.currentUser;
    if (user == null) return;
    _channel?.unsubscribe();
    _channel = _client
        .channel('chaty-status-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'status_updates',
          callback: (_) => unawaited(refresh()),
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(_client.removeChannel(channel));
    }
    super.dispose();
  }
}
