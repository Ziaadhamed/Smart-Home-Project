import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'PreferencesTitle.dart';

class TopCenterRoundedClickableContainer extends StatefulWidget {
  @override
  _TopCenterRoundedClickableContainerState createState() =>
      _TopCenterRoundedClickableContainerState();
}

class _TopCenterRoundedClickableContainerState
    extends State<TopCenterRoundedClickableContainer> {
  bool _isTapped = false;
  bool _isAddingPreference = false;
  List<Map<String, dynamic>> _preferences = [];
  String _chosenPreference = "Not set";

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadChosenPreference();
  }

  Future<void> _loadPreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    final CollectionReference preferencesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('preferences');

    QuerySnapshot snapshot = await preferencesCollection.get();
    List<Map<String, dynamic>> preferences = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add the document ID to the data map
      return data;
    }).toList();

    setState(() {
      _preferences = preferences;
      print('Preferences loaded: $_preferences'); // Debug statement
    });
  }

  Future<void> _loadChosenPreference() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    final DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);

    DocumentSnapshot userSnapshot = await userDoc.get();
    if (userSnapshot.exists) {
      setState(() {
        _chosenPreference = userSnapshot['chosen_preference'] ?? "Not set";
      });
    } else {
      setState(() {
        _chosenPreference = "Not set";
      });
    }
  }

  Future<void> _addPreference(Map<String, String> newPreference) async {
    if (_isAddingPreference) return;
    setState(() {
      _isAddingPreference = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    final CollectionReference preferencesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('preferences');

    // Fetch existing preferences outside the transaction
    QuerySnapshot existingPreferencesSnapshot =
        await preferencesCollection.get();
    List<Map<String, dynamic>> existingPreferences =
        existingPreferencesSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data;
    }).toList();

    bool isDuplicate = existingPreferences.any((preference) =>
        preference['room1_preferences']['intensity'] ==
            newPreference['Room 1']!.split(', ')[1] &&
        preference['room1_preferences']['light_color'] ==
            newPreference['Room 1']!.split(', ')[0] &&
        preference['room2_preferences']['intensity'] ==
            newPreference['Room 2']!.split(', ')[1] &&
        preference['room2_preferences']['light_color'] ==
            newPreference['Room 2']!.split(', ')[0] &&
        preference['room3_preferences']['intensity'] ==
            newPreference['Room 3']!.split(', ')[1] &&
        preference['room3_preferences']['light_color'] ==
            newPreference['Room 3']!.split(', ')[0]);

    if (isDuplicate) {
      setState(() {
        _isAddingPreference = false;
      });
    } else {
      // Use a Firestore transaction to ensure atomicity
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference docRef = preferencesCollection.doc();

        transaction.set(docRef, {
          'room1_preferences': {
            'intensity': newPreference['Room 1']!.split(', ')[1],
            'light_color': newPreference['Room 1']!.split(', ')[0]
          },
          'room2_preferences': {
            'intensity': newPreference['Room 2']!.split(', ')[1],
            'light_color': newPreference['Room 2']!.split(', ')[0]
          },
          'room3_preferences': {
            'intensity': newPreference['Room 3']!.split(', ')[1],
            'light_color': newPreference['Room 3']!.split(', ')[0]
          },
        });

        setState(() {
          _preferences.add({
            'id': docRef.id,
            'room1_preferences': {
              'intensity': newPreference['Room 1']!.split(', ')[1],
              'light_color': newPreference['Room 1']!.split(', ')[0]
            },
            'room2_preferences': {
              'intensity': newPreference['Room 2']!.split(', ')[1],
              'light_color': newPreference['Room 2']!.split(', ')[0]
            },
            'room3_preferences': {
              'intensity': newPreference['Room 3']!.split(', ')[1],
              'light_color': newPreference['Room 3']!.split(', ')[0]
            },
          });
          print(
              'New preference added: ${_preferences.last}'); // Debug statement
        });
      });
      setState(() {
        _isAddingPreference = false;
      });
    }
  }

  Future<void> _applyPreference(int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    String chosenPreferenceId = _preferences[index]['id'];

    final DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);

    await userDoc.update({'chosen_preference': chosenPreferenceId});

    setState(() {
      _chosenPreference = chosenPreferenceId;
      print("Applied preference ID: $chosenPreferenceId"); // Debug statement
    });
  }

  Future<void> _checkPreferenceExistence() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    final DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);

    DocumentSnapshot userSnapshot = await userDoc.get();
    if (userSnapshot.exists) {
      String chosenPreferenceId =
          userSnapshot['chosen_preference'] ?? "Not set";
      if (chosenPreferenceId != "Not set") {
        final DocumentReference chosenPreferenceDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .doc(chosenPreferenceId);

        DocumentSnapshot chosenPreferenceSnapshot =
            await chosenPreferenceDoc.get();
        if (!chosenPreferenceSnapshot.exists) {
          setState(() {
            _chosenPreference = "Not set";
          });
        }
      }
    } else {
      setState(() {
        _chosenPreference = "Not set";
      });
    }
  }

  void _deletePreference(int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    String docId = _preferences[index]['id'];

    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc(docId);

    await docRef.delete();

    setState(() {
      _preferences.removeAt(index);
      print('Preference deleted: $docId'); // Debug statement
    });

    if (_chosenPreference == docId) {
      setState(() {
        _chosenPreference = "Not set";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffeff7ec),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Center(
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _isTapped = true;
                    });
                  },
                  onTapUp: (_) async {
                    setState(() {
                      _isTapped = false;
                    });

                    // Debounce mechanism
                    if (_isTapped) return;

                    final newPreferences = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PreferencesPage()),
                    );
                    if (newPreferences != null) {
                      await _addPreference(newPreferences);
                      await _loadPreferences(); // Ensure preferences are reloaded
                    }
                  },
                  onTapCancel: () {
                    setState(() {
                      _isTapped = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [
                          _isTapped ? Colors.lightGreenAccent : Colors.green,
                          Colors.teal,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Add New Preference',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ..._preferences.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> preference = entry.value;
              return PreferenceContainer(
                index: index,
                preference: preference,
                onApply: () => _applyPreference(index),
                onDelete: () => _deletePreference(index),
                isChosen: _chosenPreference == preference['id'],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class PreferenceContainer extends StatelessWidget {
  final int index;
  final Map<String, dynamic> preference;
  final VoidCallback onApply;
  final VoidCallback onDelete;
  final bool isChosen;

  PreferenceContainer({
    required this.index,
    required this.preference,
    required this.onApply,
    required this.onDelete,
    this.isChosen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isChosen ? Colors.lightBlueAccent : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preference ${index + 1}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Room 1: ${preference['room1_preferences']['light_color']}, ${preference['room1_preferences']['intensity']}',
          ),
          Text(
            'Room 2: ${preference['room2_preferences']['light_color']}, ${preference['room2_preferences']['intensity']}',
          ),
          Text(
            'Room 3: ${preference['room3_preferences']['light_color']}, ${preference['room3_preferences']['intensity']}',
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: onApply,
                child: Text('Apply'),
              ),
              ElevatedButton(
                onPressed: onDelete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
