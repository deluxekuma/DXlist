import 'dart:io';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/cover_color.dart';
import '../util/level.dart';
import '../util/version.dart';
import 'marquee.dart';

/// 首頁列表裡的單首歌區塊。背景色從曲繪自動取色。
class SongCard extends StatefulWidget {
  final Song song;

  /// 長按整個區塊 = 打完了，移除。
  final VoidCallback onDone;

  const SongCard({
    super.key,
    required this.song,
    required this.onDone,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  Color? _seed;

  // fromSeed 有點吃 CPU，同一個種子色只算一次。
  static final Map<String, ColorScheme> _schemeCache = {};

  static ColorScheme _schemeFor(Color seed, Brightness brightness) {
    final key = '${seed.value}|${brightness.name}';
    return _schemeCache.putIfAbsent(
      key,
      () => ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    );
  }

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
    final base = theme.colorScheme;

    // 有取到曲繪主色就用它生成一組 M3 配色，沒有就沿用系統莫奈配色。
    final scheme =
        _seed == null ? base : _schemeFor(_seed!, theme.brightness);

    final bg = scheme.secondaryContainer;
    final fg = scheme.onSecondaryContainer;
    final sub = fg.withOpacity(0.62);

    final song = widget.song;
    final d = difficultyOf(song.diff);
    final cover = _coverImage;

    // 副標題：版本 · 譜面種類 · 曲師
    final subtitle = [
      if (song.version.isNotEmpty) versionShort(song.version),
      if (song.typeLabel.isNotEmpty) song.typeLabel,
      if ((song.artist ?? '').trim().isNotEmpty) song.artist!.trim(),
    ].join('  ·  ');

    return GestureDetector(
      onLongPress: widget.onDone,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
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
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: d.color, shape: BoxShape.circle),
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
