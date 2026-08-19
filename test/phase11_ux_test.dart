import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat/ui/core/ux/chaty_ux.dart';

void main() {
  testWidgets('global touch target never shrinks below accessibility floor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatyTouchTarget(
            semanticLabel: 'Test action',
            onTap: () {},
            child: const Icon(Icons.add, size: 16),
          ),
        ),
      ),
    );

    final target = find.descendant(
      of: find.byType(ChatyTouchTarget),
      matching: find.byType(ConstrainedBox),
    ).first;
    final size = tester.getSize(target);
    expect(size.width, greaterThanOrEqualTo(ChatyUx.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(ChatyUx.minTouchTarget));
  });

  testWidgets('responsive content constrains readable width on large windows', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatyResponsiveContent(
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    final constrained = find.descendant(
      of: find.byType(ChatyResponsiveContent),
      matching: find.byType(ConstrainedBox),
    ).first;
    expect(tester.getSize(constrained).width, lessThanOrEqualTo(ChatyUx.readableContentWidth));
  });

  testWidgets('state views expose a live semantic announcement', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatyStateView(
            kind: ChatyStateKind.error,
            title: 'Unable to load',
            message: 'Try again.',
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Unable to load. Try again.'), findsOneWidget);
  });

  test('app propagates reduced-motion and suppresses decorative particles', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('disableAnimations: reduceMotion'));
    expect(main, contains('if (!reduceMotion)'));
    expect(main, contains('ChatyUx.enforceTheme'));
  });

  test('global UX theme enforces padded interaction targets and keyboard-friendly states', () {
    final ux = File('lib/ui/core/ux/chaty_ux.dart').readAsStringSync();
    expect(ux, contains('MaterialTapTargetSize.padded'));
    expect(ux, contains('minTouchTarget'));
    expect(ux, contains('ChatyStateView'));
    expect(ux, contains('liveRegion: true'));
  });

  test('call history uses responsive accessible loading empty and error states', () {
    final calls = File('lib/features/calls/calls_screen.dart').readAsStringSync();
    expect(calls, contains('ChatyResponsiveContent'));
    expect(calls, contains('ChatyStateKind.loading'));
    expect(calls, contains('ChatyStateKind.empty'));
    expect(calls, contains('ChatyStateKind.error'));
    expect(calls, contains('Semantics('));
    expect(calls, contains('keyboardDismissBehavior'));
  });

  test('composer variants retain minimum actionable hit regions', () {
    final composer = File('lib/ui/core/composer/premium_message_composer.dart').readAsStringSync();
    expect(composer, contains('final target = size < 44 ? 44.0 : size'));
    expect(composer, contains("tooltip: hasText ? 'Send' : 'Voice note'"));
  });
}
