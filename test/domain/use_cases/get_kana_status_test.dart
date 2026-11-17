import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/use_cases/get_kana_status.dart';

import '../../support/builders.dart';

void main() {
  const getKanaStatus = GetKanaStatus();
  final introduced = kanaItem(id: 1, introducedAt: DateTime(2026));

  test('a kana not yet introduced is not started', () {
    expect(getKanaStatus(kanaItem(id: 1), const []), KanaStatus.notStarted);
  });

  test('an introduced kana with young cards is learning', () {
    final cards = [
      reviewCard(id: 1, itemId: 1),
      reviewCard(id: 2, itemId: 1, phase: CardPhase.review, stability: 30),
    ];

    expect(getKanaStatus(introduced, cards), KanaStatus.learning);
  });

  test('a kana is known when every card is in review and stable', () {
    final cards = [
      reviewCard(id: 1, itemId: 1, phase: CardPhase.review, stability: 21),
      reviewCard(id: 2, itemId: 1, phase: CardPhase.review, stability: 40),
    ];

    expect(getKanaStatus(introduced, cards), KanaStatus.known);
  });

  test('a card below 21 days of stability keeps the kana in learning', () {
    final cards = [
      reviewCard(id: 1, itemId: 1, phase: CardPhase.review, stability: 20.9),
    ];

    expect(getKanaStatus(introduced, cards), KanaStatus.learning);
  });
}
