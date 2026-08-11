import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/song.dart';
import '../util/level.dart';
import '../util/version.dart';
import '../widgets/marquee.dart';
import 'manual_add_page.dart';

/// 搜歌 → 選譜面 → 加進清單。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<CatalogSong> _results = const [];
  bool _loading = true;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    // 先把曲庫讀進記憶體，之後每次輸入都是本地搜尋。
    Catalog.songs().then((_) {
      if (mounted) setState(() => _loading = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String q) async {
    final seq = ++_seq;
    final hits = await Catalog.search(q);
    if (!mounted || seq != _seq) return;
    setState(() => _results = hits);
  }

  Future<void> _openSheetPicker(CatalogSong song) async {
    final picked = await showModalBottomSheet<Sheet>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SheetPicker(song: song),
    );
    if (picked == null || !mounted) return;
    Navigator.pop(context, Song.fromSheet(song, picked));
  }

  Future<void> _manual() async {
    final song = await Navigator.push<Song>(
      context,
      MaterialPageRoute(builder: (_) => const ManualAddPage()),
    );
    if (song != null && mounted) Navigator.pop(context, song);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: '搜歌名、曲師或縮寫',
            border: InputBorder.none,
            hintStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '清空',
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '手動新增',
            onPressed: _manual,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? _empty(scheme)
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) => _ResultTile(
                    song: _results[i],
                    onTap: () => _openSheetPicker(_results[i]),
                  ),
                ),
    );
  }

  Widget _empty(ColorScheme scheme) {
    final typed = _controller.text.trim().isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            typed ? '曲庫裡沒有這首' : '曲庫 ${Catalog.updateDate} 更新',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _manual,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('手動新增',
                style: TextStyle(fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final CatalogSong song;
  final VoidCallback onTap;

  const _ResultTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = song.coverUrl;

    final version = song.debutVersion;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: url == null
                    ? ColoredBox(color: scheme.surfaceContainerHighest)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: scheme.surfaceContainerHighest),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Marquee(
                    text: song.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      if (song.isRemoved)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '已刪除',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: scheme.error.withOpacity(0.85),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Marquee(
                          text: [
                            if (version.isNotEmpty) versionShort(version),
                            if (song.artist.isNotEmpty) song.artist,
                          ].join('  ·  '),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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

/// 選譜面：DX / STD / 宴會場 各難度。
class _SheetPicker extends StatelessWidget {
  final CatalogSong song;

  const _SheetPicker({required this.song});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 依 dx → std → 宴 排，同組內按難度排。
    const order = {'dx': 0, 'std': 1, 'utage': 2, 'utage2p': 3};
    final sheets = [...song.sheets]..sort((a, b) {
        final t = (order[a.type] ?? 9).compareTo(order[b.type] ?? 9);
        return t != 0 ? t : a.diff.compareTo(b.diff);
      });

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shrinkWrap: true,
          children: [
            Text(
              song.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            for (final s in sheets) _row(context, s),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Sheet s) {
    final scheme = Theme.of(context).colorScheme;
    final d = difficultyOf(s.diff);
    final label = s.isUtage ? (s.utageKey ?? '宴') : d.full;

    return InkWell(
      onTap: () => Navigator.pop(context, s),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: d.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 11),
            Text(
              s.typeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurface,
                ),
              ),
            ),
            // 同一首歌的 DX / STD 譜可能來自不同代，不一樣時標出來。
            if (s.version.isNotEmpty && s.version != song.debutVersion)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  versionShort(s.version),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (s.statusLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  s.statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: s.isRemoved
                        ? scheme.error.withOpacity(0.8)
                        : scheme.onSurfaceVariant.withOpacity(0.75),
                  ),
                ),
              ),
            Text(
              s.internal == null
                  ? s.level
                  : '${s.level}  ${s.internal!.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
