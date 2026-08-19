import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat/ui/core/layout/adaptive_window_metrics.dart';

void main() {
  group('AdaptiveWindowMetrics', () {
    test('very narrow freeform window remains bottom-nav compact', () {
      final metrics = AdaptiveWindowMetrics.fromSize(const Size(300, 480));
      expect(metrics.windowClass, ChatyWindowClass.compact);
      expect(metrics.isVeryNarrow, isTrue);
      expect(metrics.isShort, isTrue);
      expect(metrics.useNavigationRail, isFalse);
      expect(metrics.showNavigationLabels, isFalse);
    });

    test('phone window uses bottom navigation', () {
      final metrics = AdaptiveWindowMetrics.fromSize(const Size(412, 915));
      expect(metrics.windowClass, ChatyWindowClass.medium);
      expect(metrics.useNavigationRail, isFalse);
      expect(metrics.showNavigationLabels, isTrue);
    });

    test('tablet and desktop windows use navigation rail', () {
      final tablet = AdaptiveWindowMetrics.fromSize(const Size(700, 1000));
      final desktop = AdaptiveWindowMetrics.fromSize(const Size(1280, 800));
      expect(tablet.useNavigationRail, isTrue);
      expect(desktop.useNavigationRail, isTrue);
      expect(desktop.windowClass, ChatyWindowClass.large);
    });
  });

  test('Android activity explicitly opts into resizable multi-window mode', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:resizeableActivity="true"'));
    expect(manifest, contains('android:windowSoftInputMode="adjustResize"'));
    expect(manifest, contains('screenSize'));
    expect(manifest, contains('smallestScreenSize'));
  });
}
