import 'package:ippo/domain/models/item.dart';
import 'package:meta/meta.dart';

/// An item as it arrives from bundled seed content, before it has an id.
@immutable
class SeedItem {
  const SeedItem({
    required this.kind,
    required this.key,
    required this.sortOrder,
    required this.payload,
    this.defaultMnemonic,
  });

  final ItemKind kind;
  final String key;
  final int sortOrder;
  final ItemPayload payload;

  /// Null for kinds that have no mnemonic, such as words.
  final String? defaultMnemonic;
}
