import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/cover_color.dart';
import '../util/level.dart';
import '../util/version.dart';
import 'marquee.dart';

/// 首頁列表裡的單首歌區塊。背景是曲繪高斯模糊，文字自動黑白切換。
class SongCard extends StatefulWidget {
  final Song song;

  /// 長按整個區塊 = 打完了，移除。
  final VoidCallback onDone;

  /// 點擊區塊 = 開啟歌曲詳情。
  final VoidCallback? onTap;

  const SongCard({
    super.key,
    required this.song,
    required this.onDone,
    this.onTap,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  Color? _seed;

  @override
  void initState() {
    super.initState();
    _pickColor();
  }

  @override
  void didUpdateWidget(SongCard old) {
    super.didUpdateWidget(old);
    if (old.song.localCover != widget.song.localCover ||
        old.song.imageName != widget.song.imageName) {
      _pickColor();
    }
  }

  ImageProvider? get _coverImage {
    final local = widget.song.localCover;
    if (local != null) return FileImage(File(local));
    final url = widget.song.coverUrl;
    if (url != null) return NetworkImage(url);
    return null;
  }

  String get _colorKey =>
      widget.song.localCover ?? widget.song.imageName ?? widget.song.id;

  Future<void> _pickColor() async {
    final img = _coverImage;
    if (img == null) {
      if (mounted) setState(() => _seed = null);
      return;
    }
    final hit = CoverColor.cached(_colorKey);
    if (hit != null) {
      setState(() => _seed = hit);
      return;
    }
    final c = await CoverColor.of(_colorKey, img);
    if (mounted) setState(() => _seed = c);
  }

  /// 曲繪主色偏亮嗎。決定遮罩往哪邊拉、文字用黑還是白。
  bool get _isLight => (_seed?.computeLuminance() ?? 0) > 0.45;

  /// 背景太白時自動換成黑字。
  Color get _fg {
    if (_seed == null) return Theme.of(context).colorScheme.onSurface;
    return _isLight ? Colors.black : Colors.white;
  }

  Color get _sub => _fg.withOpacity(0.68);

  /// 長按難度看精確定數。
  void _showPrecise() {
    final song = widget.song;
    final d = difficultyOf(song.diff);
    final name = song.isUtage ? (song.utageKey ?? '宴会場') : d.full;
    final parts = [
      '${song.typeLabel} $name',
      levelPrecise(song.internal, song.level),
      if (song.version.isNotEmpty) song.version,
    ];

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
          parts.join('  ·  '),
          style: const TextStyle(fontWeight: FontWeight.w400),
        ),
        duration: const Duration(milliseconds: 2200),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final song = widget.song;
    final d = difficultyOf(song.diff);
    final cover = _coverImage;
    final fg = _fg;
    final sub = _sub;

    // 副標題：版本 · 譜面種類 · 曲師
    final subtitle = [
      if (song.version.isNotEmpty) versionShort(song.version),
      if (song.typeLabel.isNotEmpty) song.typeLabel,
      if ((song.artist ?? '').trim().isNotEmpty) song.artist!.trim(),
    ].join('  ·  ');

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onDone,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          children: [
            // 高斯模糊背景。
            //
            // tileMode 用 clamp 而非 decal：decal 會讓邊緣淡出成透明，
            // 卡片四角就會透出底色。另外整張放大 1.3 倍，把模糊邊緣
            // 推到可視範圍外，四邊才不會有一圈糊掉的暗角。
            if (cover != null)
              Positioned.fill(
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.3,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 24,
                        sigmaY: 24,
                        tileMode: TileMode.clamp,
                      ),
                      child: Image(
                        image: cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            // 遮罩層：把模糊背景整體拉向亮或暗的一邊，
            // 保證等一下選的黑字或白字一定夠對比。
            if (cover != null)
              Positioned.fill(
                child: ColoredBox(
                  color: _isLight
                      ? Colors.white.withOpacity(0.42)
                      : Colors.black.withOpacity(0.38),
                ),
              ),
            // 前景內容
            Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: cover == null
                          ? ColoredBox(
                              color: fg.withOpacity(0.10),
                              child: Icon(Icons.music_note_outlined,
                                  size: 22, color: sub),
                            )
                          : Image(
                              image: cover,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => ColoredBox(
                                color: fg.withOpacity(0.10),
                                child: Icon(Icons.broken_image_outlined,
                                    size: 20, color: sub),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Marquee(
                          text: song.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: fg,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Marquee(
                            text: subtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: sub,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onLongPress: _showPrecise,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          song.isUtage
                              ? (song.level.isEmpty ? '宴' : song.level)
                              : (song.level.isEmpty ? '?' : song.level),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: fg,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DifficultyDot(color: d.color),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
