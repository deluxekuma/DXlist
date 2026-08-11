import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/store.dart';
import '../widgets/song_card.dart';
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
        title: const Text('主頁',
            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 19)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Text(
                    '清單是空的，右下角加一首吧',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 96),
                  itemCount: _songs.length,
                  itemBuilder: (context, i) => SongCard(
                    key: ValueKey(_songs[i].id),
                    song: _songs[i],
                    onDone: () => _done(i),
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
