import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../injection/locator.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';

class StatusRecord {
  final String id;
  final String userId;
  final String text;
  final String mediaType;
  final String? mediaPath;
  final String? mediaName;
  final int mediaSize;
  final int durationSeconds;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? deletedAt;
  final String displayName;
  final String avatarInitials;
  final String avatarColorHex;

  const StatusRecord({
    required this.id,
    required this.userId,
    required this.text,
    required this.mediaType,
    required this.mediaPath,
    required this.mediaName,
    required this.mediaSize,
    required this.durationSeconds,
    required this.createdAt,
    required this.expiresAt,
    required this.deletedAt,
    this.displayName = '',
    this.avatarInitials = '',
    this.avatarColorHex = '0xFF6366F1',
  });

  bool get hasMedia => mediaPath != null && mediaPath!.isNotEmpty;
  bool get isDeleted => deletedAt != null;

  StatusRecord copyWithOwner({
    required String displayName,
    required String avatarInitials,
    required String avatarColorHex,
  }) {
    return StatusRecord(
      id: id,
      userId: userId,
      text: text,
      mediaType: mediaType,
      mediaPath: mediaPath,
      mediaName: mediaName,
      mediaSize: mediaSize,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      expiresAt: expiresAt,
      deletedAt: deletedAt,
      displayName: displayName,
      avatarInitials: avatarInitials,
      avatarColorHex: avatarColorHex,
    );
  }
}

class StatusService {
  StatusService({SupabaseClient? client, ChatyPreferencesController? preferences})
      : _client = client ?? Supabase.instance.client,
        _preferences = preferences ?? locator<ChatyPreferencesController>();

  static const String bucket = 'status-media';

  final SupabaseClient _client;
  final ChatyPreferencesController _preferences;
  final Uuid _uuid = const Uuid();
  final Map<String, Map<String, String>> _ownerCache = <String, Map<String, String>>{};

