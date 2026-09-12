import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class EnergySaving extends StatefulWidget {
  const EnergySaving({Key? key}) : super(key: key);

  @override
  _EnergySavingState createState() => _EnergySavingState();
}

class _EnergySavingState extends State<EnergySaving> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String optimalDate = '';
  double satisfactionLevel = 0.0; // Initial satisfaction level

  final TextEditingController ratingController = TextEditingController();
  final TextEditingController numberController = TextEditingController();

  late MqttServerClient client;
  bool isMqttConnected = false;

  @override
  void initState() {
    super.initState();
    numberController.addListener(() {
      final text = numberController.text;
      numberController.value = numberController.value.copyWith(
        text: text.replaceAll(RegExp(r'[^0-9]'), ''),
        selection: TextSelection.collapsed(offset: text.length),
      );
    });

    fetchFirebaseTurnOffTimes();
    setupMqttClient();
  }

  Future<void> setupMqttClient() async {
    client = MqttServerClient(
        'd00e494a6aae44fbb40323065d9ddfad.s1.eu.hivemq.cloud', '');
    client.port = 8883;
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.secure = true; // Use secure connection
    client.setProtocolV311(); // Set protocol version
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterClient')
        .authenticateAs('ZiadHamed', 'ZiadCS4@#')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
      setState(() {
        isMqttConnected = true;
      });
      print('Connected to MQTT broker');
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
    isMqttConnected = false;
    // Optionally, try to reconnect
    setupMqttClient();
  }

  Future<void> addTurnOffTimeToFirebase(DateTime turnOffTime) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('turnOffTimes')
            .add({
          'time': turnOffTime.toLocal().toString(),
        });
        await fetchFirebaseTurnOffTimes();
      } else {
        print('User not logged in');
      }
    } catch (e) {
      print('Error adding turn-off time to Firebase: $e');
    }
  }

  Future<void> fetchFirebaseTurnOffTimes() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('turnOffTimes')
            .get();
        List<String> firebaseTurnOffTimes =
            snapshot.docs.map((doc) => doc['time'].toString()).toList();

        if (firebaseTurnOffTimes.isNotEmpty) {
          List<DateTime> turnOffTimesList = firebaseTurnOffTimes
              .map((timeStr) => DateTime.parse(timeStr))
              .toList();

          await calculateAndSaveOptimalTime(turnOffTimesList);
        }
      } else {
        print('User not logged in');
      }
    } catch (e) {
      print('Error fetching turn-off times from Firebase: $e');
    }
  }

  Future<void> calculateAndSaveOptimalTime(
      List<DateTime> turnOffTimesList) async {
    DateTime averageTime = calculateAverageTime(turnOffTimesList);

    setState(() {
      optimalDate = TimeOfDay.fromDateTime(averageTime).format(context);
    });

    await sendEstimatedTimeToArduino(optimalDate);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('optimalTimes')
            .add({
          'time': optimalDate,
        });
      } else {
        print('User not logged in');
      }
    } catch (e) {
      print('Error saving optimal time to Firestore: $e');
    }
  }

  Future<void> sendEstimatedTimeToArduino(String time) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(time);

    try {
      if (isMqttConnected) {
        client.publishMessage("energy", MqttQos.atMostOnce, builder.payload!);
        print('Estimated time sent: $time');
      } else {
        print('MQTT client not connected');
      }
    } catch (e) {
      print('Error publishing message: $e');
    }
  }

  DateTime calculateAverageTime(List<DateTime> times) {
    Duration totalDuration = Duration();
    for (DateTime time in times) {
      totalDuration += time.difference(DateTime(0));
    }
    Duration averageDuration = totalDuration ~/ times.length;
    return DateTime(0).add(averageDuration);
  }

  void _showTimePicker() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      DateTime selectedDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await addTurnOffTimeToFirebase(selectedDateTime);
    }
  }

  Future<void> _submitRating() async {
    int inputRating = int.tryParse(ratingController.text) ?? 0;
    if (inputRating >= 1 && inputRating <= 10) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ratings')
            .add({
          'rating': inputRating,
        });
        ratingController.clear();
        await fetchAndUpdateSatisfactionLevel();
      } else {
        print('User not logged in');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a number between 1 and 10 for rating.'),
        ),
      );
    }
  }

  Future<void> fetchAndUpdateSatisfactionLevel() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ratings')
            .get();
        List<int> ratingsList =
            snapshot.docs.map((doc) => doc['rating'] as int).toList();

        double totalRating = ratingsList.isNotEmpty
            ? ratingsList.reduce((value, element) => value + element).toDouble()
            : 0.0;

        setState(() {
          satisfactionLevel = (totalRating / (ratingsList.length * 10)) * 100.0;
        });
      } else {
        print('User not logged in');
      }
    } catch (e) {
      print('Error fetching and updating satisfaction level: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text("Energy Saving"), titleSpacing: 10),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _showTimePicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 173, 218, 172),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Pick Today’s Turn Off Time',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w500,
                        height: 0,
                      )),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 83,
                decoration: ShapeDecoration(
                  color: Color(0xFFAAD1A9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Estimated Time is: $optimalDate',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: 'Rambla',
                      fontWeight: FontWeight.w400,
                      height: 0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 43,
                decoration: ShapeDecoration(
                  color: Color(0xFFD2E7D0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Satisfaction Level: ${satisfactionLevel.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: 'Rambla',
                      fontWeight: FontWeight.w400,
                      height: 0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    TextField(
                      controller: ratingController,
                      decoration: InputDecoration(
                        hintText: 'Rate the energy-saving experience (1-10)',
                        filled: true,
                        fillColor: Color(0xFFDFE9DF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 173, 218, 172),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('Submit Rating',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w500,
                              height: 0,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    ratingController.dispose();
    numberController.dispose();
    client.disconnect();
    super.dispose();
  }
}
