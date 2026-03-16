//////////  IMPORTS /////////////////////////////////////////////////////
import 'package:flutter/material.dart';
import 'tabs/playlists_tab.dart';
import 'tabs/songs_tab.dart';
import 'tabs/download_tab.dart';
import 'tabs/settings_tab.dart';
import 'package:satsuma_player/app_logic/media_handler.dart';

//// MAIN FUNC ///////////////////////////////////////////////////////////
void main() {
  runApp(const SatsumaPlayer());
}


///////// BASE APP CLASS /////////////////////////////////////////////////
// APP CLASS
class SatsumaPlayer extends StatelessWidget {
  // constructor
  const SatsumaPlayer({super.key});

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satsuma Player',

      // LIGHT THEME (Default)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      // DARK THEME
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark),
        useMaterial3: true,
      ),

      home: CustomTabController(),
    );
  }
}


//////// TAB INSERTION (FOR EACH APP TAB) ////////////////////////////////
// TAB CONTROLLER CLASS
class CustomTabController extends StatelessWidget {
  //constructor
  CustomTabController({super.key});

  // INITIALIZE AUDIO MANAGER FOR AUDIO PLAYLING
  final AudioManager aM = AudioManager();

  // BUILD THE UI
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
/////////////// CREATE THE APP BAR HOLDING ALL TAB ICONS ////////////////////
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: const Color.fromARGB(255, 84, 6, 228),
          bottom: const TabBar(
            tabs: [
              // PLAYLISTS, SONGS, SYNC, SETTINGS
              Tab(text: 'Playlists', icon: Icon(Icons.list)),
              Tab(text: 'Songs', icon: Icon(Icons.music_note)),
              Tab(text: 'Download', icon: Icon(Icons.download)),
              Tab(text: 'Settings', icon: Icon(Icons.settings)),
            ],
          ),
        ),

///////////// DISPLAY THE CONTENTS OF EACH TAB /////////////////////////////
        body: const TabBarView(children: [PlaylistsTab(), SongsTab(), DownloadTab(), SettingsTab()]),

///////////// DEFINE THE BOTTOM NAVIGATION BAR !!! ////////////////////////
        bottomNavigationBar: Container(
          color: Color.fromARGB(255, 6, 95, 228),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              //////// SHUFFLE TOGGLE BUTTON
              IconButton(
                onPressed: () {
                  aM.mediaPlaybackAction("shuffle");
                },
                icon: const Icon(Icons.shuffle),
                iconSize: 18,
                padding: EdgeInsets.all(25),
                constraints: const BoxConstraints(),
              ),
              //////// REWIND BUTTON
              IconButton(
                onPressed: () {
                  aM.mediaPlaybackAction("rewind");
                },
                icon: const Icon(Icons.fast_rewind_rounded),
                iconSize: 40,
                padding: EdgeInsets.all(20),
                constraints: const BoxConstraints(),
              ),
              //////// PAUSE BUTTON
              IconButton(
                onPressed: () {
                  aM.mediaPlaybackAction("pause");
                },
                icon: const Icon(Icons.pause_rounded),
                iconSize: 40,
                padding: EdgeInsets.all(20),
                constraints: const BoxConstraints(),
              ),
              //////// FORWARD BUTTON
              IconButton(
                onPressed: () {
                  aM.mediaPlaybackAction("forward");
                },
                icon: const Icon(Icons.fast_forward_rounded),
                iconSize: 40,
                padding: EdgeInsets.all(20),
                constraints: const BoxConstraints(),
              ),
              //////// LOOP TOGGLE BUTTON
              IconButton(
                onPressed: () {
                  aM.mediaPlaybackAction("loop");
                },
                icon: const Icon(Icons.loop),
                iconSize: 18,
                padding: EdgeInsets.all(25),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
