import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../data/services/chaty_call_service.dart';
import '../../injection/locator.dart';
import '../../ui/core/controllers/appearance_variant_controller.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/gb/gb_theme_overrides.dart';
import '../../ui/core/theme/theme_config.dart';
import '../../ui/core/ux/chaty_ux.dart';

class ChatyCallScreen extends StatefulWidget {
  final ThemeConfig theme;
  final ChatyCallService callService;
  final String title;
  final String conversationId;
  final String peerUserId;
  final bool isVideo;
  final ChatyCallSession? incomingSession;

  const ChatyCallScreen({
    super.key,
    required this.theme,
    required this.callService,
    required this.title,
    required this.conversationId,
    required this.peerUserId,
    required this.isVideo,
    this.incomingSession,
  });

  @override
  State<ChatyCallScreen> createState() => _ChatyCallScreenState();
}

class _ChatyCallScreenState extends State<ChatyCallScreen> {
  static const MethodChannel _windowChannel = MethodChannel('chaty/window');
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Timer? _durationTimer;
  int _connectedSeconds = 0;
  bool _initializing = true;
  bool _controlsVisible = true;
  bool _pipSupported = false;
  String? _error;

  ThemeConfig get _theme => GbThemeOverrides.resolveCalls(
        widget.theme,
        locator<ChatyPreferencesController>(),
      );

  @override
  void initState() {
    super.initState();
    widget.callService.addListener(_onCallChanged);
    unawaited(_initialize());
    unawaited(_detectPictureInPicture());
  }

