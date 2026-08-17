import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:yomu/features/reels/domain/reel.dart';
import 'package:yomu/features/reels/presentation/widgets/reel_sentence_list.dart';

Future<Reel> _loadReel(String file) async {
  final raw = jsonDecode(await rootBundle.loadString('assets/reels/$file'));
  return Reel.fromJson(raw as Map<String, dynamic>);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> diagnose(String label, String file) async {
    testWidgets('bounce diagnostic: $label', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      final reel = await _loadReel(file);
      final positionMs = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReelSentenceList(
              reel: reel,
              positionMs: positionMs,
              showFurigana: false,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(Scrollable).first;
      double offset() => tester.state<ScrollableState>(scrollableFinder).position.pixels;

      var reversals = 0;
      final reversalDetails = <String>[];
      // Walk through the first ~40 sentences (or however many exist).
      final sentencesToCheck = reel.sentences.length < 40 ? reel.sentences.length : 40;
      for (var i = 0; i < sentencesToCheck; i++) {
        final sentence = reel.sentences[i];
        positionMs.value = sentence.startMs;

        var prevOffset = offset();
        var direction = 0; // -1, 0, +1 — the very first observed movement direction of this transition
        // Sample frequently across both the 300ms ensureVisible animation
        // and the 200ms AnimatedContainer/AnimatedOpacity highlight fade.
        for (var t = 0; t < 40; t++) {
          await tester.pump(const Duration(milliseconds: 16));
          final o = offset();
          final delta = o - prevOffset;
          if (delta.abs() > 0.05) {
            final d = delta > 0 ? 1 : -1;
            if (direction == 0) {
              direction = d;
            } else if (d != direction) {
              reversals++;
              reversalDetails.add(
                'sentence $i, tick $t: offset $prevOffset -> $o (direction flip)',
              );
            }
          }
          prevOffset = o;
        }
      }

      // ignore: avoid_print
      print(
        '[$label] reversals detected: $reversals'
        '${reversalDetails.isEmpty ? '' : '\n  ' + reversalDetails.take(10).join('\n  ')}',
      );
      expect(reversals, 0, reason: 'Scroll offset reversed direction mid-transition (a visible bounce)');
    });
  }

  diagnose('reel 01 kasa', 'n5/n5-reel-01-kasa-wo-wasuremashita.json');
  diagnose('reel 02 mini-drama', 'n5/n5-reel-02-mini-drama-part1.json');
  diagnose('reel 03 eigakan-de', 'n5/n5-reel-03-eigakan-de.json');
}
