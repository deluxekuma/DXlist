import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 文字太長時自動水平滾動輪播，放得下就正常靜止顯示。
class Marquee extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // 每秒滑多少像素
  final double gap; // 兩輪之間的空隙

  const Marquee({
    super.key,
    required this.text,
    this.style,
    this.velocity = 26,
    this.gap = 36,
  });

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _offset = ValueNotifier(0);
  Ticker? _ticker;
  Duration _last = Duration.zero;

  // 量過的寬度快取起來，不要每一帧都重算。
  double? _textWidth;
  String? _measuredFor;
  double _viewWidth = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(Marquee old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.style != widget.style) {
      _textWidth = null;
      _measuredFor = null;
      _offset.value = 0;
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;

    final w = _textWidth;
    if (w == null || w <= _viewWidth) {
      if (_offset.value != 0) _offset.value = 0;
      return;
    }
    if (dt <= 0) return;

    final loop = w + widget.gap;
    _offset.value = (_offset.value + widget.velocity * dt) % loop;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _measure(BuildContext context, TextStyle style) {
    final key = '${widget.text}|${style.fontSize}|${style.fontWeight}';
    if (_measuredFor == key) return;
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    _textWidth = tp.width;
    _measuredFor = key;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final lineHeight = (style.fontSize ?? 14) * 1.45;
    _measure(context, style);

    final label = Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
    );

    return LayoutBuilder(
      builder: (context, c) {
        _viewWidth = c.maxWidth;
        final w = _textWidth ?? 0;

        if (w <= _viewWidth) {
          return SizedBox(
            height: lineHeight,
            child: Align(alignment: Alignment.centerLeft, child: label),
          );
        }

        final loop = w + widget.gap;
        return SizedBox(
          height: lineHeight,
          child: ClipRect(
            child: ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (context, off, _) => Stack(
                children: [
                  for (final base in <double>[0, loop])
                    Positioned(
                      left: base - off,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: label,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
