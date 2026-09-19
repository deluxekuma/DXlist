import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/song.dart';
import '../services/store.dart';
import '../util/typography.dart';
import '../widgets/song_card.dart';
import 'detail_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await Store.load();
    if (!mounted) return;
    setState(() {
      _songs = list;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final song = await Navigator.push<Song>(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
    if (song == null) return;
    setState(() => _songs.add(song));
    await Store.save(_songs);
  }

  Future<void> _openDetails(Song song) async {
    CatalogSong? catalog;
    try {
      final all = await Catalog.songs();
      // 先認曲繪檔名：上游同一首曲的曲名不變、曲繪檔名也穩定，
      // 但曲庫裡有同名的不同曲（例如兩首 Link），只比曲名會抓錯那首。
      final image = song.imageName;
      if (image != null && image.isNotEmpty) {
        for (final item in all) {
          if (item.imageName == image) {
            catalog = item;
            break;
          }
        }
      }
      if (catalog == null) {
        final target = Catalog.norm(song.title);
        for (final item in all) {
          if (item.normTitle == target) {
            catalog = item;
            break;
          }
        }
      }
    } catch (_) {
      // 手動新增或離線時仍然開啟基本詳情。
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(song: song, catalog: catalog),
      ),
    );
  }

  Future<void> _done(int index) async {
    final removed = _songs[index];
    setState(() => _songs.removeAt(index));
    await Store.save(_songs);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('已打完 ${removed.title}',
            style: const TextStyle(fontWeight: FontWeight.w400)),
        action: SnackBarAction(
          label: '復原',
          onPressed: () async {
            setState(() =>
                _songs.insert(index.clamp(0, _songs.length), removed));
            await Store.save(_songs);
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('DXList', style: kTitleStyle),
            // 標題下面接一行字，標題列才不會空一大塊。
            if (!_loading && _songs.isNotEmpty)
              Text('待打 ${_songs.length} 首', style: captionStyle(context)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.queue_music_outlined,
                        size: 44,
                        color: scheme.onSurfaceVariant.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '清單還是空的',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '按右下角的「添加」把想打的譜面放進來',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: scheme.onSurfaceVariant.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 96),
                  itemCount: _songs.length,
                  itemBuilder: (context, i) => SongCard(
                    key: ValueKey(_songs[i].id),
                    song: _songs[i],
                    onDone: () => _done(i),
                    onTap: () => _openDetails(_songs[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label:
            const Text('添加', style: TextStyle(fontWeight: FontWeight.w400)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        height: 62,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: '主頁',
          ),
        ],
        onDestinationSelected: (_) {},
      ),
    );
  }
}
