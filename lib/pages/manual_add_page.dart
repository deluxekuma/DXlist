import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/song.dart';
import '../util/level.dart';

/// 曲庫裡沒有的歌（新曲、日限、消除曲）用這裡手動加。
class ManualAddPage extends StatefulWidget {
  const ManualAddPage({super.key});

  @override
  State<ManualAddPage> createState() => _ManualAddPageState();
}

class _ManualAddPageState extends State<ManualAddPage> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _level = TextEditingController();
  final _version = TextEditingController();

  int _diff = 3;
  String _type = 'dx';
  String? _localCover;

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _level.dispose();
    _version.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (x != null && mounted) setState(() => _localCover = x.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('選圖失敗：$e')));
    }
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('至少要填歌名')));
      return;
    }

    final raw = _level.text.trim();
    final song = Song(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      artist: _artist.text.trim().isEmpty ? null : _artist.text.trim(),
      localCover: _localCover,
      diff: _diff,
      level: levelDisplay(raw),
      internal: double.tryParse(raw),
      version: _version.text.trim(),
      type: _type,
    );
    Navigator.pop(context, song);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('手動新增',
            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 19)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 78,
                    height: 78,
                    color: scheme.surfaceContainerHighest,
                    child: _localCover == null
                        ? Icon(Icons.add_photo_alternate_outlined,
                            color: scheme.onSurfaceVariant)
                        : Image.file(File(_localCover!), fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _localCover == null ? '點一下挑曲繪' : '再點一下可以換',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _field(_title, '歌名'),
          const SizedBox(height: 14),
          _field(_artist, '曲師（可留空）'),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: _diff,
            decoration: const InputDecoration(
              labelText: '難度',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var i = 0; i < kDifficulties.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: kDifficulties[i].color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(kDifficulties[i].full,
                          style:
                              const TextStyle(fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _diff = v ?? 3),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(
              labelText: '譜面種類',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                  value: 'dx',
                  child: Text('DX',
                      style: TextStyle(fontWeight: FontWeight.w400))),
              DropdownMenuItem(
                  value: 'std',
                  child: Text('STD',
                      style: TextStyle(fontWeight: FontWeight.w400))),
              DropdownMenuItem(
                  value: 'utage',
                  child: Text('宴会場',
                      style: TextStyle(fontWeight: FontWeight.w400))),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'dx'),
          ),
          const SizedBox(height: 14),
          _field(
            _level,
            '定數（例如 14.7）',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 14),
          _field(_version, '版本（可留空，例如 CiRCLE+）'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submit,
        icon: const Icon(Icons.check),
        label: const Text('加入清單',
            style: TextStyle(fontWeight: FontWeight.w400)),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: const TextStyle(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
