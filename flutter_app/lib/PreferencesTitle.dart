import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const CardExampleApp());
}

class CardExampleApp extends StatelessWidget {
  const CardExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Example App',
      debugShowCheckedModeBanner: false,
      home: PreferencesPage(),
    );
  }
}

class PreferencesPage extends StatefulWidget {
  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final Map<String, String> _roomSettings = {
    'Room 1': 'White, Low',
    'Room 2': 'White, Low',
    'Room 3': 'White, Low',
  };

  void _savePreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    String userId = user.uid;

    try {
      final CollectionReference preferencesCollection = FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .collection('preferences');

      // Check for duplicates
      QuerySnapshot existingPreferences = await preferencesCollection.get();
      bool isDuplicate = existingPreferences.docs.any((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['room1_preferences']['intensity'] ==
                _roomSettings['Room 1']!.split(', ')[1] &&
            data['room1_preferences']['light_color'] ==
                _roomSettings['Room 1']!.split(', ')[0] &&
            data['room2_preferences']['intensity'] ==
                _roomSettings['Room 2']!.split(', ')[1] &&
            data['room2_preferences']['light_color'] ==
                _roomSettings['Room 2']!.split(', ')[0] &&
            data['room3_preferences']['intensity'] ==
                _roomSettings['Room 3']!.split(', ')[1] &&
            data['room3_preferences']['light_color'] ==
                _roomSettings['Room 3']!.split(', ')[0];
      });

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicate preferences. No new list added.')),
        );
        return;
      }

      // Add new preferences if no duplicates found
      await preferencesCollection.add({
        'room1_preferences': {
          'intensity': _roomSettings['Room 1']!.split(', ')[1],
          'light_color': _roomSettings['Room 1']!.split(', ')[0]
        },
        'room2_preferences': {
          'intensity': _roomSettings['Room 2']!.split(', ')[1],
          'light_color': _roomSettings['Room 2']!.split(', ')[0]
        },
        'room3_preferences': {
          'intensity': _roomSettings['Room 3']!.split(', ')[1],
          'light_color': _roomSettings['Room 3']!.split(', ')[0]
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences saved successfully!')),
      );

      Navigator.pop(context, _roomSettings);
    } catch (e) {
      print('Error saving preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          color: Colors.lightGreen[50],
          child: Column(
            children: [
              const PreferencesTitle(),
              const SizedBox(height: 20),
              RoomSettings(
                roomName: 'Room 1',
                onSettingsChanged: (settings) {
                  _roomSettings['Room 1'] = settings;
                },
              ),
              const SizedBox(height: 20),
              RoomSettings(
                roomName: 'Room 2',
                onSettingsChanged: (settings) {
                  _roomSettings['Room 2'] = settings;
                },
              ),
              const SizedBox(height: 20),
              RoomSettings(
                roomName: 'Room 3',
                onSettingsChanged: (settings) {
                  _roomSettings['Room 3'] = settings;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePreferences,
                child: const Text('Add new list'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreferencesTitle extends StatelessWidget {
  const PreferencesTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'Preferences',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: Colors.black,
      ),
    );
  }
}

class RoomSettings extends StatefulWidget {
  final String roomName;
  final ValueChanged<String> onSettingsChanged;

  const RoomSettings(
      {Key? key, required this.roomName, required this.onSettingsChanged})
      : super(key: key);

  @override
  _RoomSettingsState createState() => _RoomSettingsState();
}

class _RoomSettingsState extends State<RoomSettings> {
  String _selectedLightColor = 'White';
  String _selectedIntensityLevel = 'Low';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.lightGreen[100],
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.roomName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedLightColor,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Light Color',
              ),
              items: <String>['White', 'Red', 'Green', 'Blue', 'Yellow']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  if (newValue != null) _selectedLightColor = newValue;
                  widget.onSettingsChanged(
                      '$_selectedLightColor, $_selectedIntensityLevel');
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedIntensityLevel,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Intensity Level',
              ),
              items: <String>['Low', 'Medium', 'High'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  if (newValue != null) _selectedIntensityLevel = newValue;
                  widget.onSettingsChanged(
                      '$_selectedLightColor, $_selectedIntensityLevel');
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
