import 'package:flutter/material.dart';
import '../util/level.dart';

class ChartTypeBadge extends StatelessWidget {
  final String type;
  final double height;
  const ChartTypeBadge({super.key, required this.type, this.height = 23});
  @override
  Widget build(BuildContext context) {
    if (type == 'dx' || type == 'std') {
      // 素材底部帶陰影，視覺主體比圖片尺寸小：放大 18%，
      // 並稍向下移動，讓主體中心與旁邊膠囊對齊。
      // 預留實際寬度，避免放大後蓋到難度文字。
      final imageHeight = height * 1.18;
      return SizedBox(
        height: height,
        width: imageHeight * 140 / 52,
        child: OverflowBox(
          maxHeight: imageHeight,
          child: Transform.translate(
            offset: Offset(0, imageHeight * .035),
            child: Image.asset('assets/badges/$type.png',
              height: imageHeight, width: imageHeight * 140 / 52,
              fit: BoxFit.contain,
              semanticLabel: type == 'dx' ? 'DX 譜面' : 'STD 譜面'),
          ),
        ),
      );
    }
    return Text(type == 'utage2p' ? '宴 2P' : '宴會場');
  }
}
class DifficultyPill extends StatelessWidget {
  final int diff;
  final String? label;
  const DifficultyPill({super.key, required this.diff, this.label});
  @override
  Widget build(BuildContext context) {
    final d = difficultyOf(diff);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: d.color, borderRadius: BorderRadius.circular(99),
        border: diff == 4 ? Border.all(color: Colors.black26, width: .7) : null),
      child: Text(label ?? d.full, maxLines: 1, style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.w400, color: d.color.computeLuminance() > .45 ? Colors.black : Colors.white)),
    );
  }
}
class PreciseLevel extends StatelessWidget {
  final double? value;
  final String fallback;
  final Color color;
  final double size;
  const PreciseLevel({super.key, required this.value, required this.fallback,
    required this.color, this.size = 23});
  @override
  Widget build(BuildContext context) {
    final text = value?.toStringAsFixed(1);
    return Text.rich(TextSpan(children: text == null
      ? [TextSpan(text: fallback.isEmpty ? '—' : fallback)]
      : [TextSpan(text: text.split('.').first),
         TextSpan(text: '.${text.split('.').last}', style: TextStyle(color: color.withOpacity(.65))) ]),
      maxLines: 1, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w400));
  }
}
