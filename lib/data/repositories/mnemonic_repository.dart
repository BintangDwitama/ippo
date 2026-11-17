import 'package:ippo/domain/models/mnemonic.dart';

/// Access to mnemonics, including the learner's own versions.
abstract interface class MnemonicRepository {
  Stream<Mnemonic> getMnemonicStream(int itemId);

  Future<Mnemonic> getMnemonic(int itemId);

  /// Replaces the mnemonic shown for [itemId] with the learner's [text].
  ///
  /// Throws [ArgumentError] if [text] is empty or only whitespace.
  Future<void> saveLearnerText(int itemId, String text);

  /// Removes the learner's text so the default is shown again.
  Future<void> restoreDefault(int itemId);
}
