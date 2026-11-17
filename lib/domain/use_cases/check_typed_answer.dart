import 'package:ippo/domain/models/item.dart';

/// Checks a typed romaji answer against a kana.
class CheckTypedAnswer {
  const CheckTypedAnswer();

  /// Ignores letter case and surrounding whitespace, and accepts the
  /// kana's alternative romanisations.
  bool call(KanaPayload kana, String input) {
    final answer = input.trim().toLowerCase();
    if (answer.isEmpty) return false;
    return kana.acceptedRomaji.any((romaji) => romaji.toLowerCase() == answer);
  }
}
