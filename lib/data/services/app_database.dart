import 'package:drift/drift.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

part 'app_database.g.dart';

@DataClassName('ItemRow')
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<ItemKind>()();
  TextColumn get itemKey => text().unique()();

  /// Kind-specific content as JSON.
  TextColumn get payload => text()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get introducedAt => dateTime().nullable()();
}

@DataClassName('MnemonicRow')
class Mnemonics extends Table {
  IntColumn get itemId => integer().references(Items, #id)();
  TextColumn get defaultText => text()();
  TextColumn get learnerText => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};
}

@DataClassName('CardRow')
class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id)();
  TextColumn get promptType => textEnum<PromptType>()();
  TextColumn get phase => textEnum<CardPhase>()();
  IntColumn get step => integer().nullable()();
  DateTimeColumn get due => dateTime()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  DateTimeColumn get lastReview => dateTime().nullable()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveCorrect =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {itemId, promptType},
      ];
}

@DataClassName('ReviewRecordRow')
class ReviewRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(Cards, #id)();
  DateTimeColumn get reviewedAt => dateTime()();
  TextColumn get rating => textEnum<Rating>()();
  BoolColumn get wasCorrect => boolean()();
  TextColumn get phaseBefore => textEnum<CardPhase>()();
  IntColumn get elapsedDays => integer()();
}

@DataClassName('GoalRow')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetSet => textEnum<GoalTargetSet>()();
  RealColumn get targetAccuracy => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deadline => dateTime()();
  TextColumn get status => textEnum<GoalStatus>()();
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get name => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {name};
}

/// The app's local SQLite database. Only repositories may use it.
@DriftDatabase(
  tables: [Items, Mnemonics, Cards, ReviewRecords, Goals, Settings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
