import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'visual_math_block.dart';

enum ScientificCategory {
  math('Toán học'),
  physics('Vật lý'),
  chemistry('Hóa học'),
  greek('Hy Lạp'),
  languages('Ngoại ngữ / IPA');

  const ScientificCategory(this.label);

  final String label;
}

class ScientificShortcut {
  const ScientificShortcut({
    required this.command,
    required this.label,
    this.template,
    this.blockType,
  });

  final String command;
  final String label;
  final String? template;
  final MathBlockType? blockType;

  ScientificShortcut copyWith({String? command}) => ScientificShortcut(
    command: command ?? this.command,
    label: label,
    template: template,
    blockType: blockType,
  );
}

class ScientificShortcutStore {
  static const _preferenceKey = 'scientific_shortcuts_v1';

  static const defaults = <ScientificCategory, List<ScientificShortcut>>{
    ScientificCategory.math: [
      ScientificShortcut(
        command: '/1',
        label: 'Phân số',
        blockType: MathBlockType.fraction,
      ),
      ScientificShortcut(
        command: '/2',
        label: 'Căn bậc hai',
        blockType: MathBlockType.sqrt,
      ),
      ScientificShortcut(
        command: '/3',
        label: 'Lũy thừa',
        blockType: MathBlockType.power,
      ),
      ScientificShortcut(
        command: '/4',
        label: 'Chỉ số dưới',
        blockType: MathBlockType.subscript,
      ),
      ScientificShortcut(
        command: '/5',
        label: 'Tích phân',
        blockType: MathBlockType.integral,
      ),
      ScientificShortcut(
        command: '/6',
        label: 'Giới hạn',
        blockType: MathBlockType.limit,
      ),
      ScientificShortcut(
        command: '/7',
        label: 'Tổng Sigma',
        blockType: MathBlockType.summation,
      ),
      ScientificShortcut(
        command: '/8',
        label: 'Vector',
        blockType: MathBlockType.vector,
      ),
    ],
    ScientificCategory.physics: [
      ScientificShortcut(
        command: '/1',
        label: 'Vector lực',
        template: r'$\vec{F}$',
      ),
      ScientificShortcut(
        command: '/2',
        label: 'Độ biến thiên',
        template: r'$\Delta$',
      ),
      ScientificShortcut(
        command: '/3',
        label: 'Độ C',
        template: r'$^\circ\mathrm{C}$',
      ),
      ScientificShortcut(command: '/4', label: 'Omega', template: r'$\Omega$'),
    ],
    ScientificCategory.chemistry: [
      ScientificShortcut(
        command: '/1',
        label: 'Nhiệt độ phản ứng',
        template: r'$\overset{t^\circ}{\rightarrow}$',
      ),
      ScientificShortcut(
        command: '/2',
        label: 'Phản ứng một chiều',
        template: r'$\rightarrow$',
      ),
      ScientificShortcut(
        command: '/3',
        label: 'Phản ứng thuận nghịch',
        template: r'$\rightleftharpoons$',
      ),
      ScientificShortcut(
        command: '/4',
        label: 'Chất khí',
        template: r'$\uparrow$',
      ),
      ScientificShortcut(
        command: '/5',
        label: 'Chất kết tủa',
        template: r'$\downarrow$',
      ),
      ScientificShortcut(
        command: '/6',
        label: 'Điều kiện xúc tác',
        template: r'$\overset{xt}{\rightarrow}$',
      ),
      ScientificShortcut(
        command: '/7',
        label: 'Đun nóng',
        template: r'$\Delta$',
      ),
      ScientificShortcut(
        command: '/8',
        label: 'Trạng thái khí',
        template: r'$\mathrm{(g)}$',
      ),
      ScientificShortcut(
        command: '/9',
        label: 'Trạng thái dung dịch',
        template: r'$\mathrm{(aq)}$',
      ),
      ScientificShortcut(
        command: '/10',
        label: 'Điện tích dương',
        template: r'$^{+}$',
      ),
      ScientificShortcut(
        command: '/11',
        label: 'Điện tích âm',
        template: r'$^{-}$',
      ),
      ScientificShortcut(
        command: '/12',
        label: 'Liên kết đôi',
        template: r'$=$',
      ),
      ScientificShortcut(
        command: '/13',
        label: 'Liên kết ba',
        template: r'$\equiv$',
      ),
      ScientificShortcut(
        command: '/14',
        label: 'pH',
        template: r'$\mathrm{pH}$',
      ),
    ],
    ScientificCategory.greek: [
      ScientificShortcut(command: '/1', label: 'Alpha', template: r'$\alpha$'),
      ScientificShortcut(command: '/2', label: 'Beta', template: r'$\beta$'),
      ScientificShortcut(command: '/3', label: 'Gamma', template: r'$\gamma$'),
      ScientificShortcut(command: '/4', label: 'Delta', template: r'$\Delta$'),
    ],
    ScientificCategory.languages: [
      ScientificShortcut(command: '/1', label: 'Âm think', template: '/θ/'),
      ScientificShortcut(command: '/2', label: 'Âm this', template: '/ð/'),
      ScientificShortcut(command: '/3', label: 'Âm ship', template: '/ʃ/'),
      ScientificShortcut(command: '/4', label: 'Âm vision', template: '/ʒ/'),
    ],
  };

