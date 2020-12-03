import 'dart:async';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ruuvi/database_connect.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart' show CalendarCarousel;
import 'package:flutter_calendar_carousel/classes/event.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Ruuvi Project'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  double tempC = 0;
  bool noIsolateRunning = true;
  bool notScanningYet = true;

  var _currentDate = new DateTime.now();
  DateTime dateValue; //valittu päivämäärä

  void handleClick(String value) {
    switch (value) {
      case 'Settings':
        break;
      case 'Logout':
        break;
    }
  }

  Future<void> _incrementCounter() async {
    CheckData("1", 22.5).dataCheck();
    /*if (noIsolateRunning = true){
      SendPort toIsolate = await initIsolate();
      toIsolate.send('Isolate started');
      noIsolateRunning = false;
    }

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });*/
  }

  parseManufacturerData(data) {
    var manufacturerData = Uint8List.fromList(data[1177]);
    var pressure = ByteData.sublistView(manufacturerData, 4, 6);
    var humidity = ByteData.sublistView(manufacturerData, 2, 4);
    var temperature = ByteData.sublistView(manufacturerData, 0, 2);
    print("Pressure: ${(pressure.getUint16(0, Endian.little)+50000)/100} hPa");
    print("Humidity: ${humidity.getUint16(0, Endian.little)/400} %");
    print("Temperature: ${temperature.getUint16(0, Endian.little)*0.005} \u{00B0}C");
    tempC = temperature.getUint16(0, Endian.little)*0.005;
  }

  Future<SendPort> initIsolate() async {
    Completer completer = new Completer<SendPort>();
    ReceivePort fromIsolate = ReceivePort();

    fromIsolate.listen((data) {
      if (data is SendPort) {
        SendPort toIsolate = data;
        completer.complete(toIsolate);
      } else {
        print(data);
        widget.flutterBlue.startScan(timeout: Duration(seconds: 3));
        widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
          if(notScanningYet){
            notScanningYet = false;
            for (ScanResult result in results) {
              //if (result.device.id.toString().contains('E6:C0:0A:82:3C:3F')) {
              //if (result.device.id.toString().contains('E4:FA:5E:EE:BF:D8')) {
              if (result.device.id.toString().contains('D9:E5:26:B2:B0:09')) {
                print(result.advertisementData.manufacturerData);
                parseManufacturerData(result.advertisementData.manufacturerData);
                setState(() {});
              }
            }
          }
        });
        notScanningYet = true;
      }
    });

    Isolate bluetoothIsolateInstance = await Isolate.spawn(bluetoothIsolate, fromIsolate.sendPort);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: handleClick,
            itemBuilder: (BuildContext context) {
              return {'Logout', 'Settings'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(padding: EdgeInsets.all(20.0),),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text("Ylin lämpötila",style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),),
                  GetData(true, dateValue, '1'), //Kovakoodatun arvon tilalle laitteen id
                ],
              ),
              Column(
                children: <Widget>[
                  Text("Tämän hetkinen lämpötila",style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),),
                  Text('$tempC \u{00B0}C', style: Theme.of(context).textTheme.headline4,),
                  //PushData('1', 27.2).addValue(); //Kovakoodatun arvon tilalle mittaavan laitteen id ja lämpötila
                ],
              ),
              Column(
                children: <Widget>[
                  Text("Alin lämpötila",style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),),
                  GetData(false, dateValue, '1'), //kovakoodatun arvon tilalle laitteen id
                ],
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            child: CalendarCarousel<Event>(
              onDayPressed: (DateTime date, List<Event> events) {
                this.setState(() => _currentDate = dateValue = date);
              },
              weekendTextStyle: TextStyle(
                color: Colors.red,
              ),
              thisMonthDayBorderColor: Colors.grey,
              weekFormat: false,
              pageSnapping: true,
              firstDayOfWeek: 1,
              markedDatesMap: null,
              height: 420.0,
              width: 620.0,
              selectedDateTime: _currentDate,
              daysHaveCircularBorder: false, /// null for not rendering any border, true for circular border, false for rectangular border
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

void bluetoothIsolate(SendPort fromIsolate) {
  ReceivePort toIsolate = ReceivePort();
  fromIsolate.send(toIsolate.sendPort);

  toIsolate.listen((data) {
    //todo Vastaanottaa RuuviTag device IDn
    print('[mainToIsolateStream] $data');
  });

  Timer.periodic(Duration(seconds:10),(timer)=>fromIsolate.send('Start scan'));
}
