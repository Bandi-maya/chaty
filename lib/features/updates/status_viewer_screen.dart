import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/status_media_service.dart';
import '../../data/services/status_repository.dart';
import '../../domain/models/status_update.dart';
import '../../ui/core/widgets/app_avatar.dart';

class StatusViewerScreen extends StatefulWidget {
  final StatusUpdate status;
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final StatusRepository repository;

  const StatusViewerScreen({
    super.key,
    required this.status,
    required this.theme,
    required this.dataStore,
    required this.repository,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  final StatusMediaService _mediaService = StatusMediaService();
  String? _signedUrl;
  String? _error;
  bool _loadingMedia = false;

  bool get _isOwn => widget.status.userId == widget.dataStore.currentUser.id;

  @override
  void initState() {
    super.initState();
    widget.repository.markViewed(widget.status.id);
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final path = widget.status.mediaPath;
    if (path == null || path.isEmpty) return;
    setState(() => _loadingMedia = true);
    try {
      final url = await _mediaService.signedUrl(path);
      if (!mounted) return;
      setState(() {
        _signedUrl = url;
        _loadingMedia = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMedia = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openExternal() async {
    final url = _signedUrl;
    if (url == null) return;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No installed application can open this status media.')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete status?'),
        content: const Text('This removes the status for everyone immediately.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final path = widget.status.mediaPath;
    await widget.repository.delete(widget.status);
    if (path != null && path.isNotEmpty) {
      await _mediaService.delete(path);
    }
    if (mounted) Navigator.pop(context);
  }

  List<Color> _gradientColors(String id) {
    return switch (id) {
      'ocean' => const <Color>[Color(0xFF075985), Color(0xFF0E7490)],
      'sunset' => const <Color>[Color(0xFF9F1239), Color(0xFFC2410C)],
      'graphite' => const <Color>[Color(0xFF27272A), Color(0xFF52525B)],
      'rose' => const <Color>[Color(0xFFBE123C), Color(0xFF7E22CE)],
      _ => const <Color>[Color(0xFF4338CA), Color(0xFF7E22CE)],
    };
  }

  String _relativeTime(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    return '${difference.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final status = widget.status;
    final owner = widget.dataStore.getUser(status.userId);
    final title = _isOwn ? 'My Status' : (owner?.displayName ?? 'Chaty user');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  AppAvatar(
                    initials: owner?.avatarInitials ?? widget.dataStore.currentUser.avatarInitials,
                    colorHex: owner?.avatarColorHex ?? widget.dataStore.currentUser.avatarColorHex,
                    size: 36,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        Text(
                          _relativeTime(status.createdAt),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (_isOwn)
                    PopupMenuButton<String>(
                      iconColor: Colors.white,
                      onSelected: (value) {
                        if (value == 'delete') _delete();
                      },
                      itemBuilder: (_) => const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(value: 'delete', child: Text('Delete status')),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  gradient: status.mediaType == 'text'
                      ? LinearGradient(colors: _gradientColors(status.backgroundGradient))
                      : null,
                  color: status.mediaType == 'text' ? null : const Color(0xFF101010),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _buildMedia(status, theme),
                    if (status.content.isNotEmpty && status.mediaType != 'text')
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 34, 18, 18),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[Colors.transparent, Colors.black87],
                            ),
                          ),
                          child: Text(
                            status.content,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(StatusUpdate status, ThemeConfig theme) {
    if (status.mediaType == 'text') {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Text(
            status.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.28,
            ),
          ),
        ),
      );
    }
    if (_loadingMedia) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    final url = _signedUrl;
    if (url == null) {
      return const Center(
        child: Text('Media is unavailable.', style: TextStyle(color: Colors.white70)),
      );
    }
    if (status.mediaType == 'image') {
      return InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 62),
          ),
        ),
      );
    }

    final icon = switch (status.mediaType) {
      'video' => Icons.play_circle_fill_rounded,
      'audio' => Icons.graphic_eq_rounded,
      'document' => Icons.description_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 82),
          const SizedBox(height: 18),
          Text(
            '${status.mediaType[0].toUpperCase()}${status.mediaType.substring(1)} status',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open securely'),
          ),
        ],
      ),
    );
  }
}
