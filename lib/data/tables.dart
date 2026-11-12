import 'package:drift/drift.dart';

@TableIndex(name: 'idx_items_warranty_end', columns: {#warrantyEndDate})
class Items extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get category => text()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get price => real().nullable()();
  TextColumn get currency => text()();
  TextColumn get storeName => text().nullable()();
  IntColumn get warrantyMonths => integer()();
  DateTimeColumn get warrantyEndDate => dateTime()();
  DateTimeColumn get extendedWarrantyEndDate => dateTime().nullable()();
  BoolColumn get isLifetime => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_attachments_item', columns: {#itemId})
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get localPath => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_reminders_item', columns: {#itemId})
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get fireAt => dateTime()();
  TextColumn get kind => text()();
  IntColumn get notificationId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
