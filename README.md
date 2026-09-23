# Smart Home Project

A smart home system I built for my graduation project — a Flutter mobile app that controls room lighting, monitors temperature/humidity, and tries to optimize when lights get turned off, all talking to an Arduino over MQTT.

## What it does

- **Sign up / sign in** with Firebase Auth, plus a face photo captured at sign-up (stored in Firebase Storage) for face-verification login
- **Lighting control** — turn each room's light on/off and set its color + intensity, sent to the Arduino over MQTT
- **Saved preferences** — save a full 3-room lighting setup as a named preference and apply it later instead of setting each room manually
- **Environment monitoring** — live temperature and humidity readings from a DHT22 sensor on the Arduino, shown in the app in real time over MQTT
- **Energy saving** — the app logs what time you usually turn your lights off, averages it into a suggested "optimal" turn-off time, sends that to the Arduino so it can auto turn-off, and lets you rate how satisfied you were with that time

## How it's put together

- **Mobile app** — Flutter/Dart, Firebase Auth + Cloud Firestore + Firebase Storage
- **Hardware** — Arduino (WiFiNINA board) with a DHT22 temp/humidity sensor and RGB LEDs per room, connects over WiFi
- **Messaging** — MQTT (HiveMQ Cloud broker) is what connects the app and the Arduino — the app publishes light commands and the Arduino publishes sensor readings
- **Face recognition service** — a small Python Flask API (`Face_recognition.ipynb`) using the `face_recognition` library, that compares the sign-up photo against a new capture to verify identity

## Repo layout

```
Smart-Home-Project/
├── flutter_app/               # the mobile app (.dart files)
├── sketch_jul1a.ino           # Arduino firmware
├── Face_recognition.ipynb     # face verification service (Flask + face_recognition)
├── Project implementation.mp4 # demo video of the app running end-to-end
└── README.md
```

Check out `Project implementation.mp4` for a quick look at the app actually working — controlling lights, showing live sensor readings, etc.

## Things I'd improve if I revisit this

- Move all credentials (WiFi, MQTT, Firebase config) out of the code and into a gitignored config file
- The face recognition service is a separate manual step right now (upload two images, get a match/no-match) rather than being wired directly into the sign-in flow
- Error handling on the MQTT/Firebase calls is mostly just `print()` statements — would be better surfaced to the user
