import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// App 私有持久目錄：不依賴 HTTP Cache-Control，退出後仍可離線讀取。
class CoverCache {
  static final Map<String, File> memory = {};
  static final Map<String, Future<File>> _pending = {};
  static Future<Directory>? _directory;
  static Future<Directory> get directory => _directory ??= _makeDirectory();
  static Future<Directory> _makeDirectory() async {
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}/covers-v1').create(recursive: true);
  }

  static Future<File> get(String url) {
    final hit = memory[url];
    if (hit != null) return Future.value(hit);
    return _pending.putIfAbsent(url, () => _fetch(url).whenComplete(() {
      _pending.remove(url);
    }));
  }

  static Future<File> _fetch(String url) async {
    final root = await directory;
    final file = File('${root.path}/${sha256.convert(utf8.encode(url))}.img');
    if (await file.exists() && await file.length() > 0) {
      memory[url] = file;
      return file;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    final temp = File('${file.path}.part');
    try {
      await (() async {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode != 200) throw HttpException('封面 HTTP ${response.statusCode}');
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 10 * 1024 * 1024) throw const HttpException('圖片太大');
        }
        final jpeg = bytes.length > 2 && bytes[0] == 255 && bytes[1] == 216;
        final png = bytes.length > 4 && bytes[0] == 137 && bytes[1] == 80;
        if (!jpeg && !png) throw const HttpException('封面不是有效圖片');
        await temp.writeAsBytes(bytes, flush: true);
        await temp.rename(file.path);
      })().timeout(const Duration(seconds: 25));
      memory[url] = file;
      return file;
    } finally {
      client.close(force: true);
    }
  }
}
