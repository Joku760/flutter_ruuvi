import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetData extends StatelessWidget {
  final DateTime date;
  final bool highTemp;
  final String deviceId;

  GetData(this.highTemp, this.date, this.deviceId);

  @override
  Widget build(BuildContext context) {

    DateTime localDate;
    localDate = date;
    if(date == null)
      {
        DateTime today = DateTime.now();
        localDate = new DateTime(today.year, today.month, today.day);
      }
    DateTime limiterDate = localDate.add(Duration(days: 1));

    CollectionReference values = FirebaseFirestore.instance.collection('RuuviData');
    Timestamp.fromDate(localDate);
    return FutureBuilder<QuerySnapshot>(
      future: values.where('DeviceId', isEqualTo: deviceId).where('Time', isGreaterThanOrEqualTo: localDate).where('Time', isLessThan: limiterDate).orderBy('Time').orderBy('Temperature', descending: highTemp).limit(1).get(),
      builder:
          (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong");
        }

        if (snapshot.connectionState == ConnectionState.done) {

          final querySnapshot = snapshot.data;
          querySnapshot.docs.forEach((result) {
            Map<String, dynamic> data = result.data();

           /* print(data.toString());
            print(data['Time'].toString());
            print(data['Time'].toDate().toString());
            print(' ');*/

          });
          //print(localDate.toString());
          if(querySnapshot.docs.length != 0)
            {
              Map <String, dynamic> data = querySnapshot.docs[0].data();
              //return Text("DATABASE: ${data['Temperature']} ${data['Time'].toDate()} ${data['DeviceId']}");
              return Text("${data['Temperature']}");
            }
          else{
            return Text("No data");
          }
        }

        return Text("loading");
      },
    );
  }
}

class PushData {

  final String deviceId;
  final double temperature;

  PushData(this.deviceId, this.temperature);

    CollectionReference values = FirebaseFirestore.instance.collection('RuuviData');

    Future<void> addValue() {

      DateTime today = DateTime.now();
      DateTime localDate = new DateTime(today.year, today.month, today.day);

      return values
          .add({
        'DeviceId': deviceId,
        'Temperature': temperature,
        'Time': localDate
      })
          .then((value) => print("Value Added"))
          .catchError((error) => print("Failed to add value: $error"));
    }
}