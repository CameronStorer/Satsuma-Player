// import required libraries
import 'package:flutter/material.dart';
import '../app_logic/media_handler.dart';
import 'package:path/path.dart' as path; // file path recognition
// DATABASE IMPORTS
import 'package:satsuma_player/database/database.dart';
import 'package:satsuma_player/database/brains.dart';

// DEFINE THE STATEFULWIDGET CLASS
class SongsTab extends StatefulWidget {
  // constructor
  const SongsTab({super.key});
  @override
  State<SongsTab> createState() => _SongsTabState();
}
// DEFINE THE STATE CLASS
class _SongsTabState extends State<SongsTab> {
  // DEFINE STREAM VARIABLE
  late Stream<List<Song>> _songStream;
  // INITIALIZE STREAM WHEN TAB CREATED (FOR STABLE CONNECTION)
  @override
  void initState(){
    super.initState();
    _songStream = watchAllSongs();
  }
  // MANAGE STATE VARIABLES HERE
  // BUILD THE UI FOR THIS TAB CONTENT
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      // SCAFFOLD
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
////////////////////////// TITLE ////////////////////////////////////////////
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Your Songs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
/////////////////////// NAVBAR BUTTONS ///////////////////////////////////////
                    Row(
                      // padding: const EdgeInsets.symmetric(horizontal: 2),
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Column(children: [Icon(Icons.scanner), Text('Rescan')]),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Column(children: [Icon(Icons.search), Text('Search')]),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Column(children: [Icon(Icons.sort), Text('Sort By')]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
//////////////////// TAB PAGE CONTENTS ////////////////////////////////////////
        body: Expanded(
          child: Scaffold(
            body: StreamBuilder<List<Song>>(
              // The Source: database stream
              stream: _songStream,

              builder: (context, snapshot){
                // Handle the 'loading' state
                // on first load, stream is empty for a few seconds
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Handle potential errors
                if (snapshot.hasError){
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Handle the 'empty' state
                final songList = snapshot.data ?? [];
                if (songList.isEmpty) {
                  return const Center(child: Text('No songs found. Start scanning!'));
                }

                // the 'success' UI
                return ListView.builder(
                  itemCount: songList.length,
                  itemBuilder: (context, index) {
                    final song = songList[index];
                    return ListTile(
                      title: Text(song.title),
                      // subtitle: Text(song.artist ?? 'Unknown'),
                      subtitle: Text(AudioManager.artistLookup[song.artistId] ?? 'Unknown Artist'),
                      onTap: () => AudioManager.playMedia(song),
                    );
                  },
                );
              },
            )
          ),
        ),
      ),
    );
  }
}
