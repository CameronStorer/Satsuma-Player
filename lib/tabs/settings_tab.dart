// import required libraries
import 'package:flutter/material.dart';

// define the StatefulWidget class
class SettingsTab extends StatefulWidget {
  // constructor
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

// define the State class
class _SettingsTabState extends State<SettingsTab> {
  // manage state variables here

  // build the UI for this tab content
  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode = ThemeMode.dark;
    bool _isDarkTheme = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Choose Brightness', style: TextStyle(fontSize:16),textAlign: TextAlign.left),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,  children: [
                  IconButton(onPressed: (){}, icon: Icon(Icons.settings_system_daydream_rounded), 
                  color: const Color.fromARGB(255, 148, 148, 148), iconSize: 40, tooltip: "system"),
                  IconButton(onPressed: (){}, icon: Icon(Icons.wb_sunny), 
                  color: Colors.amber, iconSize: 40, tooltip: "light"),
                  IconButton(onPressed: (){}, icon: Icon(Icons.nightlight_round_sharp), 
                  color: const Color.fromARGB(255, 71, 92, 206), iconSize: 40, tooltip: "dark"),
                ]),
              ],),
            ListTile(
            title: Text('Debug'),
            trailing: Switch(
              value: _isDarkTheme,
              onChanged: (value) {
                setState(() {
                  _isDarkTheme = value;
                  themeMode = value ? ThemeMode.dark : ThemeMode.light;
                });
              },
            ),
          ),
          // ListTile(
          //   title: 

            // .:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Change Color Scheme', style: TextStyle(fontSize:16),textAlign: TextAlign.left),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,  children: [
                  IconButton(onPressed: (){}, icon: Icon(Icons.circle), 
                  color: Colors.amber, iconSize: 40, tooltip: "satsuma"),
                  IconButton(onPressed: (){}, icon: Icon(Icons.circle), 
                  color: Colors.indigoAccent, iconSize: 40, tooltip: "blueberry"),
                  IconButton(onPressed: (){}, icon: Icon(Icons.circle), 
                  color: Colors.pinkAccent, iconSize: 40, tooltip: "strawberry"),
                  IconButton(onPressed: (){}, icon: Icon(Icons.circle), 
                  color: Colors.lightGreenAccent, iconSize: 40, tooltip: "pare"),
                ]),
              ],),
          // ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Change App Icon', style: TextStyle(fontSize:16),textAlign: TextAlign.left),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,  children: [
                  IconButton(onPressed: (){}, icon:  
                  Image.asset("branding/color-darkbg.png", width: 40, height: 40, fit: BoxFit.cover),tooltip: "darkBg"),
                  IconButton(onPressed: (){}, icon:
                  Image.asset("branding/color-lightbg.png", width: 40, height: 40, fit: BoxFit.cover),tooltip: "lightBg"),
                  IconButton(onPressed: (){}, icon:
                  Image.asset("branding/neon-effects.png", width: 40, height: 40, fit: BoxFit.cover),tooltip: "neon"),
                  IconButton(onPressed: (){}, icon:
                  Image.asset("branding/mono-white-orangebg.png", width: 40, height: 40, fit: BoxFit.cover),tooltip: "gradient"),
                  IconButton(onPressed: (){}, icon:
                  Image.asset("branding/mobile_icon_old.png", width: 40, height: 40, fit: BoxFit.cover),tooltip: "classic"),
                ]),
              ],),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Change Music Scanning Directory', style: TextStyle(fontSize:16),textAlign: TextAlign.left),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,  children: []),
              ],),
        ],
      ),
    );
  }
}
