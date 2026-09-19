import 'package:flutter/material.dart';

/// 主題色純色底之上疊一層 20% 透明度的背景圖。
///
/// 這裡刻意「疊加」而不是取代：底下仍然是 colorScheme.surface，
/// 所以莫內取色、亮暗主題都照常運作；圖片只是淡淡鋪一層紋理。
class AppBackground extends StatelessWidget {
  /// 背景圖在 assets 裡的路徑。
  static const _asset = 'assets/IMG_20251207_125310.png';

  /// 疊加透明度。亮暗主題都用同一個值，維持你指定的 20%。
  static const double opacity = 0.20;

  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // 底層：原本的主題純色。
        Positioned.fill(child: ColoredBox(color: scheme.surface)),
        // 上層：背景圖，維持比例鋪滿，超出部分裁掉。
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              _asset,
              fit: BoxFit.cover,
              // 純裝飾，不進語意樹；失敗時靜靜留白，不影響任何功能。
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        // 前景：整個 app 內容。
        child,
      ],
    );
  }
}
