// File to handle the scanning and management of media

// import appropriate packages
import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart'; // audio handling
import 'package:media_scanner/media_scanner.dart'; // for scanning media
import '../database/repositories/song_repository.dart';
import '../database/app_database.dart';
import 'package:permission_handler/permission_handler.dart';


// Retrieve music file directory
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

// android specific issue
Future<bool> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  return status.isGranted;
}

// AudioManager class
class AudioManager {
  // constructor
  AudioManager(){
    initialize();
    requestStoragePermission();
  }

  // initialize a database object
  static final repo = SongRepository(AppDatabase());
  // class variable holding the currently playing song
  static Song? current_song;
  static int looping = 0;  // 0 = false, 1 = yes general, 2 = yes single
  static bool shuffle = false; // shuffle attribute
  static final AudioPlayer audioPlayer = AudioPlayer();
  bool hasStartedPlaying = false;
  bool currentlyPlaying = false;
  // list holding compatible file extensions
  static const allowedExtensions = ['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.acc', '.vorbis', '.alac'];

  // ensure that the AudioManager can initialize itself and keep track of music
  void initialize() {
    // WIP AUTOPLAY
    // // ensure that the music plays in order shown on-screen
    // // Listen to position to detect actual playback
    // audioPlayer.positionStream.listen((position) {
    //   if (position > Duration.zero) {
    //     hasStartedPlaying = true;            // Song really started
    //   }
    // });

    // audioPlayer.processingStateStream.listen((state) async {
    //   if (state == ProcessingState.completed && hasStartedPlaying) {
    //     print("REAL completion → go forward");
    //     hasStartedPlaying = false;           // reset for next song
    //     mediaPlaybackAction("forward");
    //   }
    // });
  }



  // function to return a list of all media files detected by the app
  static Future<List<Song>> scanForMedia() async {
    // first scan files from android storage if allowed
    if (Platform.isAndroid) {
      if (!await requestStoragePermission()) {
        print("Storage permission denied");
      }
      await MediaScanner.loadMedia(path: "/storage/emulated/0/Music/Satsuma Player");
    }

    // set var dir = media directory
    final dir = await getMediaDir();
    // allowed extension types
    int counter = 0;

    // Recursively list everything
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (allowedExtensions.contains(ext) && !(await repo.songExists(entity.path))) {
          // add the files to the database
          await repo.addSongFromFile(entity.path);
          counter++;
        }
      }
    }
    print("Media scan complete!");
    print("Database updated by $counter songs");
    if (await repo.songCount() is int){
      print("New song total: ${await repo.songCount()}");
    }

    return repo.getAllSongs();
  }

  // PLAY AN AUDIO FILE
  static void playMedia(Song song) async {
    final song_path = song.path;
    if (song_path == Null) return;
    final ext = path.extension(song_path).toLowerCase();
    if (allowedExtensions.contains(ext)) {
      try {
        await audioPlayer.setFilePath(song_path);
        await audioPlayer.play();
        current_song = song;
      } catch (e) {
        print("Audio error: $e");
      }
    } else {
      print("Unsupported file type: $ext");
    }
  }

  // function to handle media playback
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
        final song = current_song;
        if (song == null) return;
        final nextSong = await repo.getSongById(song.id + 1);
        if (nextSong == null) {
          // reloop if that setting is turned on
          if (looping == 1) {
            final restartSong = await repo.getSongById(1);
            if (restartSong == null) {
              return;
            } else {
              playMedia(restartSong);
              return;
            }
          }
        } else if (looping == 0){ // if no looping active
          playMedia(nextSong);
        } else { // single loop on
          playMedia(song);
        }
        print("FORWARD");
      // REWIND
      case "rewind":
        final song = current_song;
        if (song == null) return;
        final prevSong = await repo.getSongById(song.id - 1);
        // if at top of list
        if (prevSong == null) {
          // reloop if that setting is turned on
          if (looping == 1) {
            // go back to the last song
            List<Song> allSongs = await repo.getAllSongs();
            int totalSongs = allSongs.length;
            final restartSong = await repo.getSongById(totalSongs);
            if (restartSong != null) {
              playMedia(restartSong);
              return;
            }
            return;
          }
        } else if (looping == 0){ // if looping inactive
          playMedia(prevSong);
        } else {
          playMedia(song);
        }
        print("REVERSE");
      // LOOP
      case "loop":
        if (looping == 0) {
          looping = 1;
          print("LOOPING = GENERAL");
        } else if (looping == 1) {
          looping = 2;
          print("LOOPING = SINGLE");
        } else {
          looping = 0;
          print("LOOPING = FALSE");
        }
    }
  }
}
