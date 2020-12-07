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

    Future<void> addValue() async {
      DateTime today = DateTime.now();
      DateTime localDate = new DateTime(today.year, today.month, today.day);
      bool checkData = await CheckData(deviceId, temperature).checkDataMain();
      if (checkData == true){
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
}

class CheckData  {

  final String deviceId;
  final double temperature;
  int counter = 0;
  Map<String, dynamic> data1;
  Map<String, dynamic> data2;
  String data1Id;
  String data2Id;
  CheckData(this.deviceId, this.temperature);

  Future <bool> checkDataMain() async {
    await dataGet();
    bool data = await dataCheck();
   return data;
  }

  Future<void> dataGet() async{
      DateTime today = DateTime.now();
      DateTime localDate = new DateTime(today.year, today.month, today.day);
      DateTime limiterDate = localDate.add(Duration(days: 1));
      CollectionReference values = FirebaseFirestore.instance.collection('RuuviData');
      await values.where('DeviceId', isEqualTo: deviceId).where('Time', isGreaterThanOrEqualTo: localDate).where('Time', isLessThan: limiterDate).orderBy('Time').orderBy('Temperature', descending: true).limit(2).get()
          .then((QuerySnapshot querySnapshot) => {
        querySnapshot.docs.forEach((result) {
          counter ++;
          if(counter == 1)
          {
            data1 = result.data();
            data1Id = result.id;
          }
          if(counter == 2)
          {
            data2 = result.data();
            data2Id = result.id;
          }
          //Map<String, dynamic> data = result.data();
          //print(data.toString());
          //print(counter);

        })
      });
    }

  Future<bool> dataCheck() async {

    if(counter == 0)
    {
      print('Counter = 0');
      return true;
    }
    else if(counter == 1 && data1['Temperature'] != temperature)
    {
      print('Counter = 1');
      return true;
    }
    else if(counter == 2)
    {
      if(data1['Temperature'] < temperature)
      {
        deleteData(data1Id);
        print('Counter = 2, iso');
        return true;
      }
      else if(data2['Temperature'] > temperature)
      {
        deleteData(data2Id);
        print('Counter = 2 pieni');
        return true;
      }
      else
      {
        print('Counter = 2 false');
        return false;
      }
    }
    else{
      print('Counter = 1, lämpötila on jo tietokannassa');
      return false;
    }
  }

  void deleteData(String documentId)
  {
    print(documentId);
    CollectionReference users = FirebaseFirestore.instance.collection('RuuviData');
          users.doc(documentId)
          .delete()
          .then((value) => print("Doc Deleted"))
          .catchError((error) => print("Failed to delete Doc: $error"));
  }
}