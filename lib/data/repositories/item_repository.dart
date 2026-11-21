import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/seed_item.dart';

/// Access to the things that can be learned.
abstract interface class ItemRepository {
  /// All items in teaching order, updated whenever any item changes.
  Stream<List<Item>> getItemsStream();

  /// All items in teaching order.
  Future<List<Item>> getItems();

  Future<Item?> getItem(int id);

  /// Brings the stored items in line with [seedItems], which is content
  /// that ships with the app.
  ///
  /// Adds items whose key is missing. For items already stored, updates
  /// the payload, teaching order and default mnemonic when they differ.
  /// Never changes learner data (introduced dates, own mnemonics, cards)
  /// and never removes an item.
  Future<void> syncSeedItems(List<SeedItem> seedItems);

  /// Marks items as introduced by a lesson at [at].
  Future<void> markIntroduced(List<int> itemIds, DateTime at);
}
