// IMPORTANT: RUN THIS AFTER MODIFIYING THIS DB EVERYTIME:
// dart run build_runner build --delete-conflicting-outputs

// ADDITIONALLY, you must place all important code within the lib folder for the above build command to work correctly
// YOU MUST ALSO CREATE PUBSPEC.YAML and fill it with all the dependencies

// imports
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';

// generated 'sql' database
part 'database.g.dart'; 

// Songs table
class Songs extends Table {
  // a Songs table extending Music db
  IntColumn get id => integer().autoIncrement()();  // PK
  TextColumn get path => text().unique()();
  TextColumn get filename => text().nullable()();
  TextColumn get title => text().withDefault(const Constant('Unknown Title'))();
  IntColumn get artistId => integer().nullable().withDefault(const Constant(1))
                            .references(Artists, #id, onDelete: KeyAction.setNull)();
  IntColumn get coverId => integer().nullable().withDefault(const Constant(1))
                            .references(Covers, #id, onDelete: KeyAction.setNull)();
  IntColumn get genreId => integer().nullable().withDefault(const Constant(1))
                            .references(Genres, #id, onDelete: KeyAction.setNull)();
  IntColumn get albumId => integer().nullable().withDefault(const Constant(1))
                            .references(Albums, #id, onDelete: KeyAction.setNull)();
  IntColumn get durationMS => integer().withDefault(const Constant(0))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

// create the Playlists table (holds playlists)
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()(); // PK
  TextColumn get title => text()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))(); 
  DateTimeColumn get creationDate => dateTime().withDefault(currentDateAndTime)();
}

// playlist songs relation
class PlaylistSongs extends Table {
  // Link to the Playlist
  IntColumn get playlistId => integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  // Link to the Song
  IntColumn get songId => integer().references(Songs, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  // Make the combination unique
  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

// coverPath Table
class Covers extends Table {
  // id
  IntColumn get id => integer().autoIncrement()();
  // path ot cover art
  TextColumn get value => text().unique().withDefault(const Constant('branding/color-darkbg.png'))();
}

// Artists Table
class Artists extends Table {
  // id
  IntColumn get id => integer().autoIncrement()();
  // default artist
  TextColumn get value => text().unique().withDefault(const Constant('Unknown Artist'))();
}

// Genres Table
class Genres extends Table {
  // id
  IntColumn get id => integer().autoIncrement()();
  // default genre
  TextColumn get value => text().unique().withDefault(const Constant('Misc'))();
}

// Albums Table
class Albums extends Table {
  // id
  IntColumn get id => integer().autoIncrement()();
  // default albums
  TextColumn get value => text().withDefault(const Constant('Unknown Album'))();
}

// Define the Music db. Constructor opens database upon Music object initialization.
@DriftDatabase(tables: [Songs, Playlists, PlaylistSongs, Covers, Artists, Genres, Albums])
class Music extends _$Music {
  Music() : super(_openConnection());

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      // Turn on Foreign Key constraints (important for SQLite!)
      await customStatement('PRAGMA foreign_keys = ON');

      // SEED THE 'UNKNOWN'
      // use OR IGNORE so it only runs the very first time the app is opened
        await customStatement('INSERT OR IGNORE INTO covers (id, value) VALUES (1, \'branding/color-darkbg.png\')');
        await customStatement('INSERT OR IGNORE INTO artists (id, value) VALUES (1, \'Unknown Artist\')');
        await customStatement('INSERT OR IGNORE INTO genres (id, value) VALUES (1, \'Misc\')');
        await customStatement('INSERT OR IGNORE INTO albums (id, value) VALUES (1, \'Unknown Album\')');
    },
  );
}

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // This creates a local file in your project folder
    final file = File('db.sqlite4'); 
    return NativeDatabase(file);
  });
}