  Future<void> _detectPictureInPicture() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final supported = await _windowChannel.invokeMethod<bool>('isPictureInPictureSupported') ?? false;
      if (mounted) setState(() => _pipSupported = supported);
    } on PlatformException {
      if (mounted) setState(() => _pipSupported = false);
    }
  }

  Future<void> _enterPictureInPicture() async {
    if (!widget.isVideo || !_pipSupported) return;
    try {
      await _windowChannel.invokeMethod<bool>(
        'enterPictureInPicture',
        const <String, int>{'width': 16, 'height': 9},
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mini player unavailable: ${error.message ?? 'Android rejected Picture-in-Picture.'}')),
      );
    }
  }

  Future<void> _initialize() async {
    try {
      await Future.wait(<Future<void>>[_localRenderer.initialize(), _remoteRenderer.initialize()]);
      if (widget.incomingSession != null) {
        await widget.callService.acceptIncoming(widget.incomingSession!);
      } else {
        await widget.callService.startOutgoing(
          conversationId: widget.conversationId,
          calleeId: widget.peerUserId,
          isVideo: widget.isVideo,
        );
      }
      _syncRenderers();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  void _onCallChanged() {
    if (!mounted) return;
    _syncRenderers();
    if (widget.callService.state == ChatyCallState.connected && _durationTimer == null) {
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _connectedSeconds++);
      });
    }
    if ({ChatyCallState.ended, ChatyCallState.declined}.contains(widget.callService.state)) {
      final delay = MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero
          : const Duration(milliseconds: 500);
      Future<void>.delayed(delay, () {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
    setState(() {});
  }

  void _syncRenderers() {
    if (_localRenderer.srcObject != widget.callService.localStream) {
      _localRenderer.srcObject = widget.callService.localStream;
    }
    if (_remoteRenderer.srcObject != widget.callService.remoteStream) {
      _remoteRenderer.srcObject = widget.callService.remoteStream;
    }
  }

  String get _statusText {
    if (_error != null) return _error!;
    switch (widget.callService.state) {
      case ChatyCallState.preparing:
        return 'Preparing camera and microphone…';
      case ChatyCallState.ringing:
        return 'Ringing…';
      case ChatyCallState.connecting:
        return 'Connecting…';
      case ChatyCallState.connected:
        final minutes = (_connectedSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (_connectedSeconds % 60).toString().padLeft(2, '0');
        return '$minutes:$seconds';
      case ChatyCallState.declined:
        return 'Call declined';
      case ChatyCallState.ended:
        return 'Call ended';
      case ChatyCallState.failed:
        return widget.callService.errorMessage ?? 'Call failed';
    }
  }

  Future<void> _end() async {
    try {
      await widget.callService.endCall();
    } finally {
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    widget.callService.removeListener(_onCallChanged);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final isVideo = widget.isVideo;
    final remoteReady = widget.callService.remoteStream != null;
    final fadeDuration = ChatyUx.motionDuration(context, standard: const Duration(milliseconds: 180));
    final slideDuration = ChatyUx.motionDuration(context, standard: const Duration(milliseconds: 220));
    final callTemplateIndex = locator<AppearanceVariantController>().callUiIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_end());
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isVideo ? () => setState(() => _controlsVisible = !_controlsVisible) : null,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420 || constraints.maxHeight < 640;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isVideo && remoteReady)
                      Semantics(
                        image: true,
                        label: 'Remote video from ${widget.title}',
                        child: RTCVideoView(
                          _remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      )
                    else
                      _AudioCallBackdrop(theme: theme, title: widget.title, status: _statusText),
                    if (isVideo && !remoteReady)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Avatar(theme: theme, title: widget.title, size: compact ? 88 : 112),
                            const SizedBox(height: 18),
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: theme.primaryTextColor,
                                fontSize: compact ? 20 : 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              liveRegion: true,
                              label: _statusText,
                              child: ExcludeSemantics(
                                child: Text(
                                  _statusText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: theme.secondaryTextColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isVideo && widget.callService.localStream != null && widget.callService.cameraEnabled)
                      Positioned(
                        right: 14,
                        top: 72,
                        width: compact ? 96 : 126,
                        height: compact ? 138 : 178,
                        child: Semantics(
                          image: true,
                          label: 'Your camera preview',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: DecoratedBox(
                              decoration: BoxDecoration(border: Border.all(color: theme.surfaceColor)),
                              child: RTCVideoView(
                                _localRenderer,
                                mirror: true,
                                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: AnimatedOpacity(
                        opacity: _controlsVisible ? 1 : 0,
                        duration: fadeDuration,
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(
                              children: [
                                IconButton.filledTonal(
                                  tooltip: 'End call and go back',
                                  onPressed: _end,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                ),
                                if (isVideo && _pipSupported) ...[
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    tooltip: 'Open video in mini player',
                                    onPressed: _enterPictureInPicture,
                                    icon: const Icon(Icons.picture_in_picture_alt_rounded),
                                  ),
                                ],
                                const Spacer(),
                                Flexible(
                                  child: Semantics(
                                    liveRegion: true,
                                    label: '${widget.title}. $_statusText',
                                    child: ExcludeSemantics(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            widget.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w800),
                                          ),
                                          Text(
                                            _statusText,
                                            maxLines: 2,
                                            textAlign: TextAlign.right,
                                            style: TextStyle(color: theme.secondaryTextColor, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: callTemplateIndex == 17 ? 0 : 12,
                      right: callTemplateIndex == 17 ? 0 : 12,
                      bottom: callTemplateIndex == 17 ? 0 : 12,
                      child: AnimatedSlide(
                        offset: _controlsVisible ? Offset.zero : const Offset(0, 1.4),
                        duration: slideDuration,
                        curve: Curves.easeOutCubic,
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: _CallControls(
                            theme: theme,
                            compact: compact,
                            isVideo: isVideo,
                            service: widget.callService,
                            styleIndex: callTemplateIndex,
                            onEnd: _end,
                          ),
                        ),
                      ),
                    ),
                    if (_initializing)
                      Semantics(
                        liveRegion: true,
                        label: 'Preparing call',
                        child: ColoredBox(
                          color: theme.backgroundColor.withValues(alpha: .82),
                          child: Center(child: CircularProgressIndicator(color: theme.accentColor)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final ThemeConfig theme;
  final bool compact;
  final bool isVideo;
  final ChatyCallService service;
  final int styleIndex;
  final Future<void> Function() onEnd;

  const _CallControls({
    required this.theme,
    required this.compact,
    required this.isVideo,
    required this.service,
    required this.styleIndex,
    required this.onEnd,
  });

  List<_ControlSpec> get _specs => <_ControlSpec>[
        _ControlSpec(
          label: service.microphoneEnabled ? 'Mute' : 'Unmute',
          icon: service.microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
          selected: !service.microphoneEnabled,
          onPressed: () => service.setMicrophoneEnabled(!service.microphoneEnabled),
        ),
        _ControlSpec(
          label: service.speakerEnabled ? 'Speaker' : 'Earpiece',
          icon: service.speakerEnabled ? Icons.volume_up_rounded : Icons.hearing_rounded,
          selected: service.speakerEnabled,
          onPressed: () => service.setSpeakerEnabled(!service.speakerEnabled),
        ),
        if (isVideo)
          _ControlSpec(
            label: service.cameraEnabled ? 'Camera' : 'Camera off',
            icon: service.cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            selected: !service.cameraEnabled,
            onPressed: () => service.setCameraEnabled(!service.cameraEnabled),
          ),
        if (isVideo)
          _ControlSpec(label: 'Flip', icon: Icons.cameraswitch_rounded, selected: false, onPressed: service.switchCamera),
        _ControlSpec(label: 'End', icon: Icons.call_end_rounded, selected: true, destructive: true, onPressed: onEnd),
      ];

  @override
  Widget build(BuildContext context) {
    final index = styleIndex.clamp(0, 19);
    return switch (index) {
      0 => _surface(context, radius: 28, padding: 14, shadow: true, child: _row(0, labels: true)),
      1 => _surface(context, radius: 12, padding: 12, child: _row(1, labels: true)),
      2 => _surface(context, radius: 24, padding: 7, child: _row(2, labels: false)),
      3 => _split(context),
      4 => _surface(context, radius: 22, padding: 12, outlined: true, transparent: true, child: _row(4, labels: true)),
      5 => _surface(context, radius: 34, padding: 13, soft: true, child: _row(5, labels: true)),
      6 => _surface(context, radius: 18, padding: 9, shadow: true, child: _row(6, labels: false)),
      7 => _surface(context, radius: 14, padding: 10, child: _labelDeck(context)),
      8 => _minimal(context),
      9 => _raisedEnd(context),
      10 => _segmented(context),
      11 => _surface(context, radius: 20, padding: 16, inset: true, child: _row(11, labels: true)),
      12 => _flat(context),
      13 => _surface(context, radius: 9, padding: 5, child: _row(13, labels: false)),
      14 => _surface(context, radius: 36, padding: 14, shadow: true, child: _row(14, labels: true)),
      15 => _surface(context, radius: 28, padding: 6, child: _row(15, labels: false)),
      16 => _cards(context),
      17 => _edge(context),
      18 => _workspace(context),
      _ => _focus(context),
    };
  }

  Widget _row(int presentation, {required bool labels}) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _specs.map((spec) => _ControlButton(spec: spec, presentation: presentation, showLabel: labels)).toList(growable: false),
        ),
      );

  Widget _surface(
    BuildContext context, {
    required double radius,
    required double padding,
    required Widget child,
    bool shadow = false,
    bool outlined = false,
    bool transparent = false,
    bool soft = false,
    bool inset = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? padding * .72 : padding, vertical: compact ? 8 : padding),
      margin: inset ? const EdgeInsets.symmetric(horizontal: 8) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: transparent
            ? Colors.transparent
            : soft
                ? theme.accentColor.withValues(alpha: .10)
                : theme.surfaceColor.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(radius),
        border: outlined || inset ? Border.all(color: outlined ? theme.accentColor.withValues(alpha: .55) : theme.cardColor) : null,
        boxShadow: shadow ? [BoxShadow(color: Colors.black.withValues(alpha: .16), blurRadius: 24, offset: const Offset(0, 8))] : const [],
      ),
      child: child,
    );
  }

  Widget _split(BuildContext context) {
    final regular = _specs.where((spec) => !spec.destructive).toList(growable: false);
    final end = _specs.firstWhere((spec) => spec.destructive);
    return Row(
      children: [
        Expanded(
          child: _surface(
            context,
            radius: 20,
            padding: 9,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: regular.map((spec) => _ControlButton(spec: spec, presentation: 3, showLabel: false)).toList()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ControlButton(spec: end, presentation: 3, showLabel: false, prominent: true),
      ],
    );
  }

  Widget _labelDeck(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: _specs.map((spec) => _ControlButton(spec: spec, presentation: 7, showLabel: true, labelFirst: true)).toList(),
      );

  Widget _minimal(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _row(8, labels: false),
      );

  Widget _raisedEnd(BuildContext context) {
    final end = _specs.last;
    final regular = _specs.take(_specs.length - 1);
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        _surface(
          context,
          radius: 24,
          padding: 10,
          shadow: true,
          child: Row(children: [
            ...regular.map((spec) => Expanded(child: _ControlButton(spec: spec, presentation: 9, showLabel: false))),
            const SizedBox(width: 64),
          ]),
        ),
        Positioned(right: 14, top: -10, child: _ControlButton(spec: end, presentation: 9, showLabel: false, prominent: true)),
      ],
    );
  }

  Widget _segmented(BuildContext context) => _surface(
        context,
        radius: 16,
        padding: 4,
        child: Row(
          children: _specs
              .map((spec) => Expanded(child: _ControlButton(spec: spec, presentation: 10, showLabel: false, segmented: true)))
              .toList(),
        ),
      );

  Widget _flat(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: .96),
          border: Border(top: BorderSide(color: theme.cardColor)),
        ),
        child: _row(12, labels: true),
      );

  Widget _cards(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _specs
              .map((spec) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _ControlButton(spec: spec, presentation: 16, showLabel: true, card: true),
                  ))
              .toList(),
        ),
      );

  Widget _edge(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        color: theme.surfaceColor,
        child: _row(17, labels: true),
      );

  Widget _workspace(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: .97),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.cardColor),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: _specs.map((spec) => _ControlButton(spec: spec, presentation: 18, showLabel: true, workspace: true)).toList(),
        ),
      );

  Widget _focus(BuildContext context) => Align(
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: theme.surfaceColor, borderRadius: BorderRadius.circular(12)),
          child: _row(19, labels: false),
        ),
      );
}

class _ControlSpec {
  final String label;
  final IconData icon;
  final bool selected;
  final bool destructive;
  final FutureOr<void> Function() onPressed;

  const _ControlSpec({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.destructive = false,
  });
}

class _ControlButton extends StatelessWidget {
  final _ControlSpec spec;
  final int presentation;
  final bool showLabel;
  final bool labelFirst;
  final bool prominent;
  final bool segmented;
  final bool card;
  final bool workspace;

  const _ControlButton({
    required this.spec,
    required this.presentation,
    required this.showLabel,
    this.labelFirst = false,
    this.prominent = false,
    this.segmented = false,
    this.card = false,
    this.workspace = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = spec.destructive
        ? scheme.error
        : spec.selected
            ? scheme.primaryContainer
            : presentation == 8 || presentation == 19
                ? Colors.transparent
                : scheme.surfaceContainerHighest;
    final foreground = spec.destructive
        ? scheme.onError
        : spec.selected
            ? scheme.onPrimaryContainer
            : scheme.onSurface;

    final shape = switch (presentation) {
      1 || 13 || 18 => RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      4 => RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
      5 || 14 || 15 => const StadiumBorder(),
      10 => RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      16 => RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      17 => RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      _ => const CircleBorder(),
    };

    final size = prominent ? 60.0 : (presentation == 2 || presentation == 13 || presentation == 15 ? 44.0 : 48.0);
    final button = SizedBox(
      width: segmented ? double.infinity : (card ? 62 : size),
      height: card ? 58 : size,
      child: FilledButton(
        onPressed: () => spec.onPressed(),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: background,
          foregroundColor: foreground,
          shape: shape,
          minimumSize: Size(size, size),
          elevation: prominent ? 5 : (presentation == 6 || presentation == 16 ? 2 : 0),
        ),
        child: Icon(spec.icon, size: prominent ? 26 : (presentation == 13 ? 19 : 22)),
      ),
    );

    final label = Text(
      spec.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: workspace ? 10 : 10.5, fontWeight: presentation == 7 ? FontWeight.w700 : FontWeight.w500),
    );

    return Semantics(
      button: true,
      selected: spec.selected,
      label: spec.label,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: segmented ? 2 : 4),
        child: SizedBox(
          width: segmented ? null : (showLabel ? 68 : size),
          child: labelFirst && showLabel
              ? Column(mainAxisSize: MainAxisSize.min, children: [label, const SizedBox(height: 4), button])
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    button,
                    if (showLabel) ...[const SizedBox(height: 4), label],
                  ],
                ),
        ),
      ),
    );
  }
}

class _AudioCallBackdrop extends StatelessWidget {
  final ThemeConfig theme;
  final String title;
  final String status;
  const _AudioCallBackdrop({required this.theme, required this.title, required this.status});

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          liveRegion: true,
          label: '$title. $status',
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(theme: theme, title: title, size: 118),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.primaryTextColor, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(status, textAlign: TextAlign.center, style: TextStyle(color: theme.secondaryTextColor, fontSize: 15)),
              ],
            ),
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  final ThemeConfig theme;
  final String title;
  final double size;
  const _Avatar({required this.theme, required this.title, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = title.trim().isEmpty
        ? 'C'
        : title.trim().split(RegExp(r'\s+')).take(2).map((part) => part[0]).join().toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.accentColor.withValues(alpha: .16),
          border: Border.all(color: theme.accentColor.withValues(alpha: .5), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(initials, style: TextStyle(color: theme.accentColor, fontSize: size * .31, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
