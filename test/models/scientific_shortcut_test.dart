import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/scientific_shortcut.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists custom bindings that are not part of defaults', () async {
    final shortcuts = ScientificShortcutStore.freshDefaults();
    shortcuts[ScientificCategory.chemistry] = [
      ...shortcuts[ScientificCategory.chemistry]!,
      const ScientificShortcut(
        command: '/aq',
        label: 'Trạng thái dung dịch',
        template: r'$\mathrm{(aq)}$',
      ),
    ];

    await ScientificShortcutStore.save(shortcuts);
    final loaded = await ScientificShortcutStore.load();

    expect(
      loaded[ScientificCategory.chemistry]!.any(
        (shortcut) => shortcut.command == '/aq',
      ),
      isTrue,
    );
  });
}
