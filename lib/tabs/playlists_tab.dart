// import required libraries
import 'package:flutter/material.dart';
import 'package:satsuma_player/app_logic/ui_handler.dart';
// DATABASE IMPORTS
import 'package:satsuma_player/database/database.dart';
import 'package:satsuma_player/database/brains.dart';

// define the StatefulWidget class
class PlaylistsTab extends StatefulWidget {
  // constructor
  const PlaylistsTab({super.key});

  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

// define the State class
class _PlaylistsTabState extends State<PlaylistsTab> {
  // DEFINE STREAM VARIABLE
  late Stream<List<Playlist>> _playlistStream;
  // INITIALIZE STREAM WHEN TAB CREATED (FOR STABLE CONNECTION)
  @override
  void initState(){
    super.initState();
    _playlistStream = watchAllPlaylists();
  }

  // build the UI for this tab content
  @override
  Widget build(BuildContext context) {
    // list of Playlist objects
    // final List<Playlist> userPlaylists = const [
    //   Playlist('Coding Focus', 'assets/covers/color-darkbg.png', 45),
    //   Playlist('Coding Focus', 'assets/covers/2.png', 1),
    //   Playlist('Coding Focus', 'assets/covers/3.png', 23),
    //   Playlist('Coding Focus', 'assets/covers/4.png', 67),
    //   Playlist('Coding Focus', 'assets/covers/5.png', 100),
    //   Playlist('Coding Focus', 'assets/covers/6.png', 12),
    // ];

    return Column(
      // Column is used for the title shown above the grid (of playlists)
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
//////////// TITLE ////////////////////////////////////////////////
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your Playlists',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
//////////// PLAYLIST MANIPULATE BTTNS ////////////////////////////////////////////
            IconButton(onPressed: () => showAddDialog(context), padding: EdgeInsets.all(15), icon: Icon(Icons.add_circle)),
//             PopupMenuButton<String>(
//   icon: const Icon(Icons.add_circle),
//   padding: const EdgeInsets.all(15),
//   onSelected: (value) => print(value),
//   itemBuilder: (BuildContext context) {
//     return {'New', 'Option 2'}.map((String choice) {
//       return PopupMenuItem<String>(
//         value: choice,
//         child: Text(choice),
//       );
//     }).toList();
//   },
// ),
            IconButton(onPressed: () {}, padding: EdgeInsets.all(15), icon: Icon(Icons.remove_circle)),
          ])],
        ),
        // --- build the playlist grid ---

///////////// BUILD EACH PLAYLIST ITEM ////////////////////////////////////////

      // The individual item structure remains the same

  Expanded(
    child: Scaffold(
      body: StreamBuilder<List<Playlist>>(
      // The Source: database stream
      stream: _playlistStream,

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
        final playlistList = snapshot.data ?? [];
        if (playlistList.isEmpty) {
          return const Center(child: Text('No Playlists found. Create one ^!'));
        }

        // the 'success' UI
        final list = snapshot.data ?? [];
          return 
          
          
          // Expanded(
          //   child: GridView.builder(
          //     gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(                
          //       // --- gridDelegate to help organize grid elements ---
          //       // Flutter calculates how many can fit.
          //       maxCrossAxisExtent: 140.0, // max width 140 pixels
          //       crossAxisSpacing: 10.0, // Max width allowed for each item.
          //       mainAxisSpacing: // Setting this lower makes the tiles smaller.
          //       15.0, // Increased vertical spacing for better separation
          //       childAspectRatio:
          //       0.8, // Adjusted aspect ratio to account for text below the square image
          //     ),
          // //     padding: const EdgeInsets.all(8.0),
          // //     itemCount: list.length,
          //     itemBuilder: (context, index) {
          // //       Column(
          // //         crossAxisAlignment: CrossAxisAlignment.start,
          // //         children: <Widget>[
          // //         // 1. COVER ART
          // //         Expanded(
          // //           child: ClipRRect(
          // //             borderRadius: BorderRadius.circular(8.0),
          // //             child: Image.asset("branding/neon.png", fit: BoxFit.cover),
          // //           ),
          // //         ),
          // //         // 2. TITLE
          // //         Padding(
          // //           padding: const EdgeInsets.only(top: 4.0),
          // //           child: Text(
          // //             "title",
          // //             maxLines: 1,
          // //             overflow: TextOverflow.ellipsis,
          // //             style: const TextStyle(
          // //               fontWeight: FontWeight.bold,
          // //               fontSize: 13,
          // //             ),
          // //           ),
          // //         ),
          // //         // 3. SONG COUNT
          // //         Text(
          // //           '${playlistList.length} songs',
          // //           style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          // //         ),
          // //       ]
          // //     );
          //     }
          //   )
          // );

        // --- build the playlist grid ---
        Expanded(
          // use a GridView.builder
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: list.length,
            // --- gridDelegate to help organize grid elements ---
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              // set some attributes for the grid
              // Max width allowed for each item.
              // Flutter calculates how many can fit.
              // Setting this lower makes the tiles smaller.
              maxCrossAxisExtent: 140.0, // max width 140 pixels
              crossAxisSpacing: 10.0,
              mainAxisSpacing:
                  15.0, // Increased vertical spacing for better separation
              childAspectRatio:
                  0.8, // Adjusted aspect ratio to account for text below the square image
            ),

            // --- Build Each Playlist Item ---
            itemBuilder: (context, index) {
              final playlist = playlistList[index];
              // The individual item structure remains the same
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. COVER ART
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset("branding/neon.png", fit: BoxFit.cover),
                    ),
                  ),
                  // 2. TITLE
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // 3. SONG COUNT
                  Text(
                    'SONG COUNT',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              );
            },
          ),
        );


            },)
            ))]); }      
            
            
          }









//         return ListView.builder(
//           itemCount: playlistList.length,
//           itemBuilder: (context, index) {
//             final playlist = playlistList[index];
// /////////////// USE A GRIDVIEW.BUILDER /////////////////////////////////////////
//             // final Playlist playlist = userPlaylists[index];

          // },
//         )
//     )]
//     );}
// }
                  //   return ListTile(
                  //     leading: 
                  //       Image.asset(AudioManager.coverLookup[playlist.coverId] ?? 'branding/neon.png',
                  //       width: 50,
                  //       height: 50,
                  //       fit: BoxFit.cover,
                  //     ),

                  //     title: Text(playlist.title),
                  //     // subtitle: Text('${count()} songs'),
                  //     // onTap: () => AudioManager.playMedia(playlist),
                  //   );
              // }





                  // // 1. COVER ART
                  // Expanded(
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius.circular(8.0),
                  //     child: Image.asset(playlist.imagePath, fit: BoxFit.cover),
                  //   ),
                  // ),
                  // // 2. TITLE
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 4.0),
                  //   child: Text(
                  //     playlist.title,
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //     style: const TextStyle(
                  //       fontWeight: FontWeight.bold,
                  //       fontSize: 13,
                  //     ),
                  //   ),
                  // ),
                  // // 3. SONG COUNT
                  // Text(
                  //   '${playlist.songCount} songs',
                  //   style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  // ),




// playlist class to hold playlist details
// class Playlist {
//   // class variables
//   final String title;
//   final String imagePath;
//   final int songCount;

//   // class constructor
//   const Playlist(this.title, this.imagePath, this.songCount);
// }
