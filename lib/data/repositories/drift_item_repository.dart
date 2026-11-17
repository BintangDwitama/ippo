import 'package:drift/drift.dart';
import 'package:ippo/data/repositories/item_payload_mapper.dart';
import 'package:ippo/data/repositories/item_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/seed_item.dart';

class DriftItemRepository implements ItemRepository {
  DriftItemRepository(this._db, {ItemPayloadMapper? payloadMapper})
      : _payloadMapper = payloadMapper ?? const ItemPayloadMapper();

  final AppDatabase _db;
  final ItemPayloadMapper _payloadMapper;

  SimpleSelectStatement<$ItemsTable, ItemRow> get _orderedItems =>
      _db.select(_db.items)
        ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);

  @override
  Stream<List<Item>> getItemsStream() {
    return _orderedItems.watch().map((rows) => rows.map(_toItem).toList());
  }

  @override
  Future<List<Item>> getItems() async {
    final rows = await _orderedItems.get();
    return rows.map(_toItem).toList();
  }

  @override
  Future<Item?> getItem(int id) async {
    final row = await (_db.select(_db.items)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toItem(row);
  }

  @override
  Future<void> insertSeedItems(List<SeedItem> seedItems) {
    return _db.transaction(() async {
      for (final seed in seedItems) {
        final existing = await (_db.select(_db.items)
              ..where((t) => t.itemKey.equals(seed.key)))
            .getSingleOrNull();
        if (existing != null) continue;

        final id = await _db.into(_db.items).insert(
              ItemsCompanion.insert(
                kind: seed.kind,
                itemKey: seed.key,
                payload: _payloadMapper.encode(seed.payload),
                sortOrder: seed.sortOrder,
              ),
            );
        await _db.into(_db.mnemonics).insert(
              MnemonicsCompanion.insert(
                itemId: Value(id),
                defaultText: seed.defaultMnemonic,
              ),
            );
      }
    });
  }

  @override
  Future<void> markIntroduced(List<int> itemIds, DateTime at) {
    return (_db.update(_db.items)..where((t) => t.id.isIn(itemIds)))
        .write(ItemsCompanion(introducedAt: Value(at)));
  }

  Item _toItem(ItemRow row) {
    return Item(
      id: row.id,
      kind: row.kind,
      key: row.itemKey,
      sortOrder: row.sortOrder,
      payload: _payloadMapper.decode(row.kind, row.payload),
      introducedAt: row.introducedAt,
    );
  }
}
