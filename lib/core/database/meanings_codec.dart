/// [DictionaryEntry.meanings] is stored as a JSON-encoded list of strings;
/// this avoids a dart:convert round-trip for the common "just show them"
/// display case.
String decodeMeanings(String meaningsJson) {
  final matches = RegExp(r'"([^"]+)"').allMatches(meaningsJson);
  return matches.map((m) => m.group(1)).join(', ');
}
