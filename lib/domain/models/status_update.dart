class StatusUpdate {
  final String id;
  final String userId;
  final String content;
  final String mediaType;
  final String? mediaPath;
  final String? mimeType;
  final String backgroundGradient;
  final DateTime createdAt;
  final DateTime expiresAt;

  const StatusUpdate({
    required this.id,
    required this.userId,
    required this.content,
    required this.mediaType,
    required this.mediaPath,
    required this.mimeType,
    required this.backgroundGradient,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get hasMedia => mediaPath != null && mediaPath!.isNotEmpty;

  factory StatusUpdate.fromMap(Map<String, dynamic> map) => StatusUpdate(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        mediaType: map['media_type']?.toString() ?? 'text',
        mediaPath: map['media_path']?.toString(),
        mimeType: map['mime_type']?.toString(),
        backgroundGradient:
            map['background_gradient']?.toString() ?? 'indigo_purple',
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
        expiresAt: DateTime.tryParse(map['expires_at']?.toString() ?? '') ??
            DateTime.now().add(const Duration(hours: 24)),
      );
}
