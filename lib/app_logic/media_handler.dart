// File to handle the scanning and management of media
// IMPORT APPROPRIATE PACKAGES
import 'dart:io';
////////// FILE SYSTEM IMPORTS
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart'; // for scanning media
import 'package:metadata_god/metadata_god.dart';   // for finding song meta data
import 'package:drift/drift.dart';
////////// DATABASE IMPORTS
import 'package:satsuma_player/database/database.dart';
import 'package:satsuma_player/database/brains.dart';
////////// AUDIO PLAYBACK IMPORT
import 'package:just_audio/just_audio.dart';
import 'package:sqlite3/sqlite3.dart'; // audio handling


////////// AUDIOMANAGER CLASS /////////////////////////////////
class AudioManager {
  // CONSTRUCTOR
  AudioManager(){
    initialize();
    requestStoragePermission();
    refreshLookUpTables();
    scanForMedia();
  }

////////// CLASS/INSTANCE VARIABLES ///////////////////////////
  // class variable holding the currently playing song
  static Song? currentSong;
  static int looping = 0;  // 0 = false, 1 = yes general, 2 = yes single
  static bool shuffle = false; // shuffle attribute
  static final AudioPlayer audioPlayer = AudioPlayer();
  // list holding compatible file extensions
  static const allowedExtensions = ['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.acc', '.vorbis', '.alac'];
  static bool _isManualSelection = false;
  // helpful maps for efficiency
  final Map<String, int> _artistCache = {};
  final Map<String, int> _coverCache = {};
  final Map<String, int> _albumCache = {};
  final Map<String, int> _genreCache = {};
  static Map<int, String> artistLookup = {};
  static Map<int, String> coverLookup = {};

