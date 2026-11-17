import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/seed_item.dart';

/// Access to the things that can be learned.
abstract interface class ItemRepository {
  /// All items in teaching order, updated whenever any item changes.
  Stream<List<Item>> getItemsStream();

  /// All items in teaching order.
  Future<List<Item>> getItems();

  Future<Item?> getItem(int id);

  /// Inserts seed items and their default mnemonics. Items whose key
  /// already exists are left untouched, so this is safe to repeat.
  Future<void> insertSeedItems(List<SeedItem> seedItems);

  /// Marks items as introduced by a lesson at [at].
  Future<void> markIntroduced(List<int> itemIds, DateTime at);
}
