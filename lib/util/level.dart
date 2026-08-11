import 'package:flutter/material.dart';

/// 五個難度的名稱與顏色（取自 dxdata 的官方配色）。
class Difficulty {
  final String short;
  final String full;
  final Color color;
  const Difficulty(this.short, this.full, this.color);
}

const List<Difficulty> kDifficulties = [
  Difficulty('BAS', 'BASIC', Color(0xFF22BB5B)),
  Difficulty('ADV', 'ADVANCED', Color(0xFFFB9C2D)),
  Difficulty('EXP', 'EXPERT', Color(0xFFF64861)),
  Difficulty('MAS', 'MASTER', Color(0xFF9E45E2)),
  Difficulty('Re:MAS', 'Re:MASTER', Colors.white),
  // 5 = 宴會場
  Difficulty('宴', '宴会場', Color(0xFFFF69B4)),
];

Difficulty difficultyOf(int index) =>
    kDifficulties[index.clamp(0, kDifficulties.length - 1)];

/// 難度色圓點。Re:MASTER 是純白，在亮背景上要描邊才看得見。
class DifficultyDot extends StatelessWidget {
  final Color color;
  final double size;

  const DifficultyDot({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final needsBorder = color.computeLuminance() > 0.8;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: needsBorder
            ? Border.all(color: Colors.black.withOpacity(0.25), width: 0.8)
            : null,
      ),
    );
  }
}

/// 把定數轉成遊戲內顯示的等級。
///
///   13 / 13.0 ~ 13.4  -> 13
///   14+ / 14.5 ~ 14.9 -> 14+
///
/// 從曲庫加進來的歌會直接帶官方等級字串，這個只在手動輸入時用得到。
String levelDisplay(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '?';

  if (s.endsWith('+')) {
    final base = s.substring(0, s.length - 1).trim();
    final n = double.tryParse(base);
    return n == null ? s : '${n.floor()}+';
  }

  final v = double.tryParse(s);
  if (v == null) return s;

  final base = v.floor();
  return (v - base) >= 0.5 ? '$base+' : '$base';
}

/// 長按時顯示的精確定數。
String levelPrecise(double? internal, String raw) {
  if (internal != null) return internal.toStringAsFixed(1);
  final s = raw.trim();
  if (s.isEmpty) return '未知';
  if (s.endsWith('+')) return s;
  final v = double.tryParse(s);
  return v == null ? s : v.toStringAsFixed(1);
}
