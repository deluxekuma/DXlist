import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// 從曲繪取主色，做成每首歌自己的區塊配色。算過的會快取。
class CoverColor {
  static final Map<String, Color> _cache = {};

  static Color? cached(String key) => _cache[key];

  static Future<Color?> of(String key, ImageProvider image) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        image,
        size: const Size(80, 80),
        maximumColorCount: 12,
      );
      final c = palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.mutedColor?.color;
      if (c != null) _cache[key] = c;
      return c;
    } catch (_) {
      return null;
    }
  }
}
