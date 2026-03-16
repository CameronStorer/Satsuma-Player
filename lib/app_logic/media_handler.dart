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
import 'package:just_audio/just_audio.dart'; // audio handling

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

////////// AUDIOMANAGER CLASS /////////////////////////////////
class AudioManager {
  // CONSTRUCTOR
  AudioManager(){
    initialize();
    requestStoragePermission();
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

//////// CONVERT FILEPATHS INTO SONG COMPANION TYPES //////////////
Future<SongsCompanion> fileToCompanion(File file) async {
  // read the tags
  final metadata = await MetadataGod.readMetadata(file.path);

  // add artist to artist table if not already present
  if (metadata.artist != null && getByTitle(db.artists, metadata.artist!) == null){
      insert(db.artists, ArtistsCompanion(title:Value(metadata.artist!)));
  }
  // add genre to genre table if not already present
  if (metadata.genre != null && getByTitle(db.genres, metadata.genre!) == null){
      insert(db.genres, GenresCompanion(title:Value(metadata.genre!)));
  }
  // add album to album table if not already present
  if (metadata.album != null && getByTitle(db.albums, metadata.album!) == null){
      insert(db.albums, AlbumsCompanion(title:Value(metadata.album!)));
  }

  Artist? getArtistId = await getByTitle(db.artists, metadata.artist!);
  Genre? getGenreId = await getByTitle(db.genres, metadata.genre!);
  Album? getAlbumId = await getByTitle(db.albums, metadata.album!);

  

  // map metadata to drift columns
  return SongsCompanion(
    path: Value(file.path),
    filename: Value(path.basename(file.path)),
    // Use the title from tags, or fallback to filename
    title: Value(metadata.title ?? path.basenameWithoutExtension(file.path)),
    artistId: await getByTitle(db.artists, metadata.artist!),
    
    
    
    Value(metadata.artist ?? 1),
    albumId: Value(metadata.album ?? 1),
    durationMS: Value(metadata.durationMs?.toInt() ?? 0),
    // If you have a genre column
    genre: Value(metadata.genre ?? 'Misc'),
  );
}


/////// GET LIST OF MEDIA FILES DETECTED BY THE APP ON SCAN //////
  static Future<List<Song>> scanForMedia() async {
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

    // ITERATIVELY INSERT ALL SONGS
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && allowedExtensions.contains(path.extension(entity.path))) {
        // FAST IN-MEMORY CHECK
        if (!pathSet.contains(entity.path)){
          final companion = await fileToCompanion(entity);
          toInsert.add(companion);
        }
        // BATCH INSERT IN CHUCKS SO UI UPDATES IN WAVES
        if (toInsert.length >= 20){
          await db.batch((b) => b.insertAll(db.songs, toInsert));
          toInsert.clear();
        }
        final ext = path.extension(entity.path).toLowerCase();
        if (!(await songExists(entity.path))) {
          // ADD THE FILES TO THE DATABASE
          await addSongFromFile(entity.path);
        }
      }
    }
    print("Media insertion complete!");
    if (await getSongCount() is int){
      print("New song total: ${await getSongCount()}");
    }

    // RETURN ALL SONGS IN THE SONGS TABLE AFTER ALL LOCAL SONGS HAVE BEEN ADDED
    return getAllSongs();
  }

/////////// PLAY AN AUDIO FILE ////////////////////////////////////
  static void playMedia(Song song) async {
    _isManualSelection = true; // Tell the listener to chill
    final song_path = song.path;
    final ext = path.extension(song_path).toLowerCase();
    if (allowedExtensions.contains(ext)) {
      try {
        await audioPlayer.setFilePath(song_path);
        await audioPlayer.play();
        currentSong = song;
        print(currentSong);
      } catch (e) {
        print("Audio error: $e");
      }
    } else {
      print("Unsupported file type: $ext");
    }
    print(_isManualSelection);
    _isManualSelection = false; // Back to normal
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
        final nextSong = await getSongById(song.id + 1);
        if (nextSong == null) {
          // reloop if that setting is turned on
          if (looping == 1) {
            final restartSong = await getSongById(1);
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
        final prevSong = await getSongById(song.id - 1);
        // if at top of list
        if (prevSong == null) {
          // reloop if that setting is turned on
          if (looping == 1) {
            // go back to the last song
            List<Song> allSongs = await getAllSongs();
            int totalSongs = allSongs.length;
            final restartSong = await getSongById(totalSongs);
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
