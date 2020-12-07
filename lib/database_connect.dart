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
      //checkData
      //if (checkdata == true){
      return values
          .add({
        'DeviceId': deviceId,
        'Temperature': temperature,
        'Time': localDate
      })
          .then((value) => print("Value Added"))
          .catchError((error) => print("Failed to add value: $error"));
    //}
    }
}

class CheckData  {

  final String deviceId;
  final double temperature;
  int counter = 0;
  Map<String, dynamic> data1;
  Map<String, dynamic> data2;
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
          }
          if(counter == 2)
          {
            data2 = result.data();
          }
          Map<String, dynamic> data = result.data();
          print(data.toString());
          print(counter);
        })
      });
    }

  Future<bool> dataCheck() async {

    if(counter == 0)
    {
      print('0');
      return true;
    }
    else if(counter == 1 && data1['Temperature'] != temperature)
    {
      print('1');
      return true;
    }
    else if(counter == 2)
    {
      if(data1['Temperature'] < temperature)
      {
        //poisto homma
        print('2iso');
        return true;
      }
      else if(data2['Temperature'] > temperature)
      {
        //poisto homma
        print('2pieni');
        return true;
      }
      else
      {
        print('2false');
        return false;
      }
    }
    else{
      print('false');
      return false;
    }
  }

}