import 'catalog.dart';

/// 清單中的一首歌（一首歌 = 一張特定譜面）。
class Song {
  String id;
  String title;
  String? artist;

  /// dxrating 的曲繪檔名，從曲庫加進來時有值。
  String? imageName;

  /// 原曲 BPM。
  double? bpm;

  /// 譜面物件統計。
  Map<String, int> notes;

  /// 使用者自己從相冊挑的曲繪，優先於網路曲繪。
  String? localCover;

  /// 0=BASIC ... 4=Re:MASTER, 5=宴會場
  int diff;

  /// 宴會場標記，例如「【協】」
  String? utageKey;

  /// 官方等級字串，例如 "13+"。手動新增時放使用者輸入的定數。
  String level;

  /// 定數，例如 13.7
  double? internal;

  /// 正式版本名，例如 "CiRCLE PLUS"
  String version;

  /// dx / std / utage / utage2p
  String type;

  Song({
    required this.id,
    required this.title,
    this.artist,
    this.imageName,
    this.localCover,
    this.bpm,
    this.notes = const {},
    this.diff = 3,
    this.utageKey,
    this.level = '',
    this.internal,
    this.version = '',
    this.type = 'dx',
  });

  /// 從曲庫的一張譜面建立清單項目。
  factory Song.fromSheet(CatalogSong song, Sheet sheet) => Song(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: song.title,
        artist: song.artist.isEmpty ? null : song.artist,
        imageName: song.imageName,
        bpm: song.bpm,
        notes: Map<String, int>.from(sheet.notes),
        diff: sheet.diff,
        utageKey: sheet.utageKey,
        level: sheet.level,
        internal: sheet.internal,
        version: sheet.version,
        type: sheet.type,
      );

  String? get coverUrl => (imageName == null || imageName!.isEmpty)
      ? null
      : '${CatalogSong.coverBase}/$imageName.jpg';

  bool get isUtage => type == 'utage' || type == 'utage2p';

  String get typeLabel {
    switch (type) {
      case 'dx':
        return 'DX';
      case 'std':
        return 'STD';
      case 'utage2p':
        return '宴2P';
      case 'utage':
        return '宴';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'imageName': imageName,
        'localCover': localCover,
        'bpm': bpm,
        'notes': notes,
        'diff': diff,
        'utageKey': utageKey,
        'level': level,
        'internal': internal,
        'version': version,
        'type': type,
      };

  factory Song.fromJson(Map<String, dynamic> j) => Song(
        id: (j['id'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        artist: j['artist'] as String?,
        imageName: j['imageName'] as String?,
        localCover: j['localCover'] as String?,
        bpm: (j['bpm'] as num?)?.toDouble(),
        notes: ((j['notes'] as Map?) ?? const {}).map(
          (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        ),
        diff: (j['diff'] ?? 3) as int,
        utageKey: j['utageKey'] as String?,
        level: (j['level'] ?? '') as String,
        internal: (j['internal'] as num?)?.toDouble(),
        version: (j['version'] ?? '') as String,
        type: (j['type'] ?? 'dx') as String,
      );
}
