import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _temperature = '--';
  String _humidity = '--';
  final client = MqttServerClient(
      'd00e494a6aae44fbb40323065d9ddfad.s1.eu.hivemq.cloud', '');
  final String username = 'ZiadHamed';
  final String password = 'ZiadCS4@#';
  final String topic = 'home/sensor';

  @override
  void initState() {
    super.initState();
    _connectAndSubscribe();
  }

  Future<void> _connectAndSubscribe() async {
    client.port = 8883;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.secure = true;
    client.setProtocolV311();

    final MqttConnectMessage connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected');
      client.subscribe(topic, MqttQos.atMostOnce);
      client.updates!.listen(_onMessage);
    } else {
      print('Connection failed - status: ${client.connectionStatus}');
      client.disconnect();
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    final MqttPublishMessage message = event[0].payload as MqttPublishMessage;
    final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

    final sensorData = payload.split(',');

    setState(() {
      _temperature = sensorData[0];
      _humidity = sensorData[1];
    });
  }

  void _onDisconnected() {
    print('Disconnected');
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(color: Color(0xffeff7ec)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Environment Monitor',
                  style: TextStyle(
                    color: Color.fromARGB(255, 134, 179, 136),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.thermostat_outlined,
                        size: 100,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'The temperature now is:',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        '$_temperature °C',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      Icon(
                        Icons.water_damage_outlined,
                        size: 100,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'The humidity now is:',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        '$_humidity %',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(HomePage());
}
