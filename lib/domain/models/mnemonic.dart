import 'package:meta/meta.dart';

/// The memory aid for an item: a seeded default the learner can replace.
@immutable
class Mnemonic {
  const Mnemonic({
    required this.itemId,
    required this.defaultText,
    this.learnerText,
  });

  final int itemId;
  final String defaultText;
  final String? learnerText;

  bool get isEdited => learnerText != null;

  /// The text to show: the learner's own if they wrote one.
  String get text => learnerText ?? defaultText;
}