  static Map<ScientificCategory, List<ScientificShortcut>> freshDefaults() => {
    for (final entry in defaults.entries)
      entry.key: entry.value.map((shortcut) => shortcut.copyWith()).toList(),
  };

  static Map<String, dynamic> _encode(
    Map<ScientificCategory, List<ScientificShortcut>> shortcuts,
  ) => {
    for (final entry in shortcuts.entries)
      entry.key.name: [
        for (final shortcut in entry.value)
          {
            'command': shortcut.command,
            'label': shortcut.label,
            'template': shortcut.template,
            'blockType': shortcut.blockType?.name,
          },
      ],
  };

  static Map<ScientificCategory, List<ScientificShortcut>> _decode(
    Map<String, dynamic> saved,
  ) {
    final result = freshDefaults();
    for (final category in ScientificCategory.values) {
      final value = saved[category.name];
      if (value is List) {
        result[category] = value
            .whereType<Map>()
            .map((raw) {
              final blockName = raw['blockType'] as String?;
              MathBlockType? blockType;
              if (blockName != null) {
                for (final type in MathBlockType.values) {
                  if (type.name == blockName) blockType = type;
                }
              }
              return ScientificShortcut(
                command: raw['command'] as String? ?? '',
                label: raw['label'] as String? ?? '',
                template: raw['template'] as String?,
                blockType: blockType,
              );
            })
            .where((shortcut) => shortcut.command.isNotEmpty)
            .toList();
      } else if (value is Map) {
        // Backward compatibility with the first label -> command format.
        result[category] = result[category]!.map((shortcut) {
          final command = value[shortcut.label] as String?;
          return command == null
              ? shortcut
              : shortcut.copyWith(command: command);
        }).toList();
      }
    }
    return result;
  }

  static Future<Map<ScientificCategory, List<ScientificShortcut>>>
  load() async {
    final result = freshDefaults();
    final prefs = await SharedPreferences.getInstance();
    try {
      final remote = Supabase
          .instance
          .client
          .auth
          .currentUser
          ?.userMetadata?[_preferenceKey];
      if (remote is Map) {
        return _decode(Map<String, dynamic>.from(remote));
      }
    } catch (_) {
      // Supabase may not be configured in tests or offline sessions.
    }

    final raw = prefs.getString(_preferenceKey);
    if (raw != null) {
      try {
        return _decode(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        return result;
      }
    }
    return result;
  }

  static Future<void> save(
    Map<ScientificCategory, List<ScientificShortcut>> shortcuts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _encode(shortcuts);
    await prefs.setString(_preferenceKey, jsonEncode(encoded));
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await client.auth.updateUser(
          UserAttributes(data: {_preferenceKey: encoded}),
        );
      }
    } catch (_) {
      // Local persistence remains authoritative while offline.
    }
  }
}
