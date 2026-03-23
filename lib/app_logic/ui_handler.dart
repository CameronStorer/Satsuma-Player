//////////  IMPORTS /////////////////////////////////////////////////////
import 'package:flutter/material.dart';
import 'package:satsuma_player/app_logic/media_handler.dart';
import 'package:metadata_god/metadata_god.dart';   // for finding song meta data


void showAddDialog(BuildContext context) {
  // 1. Create a controller to get the text out of the box
  TextEditingController _controller = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('New Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Important: prevents the dialog from taking full screen
          children: [
            const Text('Enter a name for your new playlist:'),
            const SizedBox(height: 15),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Playlist Name",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          // Cancel Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          // Accept Button
          ElevatedButton(
            onPressed: () {
              print("User entered: ${_controller.text}");
              createPlaylist(_controller.text);
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('ACCEPT'),
          ),
        ],
      );
    },
  );
}