#include <WiFiNINA.h>
#include <WiFiUdp.h>
#include <NTPClient.h>
#include <PubSubClient.h>
#include <DHT.h>

#define DHTPIN 14 // DHT22 sensor pin
#define DHTTYPE DHT22 // DHT22 sensor type

// WiFi network credentials
char ssid[] = ""; // needs to be configured
char pass[] = ""; // needs to be configured

// MQTT Broker details
const char* mqtt_server = "d00e494a6aae44fbb40323065d9ddfad.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_username = "";// needs to be configured
const char* mqtt_password = "";// needs to be configured
const char* control_topic = "room_control";
const char* sensor_topic = "home/sensor";
const char* energy_topic = "energy"; // Added energy topic

// MQTT client
WiFiSSLClient wifiClient;
PubSubClient client(wifiClient);

// NTP Client to get time
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

DHT dht(DHTPIN, DHTTYPE);

void setup() {
    Serial.begin(9600);

    // Initialize WiFi and NTP
    initializeWiFi();
    timeClient.begin();
    timeClient.setTimeOffset(0); // Set the time offset to your timezone

    // Wait for time synchronization
    while (!timeClient.update()) {
        timeClient.forceUpdate();
        delay(500);
    }
    Serial.print("Current time: ");
    Serial.println(timeClient.getFormattedTime());

    initializeMQTT();
    dht.begin();

    // Initialize all pins for all rooms
    int pins[] = {2, 3, 4, 10, 11, 12, 5, 6, 9};
    for (int i = 0; i < 9; i++) {
        pinMode(pins[i], OUTPUT);
        digitalWrite(pins[i], LOW); // Ensure all pins start off
    }
}

void loop() {
    if (!client.connected()) {
        reconnect();
    }
    client.loop();

    // Read temperature and humidity from DHT22
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    if (!isnan(temperature) && !isnan(humidity)) {
        String sensorData = String(temperature, 2) + "," + String(humidity, 2); // Convert floats to string with 2 decimal places

        boolean success = client.publish(sensor_topic, sensorData.c_str());

        delay(100); // Reduce delay, adjust as needed
    }
}

void initializeWiFi() {
    Serial.print("Connecting to WiFi...");
    while (WiFi.begin(ssid, pass) != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("WiFi connected");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    // Adding a delay to ensure WiFi connection is stable before proceeding
    delay(2000);

    // Test connection to MQTT broker
    Serial.print("Pinging MQTT broker...");
    IPAddress remote_ip;
    if (WiFi.hostByName(mqtt_server, remote_ip)) {
        Serial.print("MQTT broker IP: ");
        Serial.println(remote_ip);
        if (WiFi.ping(remote_ip)) {
            Serial.println("MQTT broker is reachable");
        } else {
            Serial.println("MQTT broker is not reachable");
        }
    } else {
        Serial.println("Failed to resolve MQTT broker hostname");
    }
}

void initializeMQTT() {
    client.setServer(mqtt_server, mqtt_port);
    client.setCallback(callback);
}

void reconnect() {
    while (!client.connected()) {
        Serial.print("Attempting MQTT connection...");
        if (client.connect("arduinoClient", mqtt_username, mqtt_password)) {
            Serial.println("connected");
            client.subscribe(control_topic); // Subscribe to the control topic
            client.subscribe(energy_topic);  // Subscribe to the energy topic
        } else {
            Serial.print("failed, rc=");
            Serial.print(client.state());
            Serial.println(" try again in 5 seconds");
            delay(5000);
        }
    }
}

void callback(char* topic, byte* payload, unsigned int length) {
    payload[length] = '\0'; // Null-terminate the payload
    String message = String((char*)payload);
    Serial.print("Message arrived [");
    Serial.print(topic);
    Serial.print("]: ");
    Serial.println(message);

    if (String(topic) == control_topic) {
        handleControl(message);
    } else if (String(topic) == energy_topic) {
        handleEnergyMessage(message);
    }
}

void handleControl(String message) {
    // Split the message into components
    int firstComma = message.indexOf(',');
    int secondComma = message.indexOf(',', firstComma + 1);
    int thirdComma = message.indexOf(',', secondComma + 1);

    String room = message.substring(0, firstComma);
    String color = message.substring(firstComma + 1, secondComma);
    String intensityStr = message.substring(secondComma + 1, thirdComma);
    String state = message.substring(thirdComma + 1);

    Serial.print("Room: ");
    Serial.println(room);
    Serial.print("Color: ");
    Serial.println(color);
    Serial.print("Intensity: ");
    Serial.println(intensityStr);
    Serial.print("State: ");
    Serial.println(state);

    int intensity = 0;
    if (intensityStr == "Low") {
        intensity = 85; // 33% brightness
    } else if (intensityStr == "Medium") {
        intensity = 170; // 66% brightness
    } else if (intensityStr == "High") {
        intensity = 255; // 100% brightness
    }

    int redPin = -1, greenPin = -1, bluePin = -1;
    if (room == "Room 1") {
        redPin = 2;
        greenPin = 3;
        bluePin = 4;
    } else if (room == "Room 2") {
        redPin = 10;
        greenPin = 11;
        bluePin = 12;
    } else if (room == "Room 3") {
        redPin = 5;
        greenPin = 6;
        bluePin = 9;
    }

    if (redPin != -1 && greenPin != -1 && bluePin != -1) {
        if (state == "On") {
            if (color == "Red") {
                analogWrite(redPin, intensity);
                analogWrite(greenPin, 0);
                analogWrite(bluePin, 0);
            } else if (color == "Green") {
                analogWrite(redPin, 0);
                analogWrite(greenPin, intensity);
                analogWrite(bluePin, 0);
            } else if (color == "Blue") {
                analogWrite(redPin, 0);
                analogWrite(greenPin, 0);
                analogWrite(bluePin, intensity);
            } else if (color == "Yellow") {
                analogWrite(redPin, intensity);
                analogWrite(greenPin, intensity);
                analogWrite(bluePin, 0);
            } else {
                analogWrite(redPin, intensity);
                analogWrite(greenPin, intensity);
                analogWrite(bluePin, intensity);
            }
        } else {
            analogWrite(redPin, 0);
            analogWrite(greenPin, 0);
            analogWrite(bluePin, 0);
        }
    }
}

void handleEnergyMessage(String message) {
    // Example message format: "12:30"
    Serial.print("Received estimated turn-off time: ");
    Serial.println(message);
    Serial.println(message);
    // Parse the received time
    int colonIndex = message.indexOf(':');
    if (colonIndex != -1) {
        int hours = message.substring(0, colonIndex).toInt();
        int minutes = message.substring(colonIndex + 1).toInt();
        Serial.println(hours);
        Serial.println(minutes);
        // Compare with current time
        timeClient.update();
        int currentHours = timeClient.getHours();
        int currentMinutes = timeClient.getMinutes();
        if(currentHours > 12){
          currentHours -= 12;
        }
        else if(currentHours == 0){
          currentHours += 12;
        }
        Serial.print("Current time: ");
        Serial.print(currentHours);
        Serial.print(":");
        Serial.println(currentMinutes);

        // If current time matches estimated turn-off time, turn off all pins
        if (currentHours == hours && currentMinutes == minutes) {
            turnOffAllPins();
            Serial.println("Turned off all pins based on estimated time");
        }
    }
}

void turnOffAllPins() {
    int pins[] = {2, 3, 4, 10, 11, 12, 5, 6, 9};
    for (int i = 0; i < 9; i++) {
        digitalWrite(pins[i], 0);
    }
}

