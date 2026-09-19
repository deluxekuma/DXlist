import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/cover_cache.dart';
import '../services/cover_color.dart';
import '../util/version.dart';
import 'cover_view.dart';
import 'chart_badges.dart';
import 'marquee.dart';

/// 「未上線」標記：官方宣布過卻沒有實裝的譜面，跟「已刪除」不同。
class UnreleasedTag extends StatelessWidget {
  final Color color;

  const UnreleasedTag({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.5), width: 0.8),
      ),
      child: Text(
        '未上線',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          height: 1.1,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }
}

class SongCard extends StatefulWidget {
  final Song song;
  final VoidCallback onDone;
  final VoidCallback? onTap;
  const SongCard({super.key, required this.song, required this.onDone, this.onTap});
  @override
  State<SongCard> createState() => _SongCardState();
}
class _SongCardState extends State<SongCard> {
  Color? _seed;
  @override
  void initState() { super.initState(); _prepare(); }
  Future<void> _prepare() async {
    final url = widget.song.coverUrl;
    final local = widget.song.localCover;
    final asset = widget.song.coverAsset;
    if (url == null && local == null && asset == null) return;
    try {
      final ImageProvider provider;
      final String key;
      if (local != null) {
        provider = FileImage(File(local));
        key = local;
      } else if (asset != null) {
        provider = AssetImage(asset);
        key = asset;
      } else {
        provider = FileImage(await CoverCache.get(url!));
        key = url;
      }
      final color = await CoverColor.of(key, provider);
      if (mounted) setState(() => _seed = color);
    } catch (_) { /* CoverView exposes retry. */ }
  }
  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final hasCover = song.coverUrl != null ||
        song.localCover != null ||
        song.coverAsset != null;
    final light = _seed != null && _seed!.computeLuminance() > .45;
    final fg = hasCover ? (light ? Colors.black : Colors.white) : Theme.of(context).colorScheme.onSurface;
    return GestureDetector(onTap: widget.onTap, onLongPress: widget.onDone,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainerHighest),
        child: Stack(children: [
          if (hasCover) Positioned.fill(child: CoverView(url: song.coverUrl, local: song.localCover, asset: song.coverAsset,
            builder: (image) => Transform.scale(scale: 1.3, child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24, tileMode: TileMode.clamp),
              child: Image(image: image, fit: BoxFit.cover),
            )),
          )),
          if (hasCover) Positioned.fill(child: ColoredBox(color: light
            ? Colors.white.withOpacity(.48) : Colors.black.withOpacity(.55))),
          Padding(padding: const EdgeInsets.all(11), child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 62, height: 62,
              child: CoverView(url: song.coverUrl, local: song.localCover, asset: song.coverAsset))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Marquee(text: song.title, style: TextStyle(fontSize: 16, color: fg)),
              const SizedBox(height: 5),
              Row(children: [
                Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ChartTypeBadge(type: song.type), const SizedBox(width: 6),
                    DifficultyPill(diff: song.diff, label: song.isUtage ? song.utageKey : null),
                  ]))),
                if (song.unreleased) ...[
                  const SizedBox(width: 5),
                  UnreleasedTag(color: fg),
                ],
              ]),
              const SizedBox(height: 5),
              Marquee(text: 'ver. ${versionShort(song.version)}', style: TextStyle(fontSize: 12, color: fg.withOpacity(.8))),
            ])),
            const SizedBox(width: 9),
            PreciseLevel(value: song.internal, fallback: song.level, color: fg),
          ])),
        ]),
      ),
    );
  }
}