  Stream<List<StatusRecord>> watchActiveStatuses() {
    return _client
        .from('status_updates')
        .stream(primaryKey: const <String>['id'])
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
      final now = DateTime.now();
      final keepDeleted = _preferences.privacy.antiDeleteStatus ||
          _preferences.gbBool('yoAntiRevokeStatus');
      final statuses = rows
          .map((row) => _fromRow(Map<String, dynamic>.from(row)))
          .where((status) => status.expiresAt.isAfter(now) && (!status.isDeleted || keepDeleted))
          .toList(growable: false);
      await _hydrateOwners(statuses.map((status) => status.userId).toSet());
      return statuses
          .map((status) {
            final owner = _ownerCache[status.userId];
            if (owner == null) return status;
            return status.copyWithOwner(
              displayName: owner['display_name'] ?? '',
              avatarInitials: owner['avatar_initials'] ?? '',
              avatarColorHex: owner['avatar_color_hex'] ?? '0xFF6366F1',
            );
          })
          .toList(growable: false);
    });
  }

  Future<void> _hydrateOwners(Set<String> userIds) async {
    final missing = userIds.where((id) => id.isNotEmpty && !_ownerCache.containsKey(id)).toList(growable: false);
    if (missing.isEmpty) return;
    try {
      final rows = await _client
          .from('profiles')
          .select('id,display_name,avatar_initials,avatar_color_hex')
          .inFilter('id', missing);
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        _ownerCache[id] = <String, String>{
          'display_name': row['display_name']?.toString() ?? '',
          'avatar_initials': row['avatar_initials']?.toString() ?? '',
          'avatar_color_hex': row['avatar_color_hex']?.toString() ?? '0xFF6366F1',
        };
      }
    } catch (_) {
      // Keep the status usable even if profile enrichment is temporarily unavailable.
    }
  }

  Future<StatusRecord> publishText(String text) async {
    final value = text.trim();
    if (value.isEmpty) throw Exception('Enter status text before publishing.');
    return _insert(text: value, mediaType: 'text');
  }

  Future<StatusRecord?> pickAndPublish({required String mediaType, String text = ''}) async {
    if (mediaType == 'audio' && !_preferences.gbBool('abu9aleh_status_audio')) {
      throw Exception('Enable Audio Status in Settings → Status & stories first.');
    }

    final fileType = switch (mediaType) {
      'image' => FileType.image,
      'video' => FileType.video,
      'audio' => FileType.audio,
      _ => FileType.any,
    };
    final files = await FilePicker.pickFiles(type: fileType);
    if (files.isEmpty) return null;
    final picked = files.single;
    final path = picked.path;
    if (path == null || path.isEmpty) throw Exception('The selected file is not accessible on this device.');

    final file = File(path);
    if (!await file.exists()) throw Exception('The selected file no longer exists.');
    final size = await file.length();
    if (size <= 0) throw Exception('The selected file is empty.');
    final configuredMb = mediaType == 'audio'
        ? _preferences.gbDouble('abo_saleh_audio_limit_check', fallback: 50)
        : _preferences.gbDouble('Up_size_limit', fallback: 100);
    final maxBytes = configuredMb.clamp(1, 2048).round() * 1024 * 1024;
    if (size > maxBytes) throw Exception('Selected media exceeds the configured ${configuredMb.round()} MB limit.');

    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Authentication required.');
    final safeName = _safeFileName(picked.name);
    final objectPath = '${user.id}/${_uuid.v4()}_$safeName';
    final mimeType = lookupMimeType(path) ?? _fallbackMime(mediaType);

    await _client.storage.from(bucket).upload(
      objectPath,
      file,
      fileOptions: FileOptions(cacheControl: '3600', upsert: false, contentType: mimeType),
    );

    try {
      return await _insert(
        text: text.trim(),
        mediaType: mediaType,
        mediaPath: objectPath,
        mediaName: picked.name,
        mediaSize: size,
        mimeType: mimeType,
      );
    } catch (_) {
      await _client.storage.from(bucket).remove(<String>[objectPath]);
      rethrow;
    }
  }

  Future<String> createSignedUrl(String path, {int expiresInSeconds = 900}) {
    return _client.storage.from(bucket).createSignedUrl(path, expiresInSeconds);
  }

  Future<void> markViewed(StatusRecord status) async {
    final hide = _preferences.privacy.hideViewStatus || _preferences.gbBool('yoHideStatViewV2');
    await _client.rpc('mark_status_viewed', params: <String, dynamic>{
      'p_status_id': status.id,
      'p_hide_view': hide,
    });
  }

  Future<void> deleteStatus(StatusRecord status) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id != status.userId) throw Exception('You can only delete your own status.');
    await _client.rpc('delete_status_update', params: <String, dynamic>{'p_status_id': status.id});
  }

  Future<StatusRecord> _insert({
    required String text,
    required String mediaType,
    String? mediaPath,
    String? mediaName,
    String? mimeType,
    int mediaSize = 0,
    int durationSeconds = 0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Authentication required.');
    final now = DateTime.now().toUtc();
    final row = await _client.from('status_updates').insert(<String, dynamic>{
      'user_id': user.id,
      'content': text,
      'media_path': mediaPath,
      'media_type': mediaType,
      'mime_type': mimeType,
      'media_name': mediaName,
      'media_size': mediaSize,
      'duration_seconds': durationSeconds,
      'expires_at': now.add(const Duration(hours: 24)).toIso8601String(),
    }).select().single();
    final created = _fromRow(Map<String, dynamic>.from(row));
    await _hydrateOwners(<String>{created.userId});
    final owner = _ownerCache[created.userId];
    return owner == null
        ? created
        : created.copyWithOwner(
            displayName: owner['display_name'] ?? '',
            avatarInitials: owner['avatar_initials'] ?? '',
            avatarColorHex: owner['avatar_color_hex'] ?? '0xFF6366F1',
          );
  }

  static StatusRecord _fromRow(Map<String, dynamic> row) {
    return StatusRecord(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      text: row['content']?.toString() ?? '',
      mediaType: row['media_type']?.toString() ?? 'text',
      mediaPath: row['media_path']?.toString(),
      mediaName: row['media_name']?.toString(),
      mediaSize: row['media_size'] is num
          ? (row['media_size'] as num).round()
          : int.tryParse(row['media_size']?.toString() ?? '') ?? 0,
      durationSeconds: row['duration_seconds'] is num ? (row['duration_seconds'] as num).round() : 0,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      expiresAt: DateTime.tryParse(row['expires_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      deletedAt: row['deleted_at'] == null ? null : DateTime.tryParse(row['deleted_at'].toString())?.toLocal(),
    );
  }

  static String _safeFileName(String source) {
    final cleaned = source.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_').replaceAll(RegExp(r'_+'), '_');
    if (cleaned.isEmpty) return 'status';
    return cleaned.length > 120 ? cleaned.substring(cleaned.length - 120) : cleaned;
  }

  static String _fallbackMime(String type) {
    return switch (type) {
      'image' => 'image/jpeg',
      'video' => 'video/mp4',
      'audio' => 'audio/mp4',
      _ => 'application/octet-stream',
    };
  }
}
