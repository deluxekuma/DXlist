import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/song.dart';
import '../util/level.dart';
import '../util/version.dart';

/// 參照 dxrating 歌曲詳情頁的手機版詳情畫面。
///
/// 上半部用曲繪做高斯模糊背景，下面是圓角白色 / 深色詳情面板；
/// 不放定數變化評論和評論區，先把曲目資料做好。
class DetailPage extends StatelessWidget {
  final Song song;
  final CatalogSong? catalog;

  const DetailPage({
    super.key,
    required this.song,
    this.catalog,
  });

  ImageProvider? get _cover {
    if (song.localCover != null) return FileImage(File(song.localCover!));
    if (song.coverUrl != null) return NetworkImage(song.coverUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cover = _cover;
    final diff = difficultyOf(song.diff);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark ? scheme.surfaceContainerLow : Colors.white;
    final foreground = isDark ? scheme.onSurface : const Color(0xFF202124);
    final secondary = foreground.withValues(alpha: 0.62);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // 參照 dxrating 頂部：曲繪放大、模糊、鋪滿。
          if (cover != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 28,
                  sigmaY: 28,
                  tileMode: TileMode.clamp,
                ),
                child: Transform.scale(
                  scale: 1.28,
                  child: Image(image: cover, fit: BoxFit.cover),
                ),
              ),
            ),
          Positioned.fill(
            child: ColoredBox(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.58)
                  : Colors.white.withValues(alpha: 0.52),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: foreground,
                  title: const Text(
                    '歌曲詳情',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _Hero(
                      song: song,
                      cover: cover,
                      diff: diff,
                      foreground: foreground,
                      secondary: secondary,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 22),
                    padding: const EdgeInsets.fromLTRB(18, 28, 18, 40),
                    decoration: BoxDecoration(
                      color: panel.withValues(alpha: 0.96),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: _Content(
                      song: song,
                      catalog: catalog,
                      foreground: foreground,
                      secondary: secondary,
                      panel: panel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Song song;
  final ImageProvider? cover;
  final Difficulty diff;
  final Color foreground;
  final Color secondary;

  const _Hero({
    required this.song,
    required this.cover,
    required this.diff,
    required this.foreground,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 142,
                height: 142,
                child: cover == null
                    ? ColoredBox(
                        color: foreground.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.music_note_outlined,
                          size: 54,
                          color: secondary,
                        ),
                      )
                    : Image(image: cover, fit: BoxFit.cover),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    song.internal?.toStringAsFixed(1) ?? song.level,
                    style: TextStyle(
                      fontSize: 51,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: diff.color,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      diff.full,
                      style: TextStyle(
                        color: diff.color.computeLuminance() > 0.75
                            ? Colors.black
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          song.title,
          style: TextStyle(
            color: foreground,
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w500,
          ),
        ),
        if ((song.artist ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            song.artist!,
            style: TextStyle(
              color: secondary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              text: versionShort(song.version),
              color: foreground.withValues(alpha: 0.1),
              foreground: foreground,
            ),
            _Pill(
              text: song.typeLabel,
              color: foreground.withValues(alpha: 0.1),
              foreground: foreground,
            ),
          ],
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  final Song song;
  final CatalogSong? catalog;
  final Color foreground;
  final Color secondary;
  final Color panel;

  const _Content({
    required this.song,
    required this.catalog,
    required this.foreground,
    required this.secondary,
    required this.panel,
  });

  Sheet? get _selectedSheet {
    final sheets = catalog?.sheets ?? const <Sheet>[];
    for (final sheet in sheets) {
      if (sheet.type == song.type && sheet.diff == song.diff) return sheet;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sheets = catalog?.sheets ?? const <Sheet>[];
    final selectedSheet = _selectedSheet;
    final notes = song.notes.isNotEmpty
        ? song.notes
        : (selectedSheet?.notes ?? const <String, int>{});
    final bpm = song.bpm ?? catalog?.bpm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('譜面一覽', foreground),
        const SizedBox(height: 12),
        if (sheets.isEmpty)
          _InfoRow('定數', song.internal?.toStringAsFixed(1) ?? song.level,
              foreground: foreground, secondary: secondary)
        else
          _HistoryTable(
            sheets: sheets,
            selected: song,
            foreground: foreground,
            secondary: secondary,
            panel: panel,
          ),
        const SizedBox(height: 26),
        _SectionTitle('詳細資訊', foreground),
        const SizedBox(height: 8),
        _InfoRow('類別', catalog?.category ?? '手動新增',
            foreground: foreground, secondary: secondary),
        _InfoRow('曲師', song.artist ?? '—',
            foreground: foreground, secondary: secondary),
        _InfoRow(
          'BPM',
          bpm == null
              ? '—'
              : bpm.toStringAsFixed(bpm % 1 == 0 ? 0 : 1),
          foreground: foreground,
          secondary: secondary,
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 26),
          _SectionTitle('音符統計', foreground),
          const SizedBox(height: 8),
          for (final entry in const [
            MapEntry('tap', 'Tap'),
            MapEntry('hold', 'Hold'),
            MapEntry('slide', 'Slide'),
            MapEntry('touch', 'Touch'),
            MapEntry('break', 'Break'),
            MapEntry('total', '總計'),
          ])
            if (notes.containsKey(entry.key))
              _InfoRow(
                entry.value,
                '${notes[entry.key]}',
                foreground: foreground,
                secondary: secondary,
              ),
        ],
      ],
    );
  }
}

class _HistoryTable extends StatelessWidget {
  final List<Sheet> sheets;
  final Song selected;
  final Color foreground;
  final Color secondary;
  final Color panel;

  const _HistoryTable({
    required this.sheets,
    required this.selected,
    required this.foreground,
    required this.secondary,
    required this.panel,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = [...sheets]..sort((a, b) {
        final av = a.internal ?? -1;
        final bv = b.internal ?? -1;
        return av.compareTo(bv);
      });

    return Column(
      children: [
        for (final sheet in ordered)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: foreground.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${versionShort(sheet.version)} · ${sheet.typeLabel}',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  sheet.internal?.toStringAsFixed(1) ?? sheet.level,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 17,
                    fontWeight: sheet.type == selected.type &&
                            sheet.diff == selected.diff
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color foreground;
  final Color secondary;

  const _InfoRow(
    this.label,
    this.value, {
    required this.foreground,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: foreground.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: secondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color foreground;

  const _Pill({
    required this.text,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
