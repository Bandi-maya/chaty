import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/chat_message.dart';

class ChatMediaService {
  ChatMediaService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String bucket = 'chat-media';
  static const int maxBytes = 50 * 1024 * 1024;

  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();

  Future<MessageAttachment?> pickAndUpload({
    required String conversationId,
    required String type,
  }) async {
    final pickerType = switch (type) {
      'image' => FileType.image,
      'video' => FileType.video,
      'audio' => FileType.audio,
      _ => FileType.any,
    };

    final result = await FilePicker.platform.pickFiles(
      type: pickerType,
      allowMultiple: false,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final sourcePath = picked.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw Exception('The selected file is not accessible on this device.');
    }

    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('The selected file no longer exists.');
    }

    final size = await file.length();
    if (size <= 0) throw Exception('The selected file is empty.');
    if (size > maxBytes) {
      throw Exception('Files larger than 50 MB are not supported yet.');
    }

    final authUser = _client.auth.currentUser;
    if (authUser == null) throw Exception('Authentication required.');

    final safeName = _safeFileName(picked.name);
    final objectPath =
        '${authUser.id}/$conversationId/${_uuid.v4()}_$safeName';
    final mimeType = lookupMimeType(sourcePath) ??
        _fallbackMimeForType(type);

    await _client.storage.from(bucket).upload(
          objectPath,
          file,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: mimeType,
          ),
        );

    return MessageAttachment(
      id: _uuid.v4(),
      type: type,
      name: picked.name,
      size: _formatBytes(size),
      // Store only the private object path. Signed URLs are generated on demand
      // so chat history never persists a long-lived bearer URL.
      url: objectPath,
    );
  }

  Future<String> createSignedUrl(
    String objectPath, {
    int expiresInSeconds = 900,
  }) async {
    if (objectPath.trim().isEmpty) {
      throw Exception('Attachment path is missing.');
    }
    return _client.storage.from(bucket).createSignedUrl(
          objectPath,
          expiresInSeconds,
        );
  }

  Future<void> deleteOwnAttachment(String objectPath) async {
    if (objectPath.trim().isEmpty) return;
    await _client.storage.from(bucket).remove(<String>[objectPath]);
  }

  static String _safeFileName(String source) {
    final cleaned = source
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (cleaned.isEmpty) return 'attachment';
    return cleaned.length > 120 ? cleaned.substring(cleaned.length - 120) : cleaned;
  }

  static String _fallbackMimeForType(String type) {
    return switch (type) {
      'image' => 'image/jpeg',
      'video' => 'video/mp4',
      'audio' => 'audio/mpeg',
      _ => 'application/octet-stream',
    };
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
