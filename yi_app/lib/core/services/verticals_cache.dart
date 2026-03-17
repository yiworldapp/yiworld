import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

/// Fetched once at startup. All screens call colorForSlug / labelForSlug
/// synchronously after that.
class VerticalsCache {
  VerticalsCache._();

  static final Map<String, Map<String, dynamic>> _cache = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final data = await Supabase.instance.client
          .from('verticals')
          .select('slug, label, color_hex')
          .order('label');
      for (final v in (data as List)) {
        _cache[v['slug'] as String] = Map<String, dynamic>.from(v as Map);
      }
      _loaded = true;
    } catch (_) {
      // Silently fall back if fetch fails
    }
  }

  /// Returns verticals as dropdown items — 'none' always first.
  static List<Map<String, String>> get list {
    final items = _cache.entries
        .where((e) => e.key != 'none')
        .map((e) => {'value': e.key, 'label': e.value['label'] as String})
        .toList()
      ..sort((a, b) => a['label']!.compareTo(b['label']!));
    return [
      {'value': 'none', 'label': 'None (General Member)'},
      ...items,
    ];
  }

  static Color colorForSlug(String? slug) {
    if (slug == null || slug == 'none') return AppColors.textMuted;
    final hex = _cache[slug]?['color_hex'] as String?;
    if (hex == null) return AppColors.textMuted;
    return _hexToColor(hex);
  }

  static String labelForSlug(String? slug) {
    if (slug == null || slug == 'none') return '';
    final label = _cache[slug]?['label'] as String?;
    return (label ?? slug).toUpperCase();
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '').padLeft(6, '0');
    return Color(int.parse('FF$h', radix: 16));
  }
}
