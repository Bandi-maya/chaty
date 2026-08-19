import 'package:flutter/material.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../data/services/status_media_service.dart';
import '../../data/services/status_repository.dart';

class StatusComposerSheet extends StatefulWidget {
  final ThemeConfig theme;
  final StatusRepository repository;

  const StatusComposerSheet({
    super.key,
    required this.theme,
    required this.repository,
  });

  @override
  State<StatusComposerSheet> createState() => _StatusComposerSheetState();
}

class _StatusComposerSheetState extends State<StatusComposerSheet> {
  final TextEditingController _captionCtrl = TextEditingController();
  final StatusMediaService _mediaService = StatusMediaService();
  String _mediaType = 'text';
  StatusMediaUpload? _upload;
  bool _selecting = false;
  bool _publishing = false;
  String? _error;
  String _gradient = 'indigo_purple';

  static const List<_StatusTypeOption> _types = <_StatusTypeOption>[
    _StatusTypeOption('text', 'Text', Icons.text_fields_rounded),
    _StatusTypeOption('image', 'Image', Icons.image_outlined),
    _StatusTypeOption('video', 'Video', Icons.videocam_outlined),
    _StatusTypeOption('audio', 'Audio', Icons.graphic_eq_rounded),
    _StatusTypeOption('document', 'File', Icons.description_outlined),
  ];

  static const List<String> _gradients = <String>[
    'indigo_purple',
    'ocean',
    'sunset',
    'graphite',
    'rose',
  ];

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectType(String type) async {
    if (_selecting || _publishing) return;
    setState(() {
      _mediaType = type;
      _error = null;
    });
    if (type == 'text') {
      final previous = _upload;
      setState(() => _upload = null);
      if (previous != null) {
        await _mediaService.delete(previous.storagePath);
      }
      return;
    }

    setState(() => _selecting = true);
    try {
      final selected = await _mediaService.pickAndUpload(type);
      if (!mounted) return;
      if (selected != null) {
        final previous = _upload;
        setState(() => _upload = selected);
        if (previous != null && previous.storagePath != selected.storagePath) {
          await _mediaService.delete(previous.storagePath);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _publish() async {
    if (_publishing || _selecting) return;
    if (_mediaType != 'text' && _upload == null) {
      setState(() => _error = 'Choose a $_mediaType before publishing.');
      return;
    }
    if (_mediaType == 'text' && _captionCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Write something before publishing.');
      return;
    }

    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      await widget.repository.create(
        content: _captionCtrl.text.trim(),
        mediaType: _mediaType,
        mediaPath: _upload?.storagePath,
        mimeType: _upload?.mimeType,
        backgroundGradient: _gradient,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.secondaryTextColor.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Add to My Status',
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _publishing ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((option) {
                    final selected = option.id == _mediaType;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          option.icon,
                          size: 17,
                          color: selected
                              ? theme.onAccentColor
                              : theme.secondaryTextColor,
                        ),
                        label: Text(option.label),
                        selected: selected,
                        selectedColor: theme.accentColor,
                        labelStyle: TextStyle(
                          color: selected
                              ? theme.onAccentColor
                              : theme.primaryTextColor,
                        ),
                        onSelected: (_) => _selectType(option.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 190,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _gradientColors(_gradient)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _selecting
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            switch (_mediaType) {
                              'image' => Icons.image_rounded,
                              'video' => Icons.play_circle_fill_rounded,
                              'audio' => Icons.graphic_eq_rounded,
                              'document' => Icons.description_rounded,
                              _ => Icons.format_quote_rounded,
                            },
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _upload?.name ??
                                (_mediaType == 'text'
                                    ? (_captionCtrl.text.trim().isEmpty
                                        ? 'Your text status preview'
                                        : _captionCtrl.text.trim())
                                    : 'Choose a $_mediaType'),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              if (_mediaType == 'text')
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _gradients.map((gradient) {
                      return GestureDetector(
                        onTap: () => setState(() => _gradient = gradient),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _gradientColors(gradient)),
                            shape: BoxShape.circle,
                            border: gradient == _gradient
                                ? Border.all(color: theme.primaryTextColor, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _captionCtrl,
                minLines: 2,
                maxLines: 5,
                maxLength: 2000,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: theme.primaryTextColor),
                decoration: InputDecoration(
                  labelText: _mediaType == 'text' ? 'Status text' : 'Caption',
                  hintText: _mediaType == 'text'
                      ? 'Share an update…'
                      : 'Add an optional caption…',
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: TextStyle(color: theme.dangerColor, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _publishing || _selecting ? null : _publish,
                  icon: _publishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_publishing ? 'Publishing…' : 'Publish status'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTypeOption {
  final String id;
  final String label;
  final IconData icon;

  const _StatusTypeOption(this.id, this.label, this.icon);
}
