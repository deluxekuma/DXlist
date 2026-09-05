import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/catalog.dart';
import '../models/song.dart';
import '../util/version.dart';
import '../widgets/chart_badges.dart';
import '../widgets/cover_view.dart';

String releaseDateLabel(String raw, {DateTime? now}) {
  final date = DateTime.tryParse(raw);
  if (date == null) return '未提供';
  final today = now ?? DateTime.now();
  // 用日曆日期而非 24 小時差，避免跨日、夏令時間造成誤差。
  final days = DateTime.utc(today.year, today.month, today.day)
    .difference(DateTime.utc(date.year, date.month, date.day)).inDays;
  final relative = days == 0 ? '今天' : days == 1 ? '昨天' : days == 2 ? '前天'
    : days > 0 ? '$days 天前' : '${-days} 天後';
  return '${date.year}年${date.month}月${date.day}日（$relative）';
}

class DetailPage extends StatefulWidget {
  final Song song;
  final CatalogSong? catalog;
  const DetailPage({super.key, required this.song, this.catalog});
  @override
  State<DetailPage> createState() => _DetailPageState();
}
class _DetailPageState extends State<DetailPage> {
  Sheet? _selected;
  @override
  void initState() {
    super.initState();
    for (final sheet in widget.catalog?.sheets ?? <Sheet>[]) {
      if (sheet.type == widget.song.type && sheet.diff == widget.song.diff) {
        _selected = sheet; break;
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final catalog = widget.catalog;
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface;
    final sheets = catalog?.sheets ?? <Sheet>[];
    final dates = sheets.map((s) => s.releaseDate).where((s) => DateTime.tryParse(s) != null).toList()..sort();
    final debut = dates.isEmpty ? '' : dates.first;
    final current = _selected;
    final notes = current?.notes ?? song.notes;
    final bpm = catalog?.bpm ?? song.bpm;
    return Scaffold(
      appBar: AppBar(title: const Text('歌曲詳情')),
      body: ListView(children: [
        ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Stack(children: [
            Positioned.fill(child: CoverView(url: song.coverUrl, local: song.localCover,
              builder: (image) => ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.clamp),
                child: Image(image: image, fit: BoxFit.cover)))),
            Positioned.fill(child: ColoredBox(color: scheme.surface.withOpacity(.82))),
            Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(width: 108, height: 108,
                  child: CoverView(url: song.coverUrl, local: song.localCover))),
                const Spacer(),
                PreciseLevel(value: current?.internal ?? song.internal,
                  fallback: current?.level ?? song.level, color: fg, size: 42),
              ]),
              const SizedBox(height: 16),
              Text(song.title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w400)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                ChartTypeBadge(type: current?.type ?? song.type, height: 26),
                DifficultyPill(diff: current?.diff ?? song.diff, label: current?.utageKey),
              ]),
              const SizedBox(height: 12),
              Text('ver. ${versionShort(current?.version ?? song.version)}'),
              const SizedBox(height: 8),
              Text('樂曲上線日 ${releaseDateLabel(debut)}'),
              if (current != null && current.releaseDate.isNotEmpty && current.releaseDate != debut)
                Text('此譜面上線日 ${releaseDateLabel(current.releaseDate)}'),
            ])),
          ])),
        Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('譜面一覽', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 10),
          for (final type in ['dx', 'std', 'utage', 'utage2p'])
            if (sheets.any((s) => s.type == type)) _group(type, sheets.where((s) => s.type == type).toList(), fg),
          if (sheets.isEmpty) const Text('此項目沒有曲庫譜面資料'),
          const SizedBox(height: 22),
          const Text('詳細資訊', style: TextStyle(fontSize: 20)),
          _row('類別', catalog?.category ?? '手動新增'),
          _row('曲師', catalog?.artist ?? song.artist ?? ''),
          _row('BPM', bpm == null ? '未提供' : bpm.toStringAsFixed(bpm % 1 == 0 ? 0 : 1)),
          _row('譜師', current?.designer ?? ''),
          const SizedBox(height: 20),
          const Text('音符統計', style: TextStyle(fontSize: 20)),
          for (final entry in const {'tap':'Tap', 'hold':'Hold', 'slide':'Slide', 'touch':'Touch', 'break':'Break', 'total':'總計'}.entries)
            _row(entry.value, notes[entry.key]?.toString() ?? '未提供'),
          const SizedBox(height: 18),
          Text('資料來源：dxrating · 曲庫 ${Catalog.updateDate}', style: TextStyle(fontSize: 11, color: fg.withOpacity(.6))),
        ])),
      ]),
    );
  }
  Widget _group(String type, List<Sheet> sheets, Color fg) {
    sheets.sort((a,b) => a.diff.compareTo(b.diff));
    final baseVersion = sheets.first.version;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
        ChartTypeBadge(type: type), const SizedBox(width: 12),
        Expanded(child: Text(versionShort(baseVersion), style: TextStyle(color: fg.withOpacity(.7)))),
      ])),
      for (final sheet in sheets)
        Material(color: identical(sheet, _selected) ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12), child: InkWell(
            borderRadius: BorderRadius.circular(12), onTap: () => setState(() => _selected = sheet),
            child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                DifficultyPill(diff: sheet.diff, label: sheet.utageKey), const Spacer(),
                PreciseLevel(value: sheet.internal, fallback: sheet.level, color: fg, size: 20),
              ]),
              // 譜師缺資料就保留空白，不以曲師或「未知」代替。
              Padding(padding: const EdgeInsets.only(top: 5), child: Text(sheet.designer, style: TextStyle(fontSize: 12, color: fg.withOpacity(.7)))),
              if (sheet.version != baseVersion) Text('ver. ${versionShort(sheet.version)}', style: const TextStyle(fontSize: 11)),
            ])),
          )),
    ]);
  }
  Widget _row(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.2)))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 88, child: Text(label)), Expanded(child: Text(value)),
    ]),
  );
}
