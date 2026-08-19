import 'package:flutter_test/flutter_test.dart';
import 'package:chat/ui/core/controllers/appearance_variant_controller.dart';

void main() {
  group('navigation variant registry', () {
    test('exposes exactly 20 desktop/tablet navigation styles', () {
      expect(AppearanceVariantController.navigationStyles, hasLength(20));
      expect(AppearanceVariantController.navigationStyles.toSet(), hasLength(20));
    });

    test('exposes exactly 20 mobile bottom-bar styles', () {
      expect(AppearanceVariantController.bottomBarStyles, hasLength(20));
      expect(AppearanceVariantController.bottomBarStyles.toSet(), hasLength(20));
    });

    test('families remain semantically distinct', () {
      expect(AppearanceVariantController.navigationStyles, containsAll(<String>[
        'Adaptive Rail',
        'Floating Rail',
        'Classic Tabs',
        'Segmented Tabs',
        'Sidebar Tabs',
        'Workspace Tabs',
        'Focus Tabs',
      ]));
      expect(AppearanceVariantController.bottomBarStyles, containsAll(<String>[
        'Floating Pill',
        'Classic Bar',
        'Icon Dock',
        'Raised Center',
        'Segmented Bar',
        'Card Dock',
        'Workspace Dock',
        'Focus Dock',
      ]));
    });
  });
}
