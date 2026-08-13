const _digraphs = {
  'kya': 'きゃ', 'kyu': 'きゅ', 'kyo': 'きょ',
  'gya': 'ぎゃ', 'gyu': 'ぎゅ', 'gyo': 'ぎょ',
  'sha': 'しゃ', 'shu': 'しゅ', 'sho': 'しょ',
  'sya': 'しゃ', 'syu': 'しゅ', 'syo': 'しょ',
  'ja': 'じゃ', 'ju': 'じゅ', 'jo': 'じょ',
  'zya': 'じゃ', 'zyu': 'じゅ', 'zyo': 'じょ',
  'cha': 'ちゃ', 'chu': 'ちゅ', 'cho': 'ちょ',
  'tya': 'ちゃ', 'tyu': 'ちゅ', 'tyo': 'ちょ',
  'dya': 'ぢゃ', 'dyu': 'ぢゅ', 'dyo': 'ぢょ',
  'nya': 'にゃ', 'nyu': 'にゅ', 'nyo': 'にょ',
  'hya': 'ひゃ', 'hyu': 'ひゅ', 'hyo': 'ひょ',
  'bya': 'びゃ', 'byu': 'びゅ', 'byo': 'びょ',
  'pya': 'ぴゃ', 'pyu': 'ぴゅ', 'pyo': 'ぴょ',
  'mya': 'みゃ', 'myu': 'みゅ', 'myo': 'みょ',
  'rya': 'りゃ', 'ryu': 'りゅ', 'ryo': 'りょ',
};

const _monographs = {
  'a': 'あ', 'i': 'い', 'u': 'う', 'e': 'え', 'o': 'お',
  'ka': 'か', 'ki': 'き', 'ku': 'く', 'ke': 'け', 'ko': 'こ',
  'ga': 'が', 'gi': 'ぎ', 'gu': 'ぐ', 'ge': 'げ', 'go': 'ご',
  'sa': 'さ', 'shi': 'し', 'si': 'し', 'su': 'す', 'se': 'せ', 'so': 'そ',
  'za': 'ざ', 'ji': 'じ', 'zi': 'じ', 'zu': 'ず', 'ze': 'ぜ', 'zo': 'ぞ',
  'ta': 'た', 'chi': 'ち', 'ti': 'ち', 'tsu': 'つ', 'tu': 'つ', 'te': 'て', 'to': 'と',
  'da': 'だ', 'di': 'ぢ', 'du': 'づ', 'de': 'で', 'do': 'ど',
  'na': 'な', 'ni': 'に', 'nu': 'ぬ', 'ne': 'ね', 'no': 'の',
  'ha': 'は', 'hi': 'ひ', 'fu': 'ふ', 'hu': 'ふ', 'he': 'へ', 'ho': 'ほ',
  'ba': 'ば', 'bi': 'び', 'bu': 'ぶ', 'be': 'べ', 'bo': 'ぼ',
  'pa': 'ぱ', 'pi': 'ぴ', 'pu': 'ぷ', 'pe': 'ぺ', 'po': 'ぽ',
  'ma': 'ま', 'mi': 'み', 'mu': 'む', 'me': 'め', 'mo': 'も',
  'ya': 'や', 'yu': 'ゆ', 'yo': 'よ',
  'ra': 'ら', 'ri': 'り', 'ru': 'る', 're': 'れ', 'ro': 'ろ',
  'wa': 'わ', 'wo': 'を', 'wi': 'うぃ', 'we': 'うぇ',
};

final _romajiPattern = RegExp(r"^[a-z']+$");

/// Converts romaji (Hepburn-ish input) to hiragana, e.g. "taberu" -> "たべる",
/// "gakkou" -> "がっこう". Returns null if [input] isn't plausibly romaji or
/// contains a syllable this converter doesn't recognize — callers should
/// fall back to treating the query as-is (e.g. an English search term).
String? romajiToHiragana(String input) {
  final s = input.toLowerCase();
  if (s.isEmpty || !_romajiPattern.hasMatch(s)) return null;

  final buffer = StringBuffer();
  var i = 0;
  while (i < s.length) {
    if (s[i] == 'n' && i + 1 < s.length && s[i + 1] == "'") {
      buffer.write('ん');
      i += 2;
      continue;
    }
    if (s[i] == "'") {
      i++;
      continue;
    }
    if (i + 1 < s.length && s[i] == s[i + 1] && !'aeiounwy'.contains(s[i])) {
      buffer.write('っ');
      i++;
      continue;
    }
    if (s[i] == 'n' && (i + 1 >= s.length || !'aeiouy'.contains(s[i + 1]))) {
      buffer.write('ん');
      i++;
      continue;
    }

    var matched = false;
    for (final len in [3, 2, 1]) {
      if (i + len > s.length) continue;
      final chunk = s.substring(i, i + len);
      final kana = _digraphs[chunk] ?? _monographs[chunk];
      if (kana != null) {
        buffer.write(kana);
        i += len;
        matched = true;
        break;
      }
    }
    if (!matched) return null;
  }
  return buffer.toString();
}
