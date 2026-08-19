import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../data/services/chaty_call_service.dart';
import '../../injection/locator.dart';
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
      await _windowChannel.invokeMethod<bool>('enterPictureInPicture', const <String, int>{'width': 16, 'height': 9});
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
                      left: 12,
                      right: 12,
                      bottom: 12,
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
  final Future<void> Function() onEnd;

  const _CallControls({
    required this.theme,
    required this.compact,
    required this.isVideo,
    required this.service,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _ControlButton(
        label: service.microphoneEnabled ? 'Mute' : 'Unmute',
        icon: service.microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
        selected: !service.microphoneEnabled,
        onPressed: () => service.setMicrophoneEnabled(!service.microphoneEnabled),
      ),
      _ControlButton(
        label: service.speakerEnabled ? 'Speaker' : 'Earpiece',
        icon: service.speakerEnabled ? Icons.volume_up_rounded : Icons.hearing_rounded,
        selected: service.speakerEnabled,
        onPressed: () => service.setSpeakerEnabled(!service.speakerEnabled),
      ),
      if (isVideo)
        _ControlButton(
          label: service.cameraEnabled ? 'Camera' : 'Camera off',
          icon: service.cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
          selected: !service.cameraEnabled,
          onPressed: () => service.setCameraEnabled(!service.cameraEnabled),
        ),
      if (isVideo)
        _ControlButton(label: 'Flip', icon: Icons.cameraswitch_rounded, selected: false, onPressed: service.switchCamera),
      _ControlButton(label: 'End', icon: Icons.call_end_rounded, selected: true, destructive: true, onPressed: onEnd),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 18, vertical: compact ? 10 : 16),
      decoration: BoxDecoration(
        color: theme.surfaceColor.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.cardColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: buttons),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool destructive;
  final FutureOr<void> Function() onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = destructive
        ? scheme.error
        : selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;
    final foreground = destructive
        ? scheme.onError
        : selected
            ? scheme.onPrimaryContainer
            : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filled(
                onPressed: () => onPressed(),
                style: IconButton.styleFrom(
                  backgroundColor: background,
                  foregroundColor: foreground,
                  minimumSize: const Size(48, 48),
                ),
                icon: Icon(icon),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5),
              ),
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
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.secondaryTextColor, fontSize: 15),
                ),
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
        child: Text(
          initials,
          style: TextStyle(color: theme.accentColor, fontSize: size * .31, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
