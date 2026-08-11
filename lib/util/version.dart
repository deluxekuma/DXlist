/// 把 dxdata 的版本名轉成玩家常用的簡寫。
///
///   maimaiでらっくす        -> でらっくす
///   maimaiでらっくす PLUS   -> でらっくす+
///   UNiVERSE PLUS          -> UNiVERSE+
///   CiRCLE PLUS            -> CiRCLE+
String versionShort(String raw) {
  var v = raw.trim();
  if (v.isEmpty) return '';

  final plus = v.endsWith(' PLUS');
  if (plus) v = v.substring(0, v.length - 5).trim();

  // 初代 DX 在 dxdata 裡寫成日文原名。
  if (v == 'maimaiでらっくす' || v == 'maimai DX' || v == '舞萌DX') {
    v = 'でらっくす';
  }

  return plus ? '$v+' : v;
}
