import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StatusMediaUpload {
  final String storagePath;
  final String name;
  final String mimeType;
  final int bytes;

  const StatusMediaUpload({
    required this.storagePath,
    required this.name,
    required this.mimeType,
    required this.bytes,
  });
}

class StatusMediaService {
  StatusMediaService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String bucket = 'status-media';
  static const int maxBytes = 50 * 1024 * 1024;

  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();

  Future<StatusMediaUpload?> pickAndUpload(String mediaType) async {
    final pickerType = switch (mediaType) {
      'image' => FileType.image,
      'video' => FileType.video,
      'audio' => FileType.audio,
      _ => FileType.any,
    };

    final picked = await FilePicker.pickFile(type: pickerType);
    if (picked == null) return null;

    final path = picked.path;
    if (path == null || path.isEmpty) {
      throw Exception('The selected file is not accessible on this device.');
    }

    final file = File(path);
    if (!await file.exists()) {
      throw Exception('The selected file no longer exists.');
    }
    final bytes = await file.length();
    if (bytes <= 0) throw Exception('The selected file is empty.');
    if (bytes > maxBytes) {
      throw Exception('Status media cannot be larger than 50 MB.');
    }

    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Authentication required.');

    final safeName = picked.name
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final storagePath =
        '${user.id}/${_uuid.v4()}_${safeName.isEmpty ? 'status' : safeName}';
    final mimeType = lookupMimeType(path) ??
        switch (mediaType) {
          'image' => 'image/jpeg',
          'video' => 'video/mp4',
          'audio' => 'audio/mp4',
          _ => 'application/octet-stream',
        };

    await _client.storage.from(bucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: mimeType,
            cacheControl: '3600',
            upsert: false,
          ),
        );

    return StatusMediaUpload(
      storagePath: storagePath,
      name: picked.name,
      mimeType: mimeType,
      bytes: bytes,
    );
  }

  Future<String> signedUrl(String storagePath) {
    return _client.storage.from(bucket).createSignedUrl(storagePath, 900);
  }

  Future<void> delete(String storagePath) async {
    if (storagePath.trim().isEmpty) return;
    await _client.storage.from(bucket).remove(<String>[storagePath]);
  }
}
