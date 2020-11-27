import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class GetData extends StatelessWidget {
  final String documentId;
  final Timestamp date;
  final bool highTemp;
  final DateTime dates = new DateTime(2020-21-11);

  GetData(this.documentId, this.highTemp, this.date);

  @override
  Widget build(BuildContext context) {
    Firebase.initializeApp();
    CollectionReference values = FirebaseFirestore.instance.collection('RuuviData');
      //.where("Time", isEqualTo: dates )

    return FutureBuilder<QuerySnapshot>(
      future: values.orderBy('Temperature', descending: highTemp).limit(1).get(),
      builder:
          (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

        if (snapshot.hasError) {
          return Text("Something went wrong");
        }

        if (snapshot.connectionState == ConnectionState.done) {

          final querySnapshot = snapshot.data;
          querySnapshot.docs.forEach((result) {
            Map<String, dynamic> data = result.data();
            log(data.toString());
          });

          Map <String, dynamic> data = querySnapshot.docs[0].data();
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

