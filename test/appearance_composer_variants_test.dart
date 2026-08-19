import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat/ui/core/controllers/appearance_variant_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('composer catalog contains exactly 20 unique production variants', () {
    final styles = AppearanceVariantController.composerStyles;
    expect(styles, hasLength(20));
    expect(styles.toSet(), hasLength(20));
    expect(styles.every((style) => style.trim().isNotEmpty), isTrue);
  });

  test('composer selection persists and restores from preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = AppearanceVariantController();
    await Future<void>.delayed(Duration.zero);

    const selected = 'Workspace Composer';
    await controller.setComposerStyle(selected);
    expect(controller.composerStyle, selected);
    expect(controller.composerIndex, AppearanceVariantController.composerStyles.indexOf(selected));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appearance.composer'), selected);
  });

  test('invalid composer values are rejected without corrupting the current value', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = AppearanceVariantController();
    await Future<void>.delayed(Duration.zero);
    final before = controller.composerStyle;

    await controller.setComposerStyle('Not a real composer');
    expect(controller.composerStyle, before);
  });
}
