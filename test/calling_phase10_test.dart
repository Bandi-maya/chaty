import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production call implementation replaces simulated call screen', () {
    expect(File('lib/features/calls/mock_call_screen.dart').existsSync(), isFalse);
    expect(File('lib/features/calls/chaty_call_screen.dart').existsSync(), isTrue);
    expect(File('lib/data/services/chaty_call_service.dart').existsSync(), isTrue);
  });

  test('WebRTC transport and signaling are wired to real runtime paths', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final service = File('lib/data/services/chaty_call_service.dart').readAsStringSync();
    expect(pubspec, contains('flutter_webrtc:'));
    for (final token in <String>[
      'createPeerConnection',
      'getUserMedia',
      'createOffer',
      'createAnswer',
      'setLocalDescription',
      'setRemoteDescription',
      "from('call_sessions')",
      "from('call_ice_candidates')",
      '_pendingLocalCandidates',
      'TURN_URL',
      'TURN_USERNAME',
      'TURN_CREDENTIAL',
    ]) {
      expect(service, contains(token), reason: '$token must remain in the real call runtime');
    }
  });

  test('call UI represents actual call states and media controls', () {
    final screen = File('lib/features/calls/chaty_call_screen.dart').readAsStringSync();
    for (final token in <String>[
      'RTCVideoRenderer',
      'ChatyCallState.preparing',
      'ChatyCallState.ringing',
      'ChatyCallState.connecting',
      'ChatyCallState.connected',
      'ChatyCallState.failed',
      'setMicrophoneEnabled',
      'setSpeakerEnabled',
      'setCameraEnabled',
      'switchCamera',
      'endCall',
    ]) {
      expect(screen, contains(token));
    }
    expect(screen, isNot(contains('Direct Peer-to-Peer Encrypted Call')));
  });

  test('GB call appearance controls affect the active call screen', () {
    final overrides = File('lib/ui/core/gb/gb_theme_overrides.dart').readAsStringSync();
    final screen = File('lib/features/calls/chaty_call_screen.dart').readAsStringSync();
    for (final key in <String>['ModCallsBackground', 'ModCallsTextColor', 'ModCallsIconColors']) {
      expect(overrides, contains("'$key'"));
    }
    expect(screen, contains('GbThemeOverrides.resolveCalls'));
  });

  test('foreground incoming calling is coordinated globally', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('watchIncomingCalls'));
    expect(main, contains('_presentIncomingCall'));
    expect(main, contains('Incoming video call'));
    expect(main, contains('incomingSession: call'));
    expect(main, contains('declineIncoming(call)'));
  });

  test('Android enables camera audio Bluetooth resize and video PiP', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final activity = File('android/app/src/main/kotlin/com/example/chat/MainActivity.kt').readAsStringSync();
    for (final permission in <String>[
      'android.permission.CAMERA',
      'android.permission.RECORD_AUDIO',
      'android.permission.MODIFY_AUDIO_SETTINGS',
      'android.permission.BLUETOOTH_CONNECT',
    ]) {
      expect(manifest, contains(permission));
    }
    expect(manifest, contains('android:supportsPictureInPicture="true"'));
    expect(activity, contains('enterPictureInPictureMode'));
    expect(activity, contains('chaty/window'));
    final screen = File('lib/features/calls/chaty_call_screen.dart').readAsStringSync();
    expect(screen, contains('enterPictureInPicture'));
  });

  test('iOS declares camera and microphone purpose strings', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('NSCameraUsageDescription'));
    expect(plist, contains('NSMicrophoneUsageDescription'));
  });

  test('chat and calls surfaces no longer route to MockCallScreen', () {
    final chat = File('lib/features/chats/chat_detail_screen.dart').readAsStringSync();
    final calls = File('lib/features/calls/calls_screen.dart').readAsStringSync();
    expect(chat, contains('ChatyCallScreen('));
    expect(calls, contains('ChatyCallScreen('));
    expect(chat, isNot(contains('MockCallScreen')));
    expect(calls, isNot(contains('MockCallScreen')));
  });
}
