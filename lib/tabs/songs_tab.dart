// import required libraries
import 'package:flutter/material.dart';
import 'package:satsuma_player/database/app_database.dart';
import '../app_logic/media_handler.dart';
import 'package:path/path.dart' as path; // file path recognition
import 'dart:io'; // input/output
import '../database/repositories/song_repository.dart';

// define the StatefulWidget class
class SongsTab extends StatefulWidget {
  // constructor
  const SongsTab({super.key});

  @override
  State<SongsTab> createState() => _SongsTabState();
}

// define the State class
class _SongsTabState extends State<SongsTab> {
  // manage state variables here

  // build the UI for this tab content
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      // scaffold
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
                    // title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Your Songs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    // buttons
                    Row(
                      // padding: const EdgeInsets.symmetric(horizontal: 2),
                      children: [
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
        body: Expanded(
          child: Scaffold(
            body: FutureBuilder<List<Song>>(
              future: AudioManager.scanForMedia(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No media found."));
                }

                final songs = snapshot.data!;

                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    // final filename = file.path.split('/').last;

                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(path.basename(song.path)),
                      onTap: () {
                        AudioManager.playMedia(song);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
