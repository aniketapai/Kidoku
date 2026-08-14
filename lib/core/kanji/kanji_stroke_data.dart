import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_drawing/path_drawing.dart';

// Hand-written (not @riverpod codegen) — see dictionary_search_provider.dart
// for why.

/// Raw kanji -> ordered list of stroke `d` path strings, decoded once from
/// assets/kanji_strokes/kanji_strokes.json (built by
/// tool/fetch_kanji_strokes.py from KanjiVG, CC BY-SA 3.0). Kept as raw
/// strings rather than parsed [Path]s here since most of the ~1,300 bundled
/// characters are never opened in a given session.
final kanjiStrokeDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final raw = await rootBundle.loadString('assets/kanji_strokes/kanji_strokes.json');
  return jsonDecode(raw) as Map<String, dynamic>;
});

/// The stroke [Path]s for [kanji] in drawing order, parsed on demand from
/// [data] — or null if this character isn't in the bundled KanjiVG dataset.
List<Path>? strokePathsFor(Map<String, dynamic> data, String kanji) {
  final strokes = data[kanji] as List<dynamic>?;
  if (strokes == null) return null;
  return [for (final d in strokes) parseSvgPathData(d as String)];
}
