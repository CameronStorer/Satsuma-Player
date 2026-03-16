// this class's only purpose is to talk to the DB
// handles all function calls into the database called QUERIES

// IMPORTS
import 'package:satsuma_player/database/database.dart';
import 'package:path/path.dart' as path;
import 'package:drift/drift.dart';

// initialize the Music Database
final db = Music();

///////////// USING GENERICS FOR COMMON FUNCTIONS ///////////////////////
// CREATE
Future<int> insert<T extends Table, D, C extends UpdateCompanion<D>>(TableInfo<T,D> table, C companion){
  return db.into(table).insert(companion, mode: InsertMode.insertOrReplace);
}
/// READ BY ID
// T is the Table (e.g., Songs); D is the Data Class (e.g., Song)
Future<D?> getById<T extends Table, D>(TableInfo<T, D> table, int id) {
  // We cast to dynamic so we can access the .id column generically
  return (db.select(table)..where(
    (tbl) => (tbl as dynamic).id.equals(id))).getSingleOrNull();
}
// UPDATE
// D is the Data Class (Song), C is the Companion (SongsCompanion)
Future<bool> update<T extends Table, D, C extends UpdateCompanion<D>>(TableInfo<T, D> table, C companion,) {
  return db.update(table).replace(companion);
}
// DELETE BY ID
Future<int> deleteById<T extends Table, D>(TableInfo<T, D> table, int id) {
  // cast to dynamic so .id column can be accessed generically
  return (db.delete(table)..where((tbl) => (tbl as dynamic).id.equals(id))).go();
}
// COUNT ALL SONGS
Future<int> count<T extends Table, D>(TableInfo<T, D> table){
  return table.count().getSingle();
}
// READ BY TITLE
Future<D?> getByTitle<T extends Table, D>(TableInfo<T, D> table, String title) {
  // We cast to dynamic so we can access the .id column generically
  return (db.select(table)..where(
    (tbl) => (tbl as dynamic).title.equals(title))).getSingleOrNull();
}


////////////////// SONGS SPECIFIC QUERIES //////////////////////////////////
// ADD SONG FROM FILE PATH
Future<void> addSongFromFile(String filePath) async {
  final song = SongsCompanion.insert(path: filePath, filename: Value(path.basename(filePath)));
  await insert(db.songs, song);
}
// IS SONG PRESENT
Future<bool> songExists(String path) async {
  final query = db.select(db.songs)..where((tbl) => tbl.path.equals(path));
  return (await query.get()).isNotEmpty;
}

// Use a Stream for the UI so the music list is always "Live"
Stream<List<Song>> watchAllSongs() => db.select(db.songs).watch();
// KEEP A ONE-TIME 'GET' FOR BACKGROUND LOGIC/PROCESSING
Future<List<Song>> getAllSongs() => db.select(db.songs).get();

// LOGIC FOR PERFORMING A FULL RESCAN
Future<void> rescanLibrary(List<SongsCompanion> newSongs) async {
  await db.batch((batch) {
    // 1. Delete everything
    batch.deleteAll(db.songs);
    // 2. Insert the new batch
    batch.insertAll(db.songs, newSongs);
  });
}

// SORT THE SONGS TABLE BY ATTRIBUTE (GENERIC SORTING FUNCTION)
Future<List<Song>> sortSongs(Expression<Object> Function(Songs) sorter, {bool descending = false}) {
  return (db.select(db.songs)..orderBy([(t) => descending ? OrderingTerm.desc(sorter(t)) : OrderingTerm.asc(sorter(t))])).get();
}

// MARK FAVORITE - inputs = id and value
Future toggleFavorite(int id, bool value) => (db.update(db.songs)..where((s) => s.id.equals(id))).write(SongsCompanion(favorite: Value(value)));

// GET ALL FAVORITE SONGS
Future<List<Song>> getFavoriteSongs() {
  return (db.select(db.songs)..where((tbl) => tbl.favorite.equals(true))).get();
}

////////////////// SONG PLAYLISTS QUERIES //////////////////////////////////
////////////////// SONG PLAYLISTSONGS QUERIES //////////////////////////////////
////////////////// SONG ARTISTS QUERIES //////////////////////////////////
////////////////// SONG GENRES QUERIES //////////////////////////////////
////////////////// SONG ALBUMS QUERIES //////////////////////////////////


