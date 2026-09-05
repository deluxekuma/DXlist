import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palette_generator/palette_generator.dart';

/// 從曲繪取主色。算過的會快取。
///
/// 取的是 dominantColor（畫面佔比最大的顏色），因為卡片背景是整張曲繪
/// 高斯模糊後的樣子，跟平均亮度比較接近。用 vibrantColor 會被小面積的
/// 鮮豔色帶偏，導致亮度判斷失準、文字黑白選錯。
class CoverColor {
  static final Map<String, Color> _cache = {};

  static Color? cached(String key) => _cache[key];

  static Future<Color?> of(String key, ImageProvider image) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('coverColorV2:$key');
      if (saved != null) return _cache[key] = Color(saved);
      final palette = await PaletteGenerator.fromImageProvider(
        image,
        size: const Size(80, 80),
        maximumColorCount: 12,
      );
      final c = palette.dominantColor?.color ??
          palette.mutedColor?.color ??
          palette.vibrantColor?.color;
      if (c != null) {
        _cache[key] = c;
        await prefs.setInt('coverColorV2:$key', c.value);
      }
      return c;
    } catch (_) {
      return null;
    }
  }
}
