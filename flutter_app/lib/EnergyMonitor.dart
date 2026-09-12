import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class EnergyMonitor extends StatefulWidget {
  @override
  _TimePickerPageState createState() => _TimePickerPageState();
}

class _TimePickerPageState extends State<EnergyMonitor> {
  TimeOfDay selectedTime = TimeOfDay.now();
  int rating = 0;
  TimeOfDay? optimalTime;

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  final CollectionReference times =
      FirebaseFirestore.instance.collection('turnOffTimes');

  Future<void> addTime(String time) {
    return times.add({
      'time': time,
      'time stamp': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Time Picker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Selected Time: ${selectedTime.format(context)}',
              style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
              onPressed: () => selectTime(context),
              child: Text('Select Time'),
            ),
            SizedBox(height: 20),
            RatingBar.builder(
              initialRating: 1,
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                this.rating = rating.toInt();
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  addTime(selectedTime.format(context)), // Pass selected time
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
            if (optimalTime != null)
              Text(
                'Optimal Time: ${optimalTime!.format(context)}',
                style: TextStyle(fontSize: 20),
              ),
          ],
        ),
      ),
    );
  }
}
