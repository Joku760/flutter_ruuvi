import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetData extends StatelessWidget {
  final String documentId;
  final Timestamp date;
  final bool highTemp;

  GetData(this.documentId, this.highTemp, this.date);

  @override
  Widget build(BuildContext context) {
    CollectionReference values = FirebaseFirestore.instance.collection('RuuviData');
        /*values.where("Time", isEqualTo: date );
        values.orderBy('Temperature', descending: highTemp);
        values.limit(1); */

    return FutureBuilder<DocumentSnapshot>(
      future: values.doc(documentId).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {

        if (snapshot.hasError) {
          return Text("Something went wrong");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data = snapshot.data.data();
          return Text("FROM DATABASE: ${data['Temperature']} ${data['Time'].toDate()} ${data['DeviceId']}");
        }

        return Text("loading");
      },
    );
  }
}

class PushData extends StatelessWidget{

  final String deviceId;
  final double temperature;
  final Timestamp timeStamp;

  PushData(this.deviceId, this.temperature, this.timeStamp);

  @override
  Widget build(BuildContext context) {

    CollectionReference values = FirebaseFirestore.instance.collection('RuuviData');

    Future<void> addValue() {
      return values
          .add({
        'DeviceId': deviceId,
        'Temperature': temperature,
        'Time': timeStamp
      })
          .then((value) => print("Value Added"))
          .catchError((error) => print("Failed to add value: $error"));
    }

    //Muuta nappisysteemi pois, addValue funktio pyöritetään heti kun mahdollista.
    return FlatButton(
      onPressed: addValue,
      child: Text(
        "Add Value",
      ),
    );
  }
}

