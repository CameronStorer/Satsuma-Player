# Satsuma Player
Modern multi-platform media playback/downloader application built primarily in Dart utilizing the Flutter framework.


### Windows Developer instructions
run command ```flutter run -d windows``` from the root directory of this repo.

### Windows Dependencies
To build this project on a Windows machine, the user must first install Visual Studio 2026 (specifically with C++ Desktop Build Tools). Then the user must install and add the Flutter SDK to path (as environment variable) and swap to flutter channel beta before running an update command. The user can then run 'flutter clean', followed by 'flutter pub get' and 'flutter pub upgrade' where applicable. Next the user must enable developer mode on the windows computer.

Upon completing the above steps, the user should then be greeted with Satsuma Player's latest dev build.
