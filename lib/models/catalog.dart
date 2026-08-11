import 'dart:convert';

import 'package:flutter/services.dart';

/// 曲庫裡一張譜面。
class Sheet {
  /// dx / std / utage / utage2p
  final String type;

  /// 0=BASIC ... 4=Re:MASTER, 5=宴會場
  final int diff;

  /// 宴會場的標記，例如「【協】」
  final String? utageKey;

  /// 官方等級字串，例如 "13+"
  final String level;

  /// 定數，例如 13.7。宴會場或未知時為 null。
  final double? internal;

  /// 正式版本名，例如 "CiRCLE PLUS"
  final String version;

  /// 實裝狀態 bitmask：1=日服 4=海外版。
  ///
  /// 刻意不記錄國服狀態，因為 dxdata 的 cn 欄位不可靠（ツユ 全曲國服
  /// 已隨日服移除卻仍標 true、宴會場全標 false 但國服打得到）。
  /// 國服沒有獨佔曲，日服刪掉的國服必然也沒有，所以看 jp 就夠。
  final int regions;

  const Sheet({
    required this.type,
    required this.diff,
    this.utageKey,
    required this.level,
    this.internal,
    required this.version,
    this.regions = 5,
  });

  bool get inJp => regions & 1 != 0;
  bool get inIntl => regions & 4 != 0;

  /// 日服沒有 = 已刪除（國服跟著日服，不會留著）。
  /// 海外版限定的少數例外不算刪除。
  bool get isRemoved => !inJp && !inIntl;

  /// 給選譜面畫面用的狀態標記。正常時回傳空字串。
  ///
  /// 「日服限定」通常是還沒輪到海外 / 國服的新曲，國服大概打不到，
  /// 但這是推論不是實據，所以照 dxdata 的原始事實寫，不代替你下結論。
  String get statusLabel {
    if (isRemoved) return '已刪除';
    if (!inJp && inIntl) return '海外版限定';
    if (inJp && !inIntl) return '日服限定';
    return '';
  }

  bool get isUtage => type == 'utage' || type == 'utage2p';

  String get typeLabel {
    switch (type) {
      case 'dx':
        return 'DX';
      case 'std':
        return 'STD';
      case 'utage2p':
        return '宴2P';
      default:
        return '宴';
    }
  }

  factory Sheet.fromJson(Map<String, dynamic> j) => Sheet(
        type: (j['t'] ?? 'std') as String,
        diff: (j['d'] ?? 0) as int,
        utageKey: j['k'] as String?,
        level: (j['l'] ?? '') as String,
        internal: (j['v'] as num?)?.toDouble(),
        version: (j['r'] ?? '') as String,
        // 精簡檔在日服 + 海外版都有時省略 g，預設補回 5。
        regions: (j['g'] ?? 5) as int,
      );
}

/// 曲庫裡一首曲子。
class CatalogSong {
  final String title;
  final String artist;

  /// 曲繪檔名（不含副檔名）
  final String imageName;

  /// 分類，例如「オンゲキ＆CHUNITHM」
  final String category;

  /// 搜尋用縮寫，例如 ["yzkc"]
  final List<String> acronyms;

  /// 初出版本（所有譜面裡最早的那個）
  final String debutVersion;

  final List<Sheet> sheets;

  /// 搜尋用的正規化字串，建構時就算好。
  final String normTitle;
  final String normArtist;

  CatalogSong({
    required this.title,
    required this.artist,
    required this.imageName,
    required this.category,
    required this.acronyms,
    required this.debutVersion,
    required this.sheets,
  })  : normTitle = Catalog.norm(title),
        normArtist = Catalog.norm(artist);

  /// 所有譜面都被刪掉了。
  bool get isRemoved =>
      sheets.isNotEmpty && sheets.every((s) => s.isRemoved);

  static const String coverBase =
      'https://shama.dxrating.net/images/cover/v2';

  String? get coverUrl =>
      imageName.isEmpty ? null : '$coverBase/$imageName.jpg';

  factory CatalogSong.fromJson(Map<String, dynamic> j) => CatalogSong(
        title: (j['n'] ?? '') as String,
        artist: (j['a'] ?? '') as String,
        imageName: (j['i'] ?? '') as String,
        category: (j['c'] ?? '') as String,
        acronyms:
            ((j['y'] as List?) ?? const []).map((e) => e as String).toList(),
        debutVersion: (j['v0'] ?? '') as String,
        sheets: ((j['s'] as List?) ?? const [])
            .map((e) => Sheet.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 內建曲庫（資料來自 dxrating 的 dxdata），離線可用。
class Catalog {
  static const _asset = 'assets/dxdata_slim.json';

  static List<CatalogSong>? _songs;
  static String _updateDate = '';

  static String get updateDate => _updateDate;

  static Future<List<CatalogSong>> songs() async {
    final cached = _songs;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_asset);
    final root = jsonDecode(raw) as Map<String, dynamic>;
    _updateDate = (root['u'] ?? '') as String;
    final list = ((root['songs'] as List?) ?? const [])
        .map((e) => CatalogSong.fromJson(e as Map<String, dynamic>))
        .toList();
    _songs = list;
    return list;
  }

  /// 要在搜尋時忽略的符號。
  static const String _ignore =
      ' \t\n-_.,!?/\\:;~*+#&\'"()[]{}！？、。：；～（）【】「」『』…·';

  /// 統一大小寫、去掉標點，讓「D.」「d」都能搜到。
  static String norm(String s) {
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      if (!_ignore.contains(ch)) b.write(ch);
    }
    return b.toString();
  }

  /// 搜曲名、曲師、縮寫。回傳按相似度排序的結果。
  static Future<List<CatalogSong>> search(String query,
      {int limit = 60}) async {
    final all = await songs();
    final q = norm(query);
    if (q.isEmpty) return const [];

    final exact = <CatalogSong>[];
    final prefix = <CatalogSong>[];
    final contains = <CatalogSong>[];
    final byArtist = <CatalogSong>[];
    final byAcronym = <CatalogSong>[];

    for (final s in all) {
      final t = s.normTitle;
      if (t == q) {
        exact.add(s);
      } else if (t.startsWith(q)) {
        prefix.add(s);
      } else if (t.contains(q)) {
        contains.add(s);
      } else if (s.acronyms.any((a) => a.toLowerCase().startsWith(q))) {
        byAcronym.add(s);
      } else if (s.normArtist.contains(q)) {
        byArtist.add(s);
      }
    }

    return [...exact, ...prefix, ...contains, ...byAcronym, ...byArtist]
        .take(limit)
        .toList();
  }
}
