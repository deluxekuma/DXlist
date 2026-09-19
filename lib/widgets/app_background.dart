import 'package:flutter/material.dart';

/// 主題色純色底之上疊一層 20% 透明度的背景圖。
///
/// 這裡刻意「疊加」而不是取代：底下仍然是 colorScheme.surface，
/// 所以莫內取色、亮暗主題都照常運作；圖片只是淡淡鋪一層紋理。
///
/// 實作上是「先畫圖，再用 80% 的主題色壓上去」，效果與
/// 「圖片設 20% 不透明度疊在主題色上」完全相同（0.2×圖 + 0.8×主題色），
/// 但不必動用 Opacity 的 saveLayer，切換頁面時不會整層重新合成、
/// 也就不會閃一下。
class AppBackground extends StatefulWidget {
  /// 背景圖在 assets 裡的路徑。
  static const String asset = 'assets/IMG_20251207_125310.png';

  /// 疊加透明度。
  static const double opacity = 0.20;

  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  /// 全 app 共用同一個 ImageProvider，避免每次重建都產生新的物件。
  static const ImageProvider _provider = AssetImage(AppBackground.asset);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 先把圖解碼好放進快取，第一次顯示就是完整的一層，不會先空再補。
    precacheImage(_provider, context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // 底層：原本的主題純色。
        Positioned.fill(child: ColoredBox(color: scheme.surface)),
        // 背景圖，維持比例鋪滿，超出部分裁掉。純裝飾，不進語意樹。
        Positioned.fill(
          child: RepaintBoundary(
            child: Image(
              image: _provider,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        // 把主題色壓回去，等於圖片只有 20% 的存在感。
        Positioned.fill(
          child: ColoredBox(
            color: scheme.surface.withOpacity(1 - AppBackground.opacity),
          ),
        ),
        // 前景：整個 app 內容。
        widget.child,
      ],
    );
  }
}
