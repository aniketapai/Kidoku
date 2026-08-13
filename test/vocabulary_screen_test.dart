import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yomu/core/database/app_database.dart';
import 'package:yomu/core/database/tables/deck_cards_table.dart';
import 'package:yomu/features/decks/application/deck_data_providers.dart';
import 'package:yomu/features/vocabulary/presentation/vocabulary_screen.dart';

List<DeckCard> _fixtureCards() {
  final cards = <DeckCard>[];
  var sortOrder = 0;
  for (var week = 1; week <= 5; week++) {
    for (var i = 0; i < 4; i++) {
      cards.add(
        DeckCard(
          id: 'vocab-$week-$i',
          deckId: 'n5-vocab',
          level: 'N5',
          cardType: DeckCardType.vocab,
          category: 'Week $week',
          expression: 'たべる$week$i',
          reading: 'たべる',
          meaning: i == 0 ? 'to eat (special word $week)' : 'word $week-$i',
          sortOrder: sortOrder++,
        ),
      );
    }
  }
  cards.add(
    DeckCard(
      id: 'kanji-1',
      deckId: 'n5-kanji',
      level: 'N5',
      cardType: DeckCardType.kanji,
      category: null,
      expression: '食',
      reading: 'ショク',
      meaning: 'eat',
      sortOrder: sortOrder++,
    ),
  );
  cards.add(
    DeckCard(
      id: 'kanji-2',
      deckId: 'n5-kanji',
      level: 'N5',
      cardType: DeckCardType.kanji,
      category: null,
      expression: '飲',
      reading: 'イン',
      meaning: 'drink',
      sortOrder: sortOrder++,
    ),
  );
  return cards;
}

void main() {
  testWidgets('Vocab tab is first and week groups start collapsed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckCardsProvider.overrideWith((ref) => Stream.value(_fixtureCards())),
        ],
        child: const MaterialApp(home: Scaffold(body: VocabularyScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Tab order: Vocab first, Kanji second.
    final tabFinder = find.byType(Tab);
    expect(tabFinder, findsNWidgets(2));
    final tabs = tester.widgetList<Tab>(tabFinder).toList();
    expect(tabs[0].text, 'Vocab');
    expect(tabs[1].text, 'Kanji');

    // Vocab tab is selected by default, showing week group headers.
    expect(find.text('N5 · Week 1'), findsOneWidget);
    expect(find.text('N5 · Week 5'), findsOneWidget);

    // 2. Groups start collapsed: card counts visible, but no card tiles yet.
    expect(find.text('4'), findsNWidgets(5)); // 5 weeks x "4" cards each
    expect(find.textContaining('to eat (special word'), findsNothing);

    // Tap the first week header to expand it.
    await tester.tap(find.text('N5 · Week 1'));
    await tester.pumpAndSettle();
    expect(find.text('to eat (special word 1)'), findsOneWidget);
    // Other weeks remain collapsed.
    expect(find.text('to eat (special word 2)'), findsNothing);

    // 3. Searching auto-expands every matching group.
    await tester.enterText(find.byType(TextField), 'special word');
    await tester.pumpAndSettle();
    final list = find.byType(ListView).last;
    for (var week = 1; week <= 5; week++) {
      await tester.scrollUntilVisible(
        find.text('to eat (special word $week)'),
        200,
        scrollable: find.descendant(of: list, matching: find.byType(Scrollable)),
      );
      expect(find.text('to eat (special word $week)'), findsOneWidget);
    }
  });

  testWidgets('Kanji tab stays flat, not collapsible', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckCardsProvider.overrideWith((ref) => Stream.value(_fixtureCards())),
        ],
        child: const MaterialApp(home: Scaffold(body: VocabularyScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kanji'));
    await tester.pumpAndSettle();

    // Both kanji cards are visible immediately, no expand/collapse needed.
    expect(find.text('eat'), findsOneWidget);
    expect(find.text('drink'), findsOneWidget);
    // No collapsible chevron on the kanji tab.
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });
}