  // ensure that the AudioManager can initialize itself and keep track of music
  void initialize() {
    print("initializing");

    // Logic for autoplaying next song
    audioPlayer.playerStateStream.listen((state) {
      if (!_isManualSelection && state.processingState == ProcessingState.completed) {
        // extra checks to ensure that the song has completed successfully
        if (audioPlayer.position >= (audioPlayer.duration ?? Duration.zero) - Duration(milliseconds: 100)) {
          print("SONG COMPLETED!");
          // Call your 'skip to next' function here
          mediaPlaybackAction("forward");
        }
      }
    });
  }
  
////////// RETRIEVE MUSIC FILE DIRECTORY //////////////////////
  Future<Directory> getMediaDir() async {
    Directory mediaDir;
    if (Platform.isWindows) {
      // Windows: put it in the user's Music folder
      final musicDir = Directory(path.join(Platform.environment['USERPROFILE']!, 'Music', 'Satsuma Player'));
      mediaDir = musicDir;
    } else if (Platform.isAndroid) {
      // Android: public Music folder
      // Note: Starting Android 10+, you may need permissions (MANAGE_EXTERNAL_STORAGE) for true public access
      final externalMusicDir = Directory('/storage/emulated/0/Music/Satsuma Player');
      mediaDir = externalMusicDir;
    } else if (Platform.isIOS) {
      // iOS: app's Documents folder (sandboxed)
      final documentsDir = await getApplicationDocumentsDirectory();
      mediaDir = Directory(path.join(documentsDir.path, 'media'));
    } else if (Platform.isLinux || Platform.isMacOS) {
      // Other desktop OS: use home directory + Music
      final homeDir = Directory(Platform.environment['HOME']!);
      mediaDir = Directory(path.join(homeDir.path, 'Music', 'Satsuma Player'));
    } else {
      // fallback: app documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      mediaDir = Directory(path.join(documentsDir.path, 'media'));
    }

    // ensure the directory exists
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    return mediaDir;
  }
////////// ANDROID PERMISSION REQUEST /////////////////////////
  Future<bool> requestStoragePermission() async {
    // if on android
    if (Platform.isAndroid) {
      // get storage status
      var status = await Permission.storage.status;
      // if not given permission, request it
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      // return permission status
      if (!status.isGranted){ print("Storage permissions denied...");}
      return status.isGranted;
    }
    return false;
  }
////////// SAVE MUSIC COVER ART TO DIR ////////////////////////
  Future<String?> saveToImageCache(Uint8List bytes, String key) async {
    try {
      // 1. Get the application-specific directory (Windows: AppData/Roaming)
      final cacheDir = Directory('assets/covers');

      // 2. Ensure the directory exists
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // 3. Define the file path (using the hash key provided)
      final filePath = path.join("${cacheDir.path}/${key}.jpg");
      final file = File(filePath);

      // 4. Only write if it doesn't exist (Efficiency/Performance)
      if (!await file.exists()) {
        await file.writeAsBytes(bytes);
      }

      return filePath; // Return the path to be saved in the Drift DB
    } catch (e) {
      print("Failed to save image to cache: $e");
      return null;
    }
  }
////////// ACCESS MUSIC COVER ART /////////////////////////////
  Future<String?> findArtwork(File songFile, Uint8List? embeddedBytes, String imageKey) async {
    // 1. If we have embedded bytes, save them to cache using the key
    if (embeddedBytes != null) {
      return await saveToImageCache(embeddedBytes, imageKey);
    }

    // 2. Jellyfin Strategy: Look for sidecar files in the same folder
    final directory = songFile.parent;
    final possibleArt = ['folder.jpg', 'cover.jpg', 'album.png', 'folder.png'];

    for (var name in possibleArt) {
      final artFile = File("${directory.path}/${name}");
      if (await artFile.exists()) {
        return artFile.path;
      }
    }

    return null; 
  }
////// Optimized GetOrCreate with Local Caching ///////////////
  Future<int> getOrCreateCached(String? name, Map<String, int> cache, TableInfo table, dynamic companion) async {
    final sanitizedName = (name == null || name.isEmpty) ? '' : name;

    if (sanitizedName.isEmpty) return 1; // Default "Unknown" seeded ID

    // 1. Check RAM (Super Fast)
    if (cache.containsKey(sanitizedName)) {
      return cache[sanitizedName]!;
    }

    // 2. RAM Miss -> Hit the DB
    int id;
    try {
      id = await db.into(table).insert(companion);
    } catch (e) {
      // Unique constraint failed, find the existing ID
      final existing = await (db.select(table)
            ..where((tbl) => (tbl as dynamic).value.equals(sanitizedName)))
          .getSingle();
      id = (existing as dynamic).id;
    }

    // 3. Save to RAM for next time
    cache[sanitizedName] = id;
    return id;
  }
///////// REFRESH LOOKUP TABLES ////////////////////////////////
  static void refreshLookUpTables() async {
    // set artist
    final artists = await db.select(db.artists).get();
    artistLookup = {for (var a in artists) a.id: a.value};
    // set cover
    final covers = await db.select(db.covers).get();
    coverLookup = {for (var c in covers) c.id: c.value};

    return;
  }

//////// CONVERT FILEPATHS INTO SONG COMPANION TYPES ///////////
  Future<SongsCompanion?> fileToCompanion(File file) async {

    // define some constants
    final fileName = path.basenameWithoutExtension(file.path);
    final parentFolderName = path.basename(file.parent.path);
    // Sanitizing the name for a Windows-safe filename
    final imageKey = parentFolderName.replaceAll(RegExp(r'[^\w\s]+'), '').toLowerCase().trim();

    // CREATE DEFAULTS INCASE MP3 CANNOT BE READ
    String title = fileName;
    String artist = parentFolderName;
    String album = parentFolderName;
    String genre = "Misc";
    // Link to a sidecar image if it exists even if we can't read the MP3
    String coverPath = "branding/color-darkbg.png";
    int durationMS = 0;

    // try fancy method of collecting all info
    try {
      // collect song meta data
      final metadata = await MetadataGod.readMetadata(file: file.path);

      // ATTEMPT TO FILL ALL SONG TABLE ATTRIBUTES FOR EACH SONG
      if (metadata.title?.isNotEmpty == true){ title = metadata.title!; }
      if (metadata.artist?.isNotEmpty == true){ artist = metadata.artist!; }      
      if (metadata.picture != null){ coverPath = (await findArtwork(file, metadata.picture?.data, imageKey))!; }
      // Execute lookups using the cache    
      if (metadata.album?.isNotEmpty == true){ album = metadata.album!; }
      if (metadata.genre?.isNotEmpty == true){ genre = metadata.genre!; }
      if (metadata.durationMs != null){ durationMS = metadata.durationMs!.toInt(); }

    } catch (e) {  // Fail-Safe: If Rust panics, we still get the song in the DB
      // print("FrbAnyhowException caught for $fileName. Using folder fallback.");
    }

    // existing getOrCreateCached logic with these names
    int artistId = await getOrCreateCached(artist, _artistCache, db.artists, ArtistsCompanion.insert(value: Value(artist)));
    int coverId = await getOrCreateCached(coverPath, _coverCache, db.covers, CoversCompanion.insert(value: Value(coverPath)));
    int albumId = await getOrCreateCached(album, _albumCache, db.albums, AlbumsCompanion.insert(value: Value(album)));
    int genreId = await getOrCreateCached(genre, _genreCache, db.genres, GenresCompanion.insert(value: Value(genre)));

    // update lookup tables
    refreshLookUpTables();

    return SongsCompanion(
      path: Value(file.path),
      filename: Value(fileName),
      title: Value(title),
      artistId: Value(artistId),
      coverId: Value(coverId),
      albumId: Value(albumId),
      genreId: Value(genreId),
      durationMS: Value(durationMS),
    );
  }

/////// GET LIST OF MEDIA FILES DETECTED BY THE APP ON SCAN //////
  Future<List<Song>> scanForMedia() async {
    // set var dir = media directory
    final dir = await getMediaDir();

    // first scan files from android storage if allowed
    if (Platform.isAndroid) {
      requestStoragePermission();
      await MediaScanner.loadMedia(path: dir.toString());
    }

    // get all existing paths
    final existingPaths = await (db.selectOnly(db.songs)..addColumns([db.songs.path]))
      .map((row) => row.read(db.songs.path)).get();
    // add paths to pathset
    final pathSet = existingPaths.toSet();
    // create list to hold songs
    List<SongsCompanion> toInsert = [];

    // ITERATIVELY SCAN ALL SONGS
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && allowedExtensions.contains(path.extension(entity.path).toLowerCase())) {
        
        // 1. Only process if not already in our memory set (prevents duplicates in one scan)
        if (!pathSet.contains(entity.path)) {
          final companion = await fileToCompanion(entity);
          
          if (companion != null) {
            toInsert.add(companion);
            // Add to pathSet so we don't process the same file twice in this loop
            pathSet.add(entity.path); 
          }
        }

        // 2. BATCH INSERT IN CHUNKS
        if (toInsert.length >= 20) {
          await db.batch((b) {
            // Mode: insertOrReplace fixes the "Unique Constraint" crash!
            b.insertAll(db.songs, toInsert, mode: InsertMode.insertOrReplace);
          });
          toInsert.clear();
          print("Batch of 20 inserted.");
        }
      }
    }

    // 3. CATCH THE LEFTOVERS (If you have 7 songs left over at the end)
    if (toInsert.isNotEmpty) {
      await db.batch((b) => b.insertAll(db.songs, toInsert, mode: InsertMode.insertOrReplace));
      toInsert.clear();
    }
    print("Media insertion complete!");
    print("New song total: ${await count(db.songs)}");

    // RETURN ALL SONGS IN THE SONGS TABLE AFTER ALL LOCAL SONGS HAVE BEEN ADDED
    return getAllSongs();
  }

  /////////// PLAY AN AUDIO FILE ////////////////////////////////////
  static Future<void> playMedia(Song song) async {
    // 1. If we are already loading THIS specific song, do nothing
    if (currentSong?.path == song.path && audioPlayer.playing) return;

    try {
      // 2. Set the state immediately so the UI reflects the change
      currentSong = song;
      
      // 3. Stop any existing playback to clear the native buffer
      await audioPlayer.pause();

      final ext = path.extension(song.path).toLowerCase();
      if (allowedExtensions.contains(ext)) {
        // 4. Load the file. 
        // Preload: false can sometimes help on Windows if the UI is hanging
        await audioPlayer.setFilePath(song.path, preload: true);
        
        // 5. Play!
        await audioPlayer.play();
      }
    } catch (e) {
      print("Audio error: $e");
    }
    // Note: I removed the _isManualSelection toggle here to see if the 
    // "Every other" pattern stops. 
  }

  /////////// FUNCTION TO HANDLE MEDIA PLAYBACK ////////////////////
    void mediaPlaybackAction(String action) async {
    // use switch-case
    switch (action) {
      // PAUSE
      case "pause":
        if (audioPlayer.playing == true) {
          audioPlayer.pause();
        } else {
          audioPlayer.play();
        }
      // FORWARD
      case "forward":
        final song = currentSong;
        if (song == null) return;
        final nextSong = await getById(db.songs, song.id + 1);
        if (nextSong == null) {
          // reloop if that setting is turned on
          if (looping == 1) {
            final restartSong = await getById(db.songs, 1);
            if (restartSong == null) {
              return;
            } else {
              playMedia(restartSong);
              return;
            }
          }
        } else if (looping == 0){ // if no looping active
          playMedia(nextSong);
        } else if (looping == 1){ // if no looping active
          playMedia(nextSong);
        } else if (looping == 2){ // single loop on
          playMedia(song);
        }
        print("FORWARD");
      // REWIND
      case "rewind":
        final song = currentSong;
        if (song == null) return;
        final prevSong = await getById(db.songs, song.id - 1);
        // if at top of list
        if (prevSong == null) {
          // reloop if that setting is turned on
          if (looping == 1) {
            // go back to the last song
            List<Song> allSongs = await getAllSongs();
            int totalSongs = allSongs.length;
            final restartSong = await getById(db.songs, totalSongs);
            if (restartSong != null) {
              playMedia(restartSong);
              return;
            }
            return;
          }
        } else if (looping == 0){ // if looping inactive
          playMedia(prevSong);
        } else if (looping == 1){ // if looping inactive
          playMedia(prevSong);
        } else {
          playMedia(song);
        }
        print("REVERSE");
      // LOOP
      case "loop":
        if (looping == 0) {
          looping = 1;
        } else if (looping == 1) {
          looping = 2;
        } else if (looping == 2){
          looping = 0;
        }
        print("LOOPING = $looping");
    }
  }

  // clean up when widget is disposed
  void dispose() => audioPlayer.dispose();
}

////////// PLAYLIST MANIPULATION //////////////////////////////
// create playlist
void createPlaylist(String title) async {
  await insert(db.playlists, PlaylistsCompanion(title: Value(title)));
  print("Playlist created: $title");
}
// delte playlist
void deletePlaylist(int id) async {
  deleteById(db.playlists, id);
  // await (db.delete(db.playlists)..where((tbl)=>tbl.title.equals(title))).go();
  print("Playlist deleted: $id");
}
// add song to playlist
void addSongToPlaylist(int playlistId, int songId) async {
  await insert(db.playlistSongs, PlaylistSongsCompanion(playlistId: Value(playlistId), songId: Value(songId)));
  print("Song added to playlist: $playlistId");

}