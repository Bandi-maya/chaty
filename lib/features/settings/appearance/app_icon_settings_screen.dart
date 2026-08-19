import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/services/chaty_app_icon_service.dart';

class AppIconSettingsScreen extends StatefulWidget {
  const AppIconSettingsScreen({super.key});

  @override
  State<AppIconSettingsScreen> createState() => _AppIconSettingsScreenState();
}

class _AppIconSettingsScreenState extends State<AppIconSettingsScreen> {
  final ChatyAppIconService _service = ChatyAppIconService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service.load();
  }

  Future<void> _applyPreset(ChatyAppIconPreset preset) async {
    if (_busy || _service.selection == preset.id) return;
    setState(() => _busy = true);
    try {
      await _service.applyPreset(preset.id);
      if (!mounted) return;
      final restart = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('App icon updated'),
          content: const Text('Android may need a moment to refresh the launcher. Restart Chaty now to complete the change everywhere.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Later')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restart now')),
          ],
        ),
      );
      if (restart == true) SystemNavigator.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('PlatformException: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCustomIcon() async {
    if (_busy) return;
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty || !mounted) return;
    final picked = files.single;
    final path = picked.path;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The selected image is not accessible on this device.')));
      return;
    }
    final source = File(path);
    if (!await source.exists()) return;
    final size = await source.length();
    if (!mounted) return;
    if (size <= 0 || size > 20 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a valid image smaller than 20 MB.')));
      return;
    }
    final bytes = await source.readAsBytes();
    if (!mounted) return;
    final croppedPath = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => _AppIconCropScreen(bytes: bytes)));
    if (croppedPath == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.applyCustom(croppedPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom icon saved and applied inside Chaty until you change it or uninstall the app.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeCustom() async {
    if (_busy || !_service.hasCustomIcon) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove custom icon?'),
        content: const Text('Chaty will return to the original launcher and in-app icon.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.removeCustom();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('App icon')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _service,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            children: [
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    const ChatyAppIcon(size: 72, borderRadius: 20, showShadow: true),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Current Chaty icon', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(_service.selection == ChatyAppIconService.customSelection ? 'Your custom image' : _service.activePreset.name, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ])),
                  ]),
                ),
              ),
              const SizedBox(height: 22),
              Text('CHAT ICONS', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .8)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ChatyAppIconService.presets.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 210, mainAxisExtent: 178, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemBuilder: (context, index) {
                  final preset = ChatyAppIconService.presets[index];
                  final selected = _service.selection == preset.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _busy ? null : () => _applyPreset(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: selected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: .35), width: selected ? 2 : 1),
                        color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: .22) : theme.cardColor,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 58, height: 58, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer])), child: Icon(preset.icon, color: theme.colorScheme.onPrimary, size: 30)),
                        const SizedBox(height: 12),
                        Text(preset.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(preset.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('CUSTOM ICON', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .8)),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                child: Column(children: [
                  ListTile(
                    minTileHeight: 72,
                    leading: const Icon(Icons.add_photo_alternate_outlined, size: 28),
                    title: const Text('Upload your own icon', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Choose an image, crop it square, zoom and reposition before applying.'),
                    trailing: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right_rounded),
                    onTap: _busy ? null : _pickCustomIcon,
                  ),
                  if (_service.hasCustomIcon)
                    ListTile(minTileHeight: 62, leading: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error), title: Text('Remove custom icon', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w700)), onTap: _busy ? null : _removeCustom),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5), borderRadius: BorderRadius.circular(14)),
                child: const Text('Android only allows the installed launcher icon to reference resources packaged in the APK. Chaty presets can replace the real launcher icon. A photo you upload is persisted and used across Chaty itself, but Android cannot turn an arbitrary runtime photo into the installed launcher resource without rebuilding/reinstalling the APK.', style: TextStyle(height: 1.4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIconCropScreen extends StatefulWidget {
  final Uint8List bytes;
  const _AppIconCropScreen({required this.bytes});

  @override
  State<_AppIconCropScreen> createState() => _AppIconCropScreenState();
}

class _AppIconCropScreenState extends State<_AppIconCropScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final TransformationController _transform = TransformationController();
  bool _saving = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _reset() => _transform.value = Matrix4.identity();

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Crop preview is not ready.');
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Unable to encode the cropped icon.');
      final support = await getApplicationSupportDirectory();
      final directory = Directory('${support.path}${Platform.pathSeparator}branding');
      await directory.create(recursive: true);
      final file = File('${directory.path}${Platform.pathSeparator}chaty_custom_icon.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (mounted) Navigator.of(context).pop(file.path);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final side = (MediaQuery.sizeOf(context).width - 36).clamp(220.0, 420.0).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('Crop app icon'), actions: [TextButton(onPressed: _saving ? null : _reset, child: const Text('Reset'))]),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: Center(child: Stack(alignment: Alignment.center, children: [
            RepaintBoundary(
              key: _captureKey,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(side * .22),
                child: SizedBox.square(
                  dimension: side,
                  child: ColoredBox(
                    color: Colors.black,
                    child: InteractiveViewer(
                      transformationController: _transform,
                      constrained: true,
                      clipBehavior: Clip.hardEdge,
                      minScale: 1,
                      maxScale: 6,
                      child: SizedBox.expand(child: Image.memory(widget.bytes, fit: BoxFit.cover)),
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(child: SizedBox.square(dimension: side, child: CustomPaint(painter: _CropGuidePainter()))),
          ]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(children: [
              const Text('Pinch to zoom and drag to position the image inside the icon frame.', textAlign: TextAlign.center),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Applying…' : 'Use this icon'),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CropGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .72)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
