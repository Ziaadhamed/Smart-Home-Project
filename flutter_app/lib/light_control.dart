import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class LightControlPage extends StatelessWidget {
  final mqtt.MqttServerClient client = mqtt.MqttServerClient(
      'd00e494a6aae44fbb40323065d9ddfad.s1.eu.hivemq.cloud', '');
  final String username = '';// needs to be configured
  final String password = '';// needs to be configured
  final String topic = 'room_control';

  LightControlPage() {
    _connect();
  }

  Future<void> _connect() async {
    client.port = 8883;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.secure = true;
    client.setProtocolV311();

    final mqtt.MqttConnectMessage connMessage = mqtt.MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(mqtt.MqttQos.atMostOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == mqtt.MqttConnectionState.connected) {
      print('Connected');
    } else {
      print('Connection failed - status: ${client.connectionStatus}');
      client.disconnect();
    }
  }

  void _publishMessage(String room, String color, String intensity, bool isOn) {
    final builder = mqtt.MqttClientPayloadBuilder();
    builder.addString('$room,$color,$intensity,${isOn ? 'On' : 'Off'}');
    client.publishMessage(topic, mqtt.MqttQos.atMostOnce, builder.payload!);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchPreferencesDocument(
      String userId, String docId) async {
    try {
      final preferencesDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc(docId)
          .get();

      return preferencesDoc;
    } catch (e) {
      print('Error fetching preferences document: $e');
      rethrow;
    }
  }

  Future<void> _handleButtonPress(String roomName, bool isOn) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user signed in');
      return;
    }

    final uid = user.uid;
    print('Current user ID: $uid');
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!doc.exists) {
      print('User document does not exist');
      return;
    }

    final chosenPreference = doc.data()?['chosen_preference'];
    print('Chosen preference: $chosenPreference'); // Debugging print statement

    if (chosenPreference == null || chosenPreference == 'Not set') {
      _publishMessage(roomName, 'white', 'High', isOn);
    } else {
      try {
        final preferencesDoc =
            await _fetchPreferencesDocument(uid, chosenPreference);

        if (preferencesDoc.exists) {
          print('Fetched preferences document: ${preferencesDoc.data()}');
          final roomKey =
              roomName.toLowerCase().replaceAll(' ', '') + '_preferences';
          print('Looking for key: $roomKey'); // Debugging print statement
          final roomPreferences = preferencesDoc.data()?[roomKey];
          if (roomPreferences != null) {
            final color = roomPreferences['light_color'] ?? 'white';
            final intensity = roomPreferences['intensity'] ?? 'High';
            _publishMessage(roomName, color, intensity, isOn);
          } else {
            print(
                'No preferences set for $roomName in document ID: $chosenPreference');
            _publishMessage(roomName, 'white', 'High', isOn);
          }
        } else {
          print(
              'Preferences document does not exist for ID: $chosenPreference');
          _publishMessage(roomName, 'white', 'High', isOn);
        }
      } catch (e) {
        print('Error fetching preferences document: $e');
        _publishMessage(roomName, 'white', 'High', isOn);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lighting Control'),
        backgroundColor: Color.fromARGB(255, 243, 249, 236),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            height: 2.0,
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        width: 435,
        height: 932,
        padding: EdgeInsets.all(30),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Color(0xFFEFF8EC)),
        child: Column(
          children: [
            LightControlItem('Room 1', _handleButtonPress),
            SizedBox(height: 20),
            LightControlItem('Room 2', _handleButtonPress),
            SizedBox(height: 20),
            LightControlItem('Room 3', _handleButtonPress),
          ],
        ),
      ),
    );
  }

  void _onDisconnected() {
    print('Disconnected');
  }
}

class LightControlItem extends StatefulWidget {
  final String roomName;
  final Future<void> Function(String, bool) onToggle;

  LightControlItem(this.roomName, this.onToggle);

  @override
  _LightControlItemState createState() => _LightControlItemState();
}

class _LightControlItemState extends State<LightControlItem> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 335,
          height: 83,
          decoration: ShapeDecoration(
            color: Color(0xFFD2E7D7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.roomName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isOn = !isOn;
                  });
                  await widget.onToggle(widget.roomName, isOn);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.all(10),
                ),
                child: Text(
                  isOn ? 'Off' : 'On',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
