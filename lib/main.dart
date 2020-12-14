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
import 'package:numberpicker/numberpicker.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/cupertino.dart';



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
        initialRoute: '/',
        routes: {
        '/': (context) => MyHomePage(),
        //'/second': (context) => SecondRoute(),  //Piti laittaa kommenttiin että 'onGenerateRoute' toimii oikein ja antaa ID:n eteenpäin
        //'/third': (context) => ThirdRoute(),
        },
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
      onGenerateRoute: (settings) {
        if (settings.name == SecondRoute.routeName) {
          final PassID args = settings.arguments;
          return MaterialPageRoute(
            builder: (context) {
              return SecondRoute(
                  id: args.id
              );
            },
          );
        }
        if (settings.name == ThirdRoute.routeName) {
          final PassID args = settings.arguments;
          return MaterialPageRoute(
            builder: (context) {
              return ThirdRoute(
                  id: args.id
              );
            },
          );
        }
        assert(false, 'Need to implement ${settings.name}');
        return null;
      }
      //home: MyHomePage(title: 'Flutter Ruuvi Project'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  //final String title;
  //final FlutterBlue flutterBlue = FlutterBlue.instance;
  //final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<String> deviceList = new List<String>();
  String idChoice;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  var initializationSettingsAndroid;
  var initializationSettingsIOS;
  var initializationSettings;

  /*void showNotification() async{
    await demoNotification();
  }

  Future<void> demoNotification() async{
    var androidPlatformChannelSpecifics = AndroidNotificationDetails('channel_ID', 'channel name', 'channel description', importance: Importance.Max, priority: Priority.High, ticker: 'test ticker');
    var iOSChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'Saunamittari', 'Saunasi on nyt valmis!', platformChannelSpecifics, payload: 'test payload');
  }*/

  @override
  void initState(){
    super.initState();
    FlutterBlue.instance.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.advertisementData.toString().contains('1177')) {
          addToList(result.device.id.toString());
        }
      }
    });
    FlutterBlue.instance.startScan();

    initializationSettingsAndroid = new AndroidInitializationSettings('app_icon');
    initializationSettingsIOS = new IOSInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
    onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async{
    if(payload != null){
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(context,
    new MaterialPageRoute(builder: (context)=>ThirdRoute()));
  }

  Future onDidReceiveLocalNotification(int id, String body, String title, String payload) async{
    await showDialog(
      context: context,
      builder: (BuildContext context)=>CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('OK'),
            onPressed: () async{
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(context,
              MaterialPageRoute(builder: (context)=>ThirdRoute()));
            },
          )
        ],
      )
    );
  }

  addToList(String id) {
    if (!deviceList.contains(id)) {
      setState(() {
        deviceList.add(id);
        print(deviceList);
      });
    }
  }

  alertWindow() {
    showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Virhe'),
        content: Text(
            'Valitse ensin RuuviTag.'),
        actions: <Widget>[
          new FlatButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true)
                  .pop(); // dismisses only the dialog and returns nothing
            },
            child: new Text('OK'),
          ),
        ],
      ),
    );
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
        title: Text('Valitse sovellus'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RaisedButton(
              child: Text('Sääkalenteri'),
              onPressed: () {
                if (idChoice == null){
                  alertWindow();
                } else {
                  FlutterBlue.instance.stopScan();
                  print('Passing ID:');
                  print(idChoice);
                  Navigator.pushReplacementNamed(
                      context, '/second', arguments: PassID(idChoice));
                }
              },
            ),
            RaisedButton(
              child: Text('Saunamittari'),
              onPressed: () {
                if (idChoice == null){
                  alertWindow();
                } else {
                  FlutterBlue.instance.stopScan();
                  print('Passing ID:');
                  print(idChoice);
                  Navigator.pushReplacementNamed(
                      context, '/third', arguments: PassID(idChoice));
                }
              },
            ),
            for (String id in deviceList) new ListTile(
              title: Text(id),
              leading: Radio(
                value: id,
                groupValue: idChoice,
                onChanged: (value) {
                  setState(() {
                    idChoice = value;
                    print(idChoice);
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SecondRoute extends StatefulWidget{
  static const routeName = '/second';
  SecondRoute({
    Key key,
    this.id,
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String id;
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  int _counter = 0;
  double tempC = 0;
  bool notScanningYet = true;
  Isolate isolate;

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

  @override
  void initState(){
    super.initState();
    /*
    widget.flutterBlue.startScan(timeout: Duration(seconds: 3));
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.id.toString().contains(widget.id)) {
          print(result.advertisementData.manufacturerData);
          parseManufacturerData(result.advertisementData.manufacturerData);
          setState(() {});
        }
      }
    });
    */
    initIsolate();
  }

  Future<void> _incrementCounter() async {
    /*
    SendPort toIsolate = await initIsolate();
    toIsolate.send('Isolate started');
    print('ID is this:');
    print(widget.id);

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
    */
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
    PushData(widget.id, tempC).addValue();
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
              //'D9:E5:26:B2:B0:09' : 'E6:C0:0A:82:3C:3F' : 'E4:FA:5E:EE:BF:D8'   Just in case vielä ID:t tallessa nopeasti saatavilla
              if (result.device.id.toString().contains(widget.id)) {
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

    isolate = await Isolate.spawn(bluetoothIsolate, fromIsolate.sendPort);
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
        title: Text('Sääkalenteri'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              //Do something with selection
            },
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
                  GetData(true, dateValue, widget.id),
                ],
              ),
              Column(
                children: <Widget>[
                  Text("Tämän hetkinen lämpötila",style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),),
                  Text('$tempC \u{00B0}C', style: Theme.of(context).textTheme.headline4,),
                ],
              ),
              Column(
                children: <Widget>[
                  Text("Alin lämpötila",style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),),
                  GetData(false, dateValue, widget.id),
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
    print('[mainToIsolateStream] $data');
  });

  fromIsolate.send('Initial scan');

  Timer.periodic(Duration(seconds:10),(timer)=>fromIsolate.send('Continuous scan'));
}

class ThirdRoute extends StatefulWidget{
  static const routeName = '/third';
  ThirdRoute({Key key, this.id}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  //final String title;
  //final FlutterBlue flutterBlue = FlutterBlue.instance;
  //final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();

  final String id;
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  _ThirdRouteState createState() => _ThirdRouteState();
}

class _ThirdRouteState extends State<ThirdRoute> {
  double tempC = 0;
  bool notScanningYet = true;
  Isolate isolate;

  double _currentValue = 1.0;
  int page = 1;
  bool isCheckOn = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  Timer timer;

  @override
  void initState(){
    super.initState();
    /*
    widget.flutterBlue.startScan(timeout: Duration(seconds: 3));
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.id.toString().contains(widget.id)) {
          print(result.advertisementData.manufacturerData);
          parseManufacturerData(result.advertisementData.manufacturerData);
          setState(() {});
        }
      }
    });
    */
    initIsolate();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => temperatureCheck());
  }

  Future<void> _incrementCounter() async {
    /*
    SendPort toIsolate = await initIsolate();
    toIsolate.send('Isolate started');
    print('ID is this:');
    print(widget.id);

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
    */
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
    PushData(widget.id, tempC).addValue();
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
              //'D9:E5:26:B2:B0:09' : 'E6:C0:0A:82:3C:3F' : 'E4:FA:5E:EE:BF:D8'   Just in case vielä ID:t tallessa nopeasti saatavilla
              if (result.device.id.toString().contains(widget.id)) {
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

    isolate = await Isolate.spawn(bluetoothIsolate, fromIsolate.sendPort);
    return completer.future;
  }

  void temperatureCheck(){
    if(page == 0 && isCheckOn) {
      if (tempC >= _currentValue) {
        showNotification();
        isCheckOn = false;
      }
    }
  }

  void showNotification() async{
    await demoNotification();
  }

Future<void> demoNotification() async{
    var androidPlatformChannelSpecifics = AndroidNotificationDetails('channel_ID', 'channel name', 'channel description', importance: Importance.Max, priority: Priority.High, ticker: 'test ticker');
    var iOSChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'Saunamittari', 'Saunasi on nyt valmis!', platformChannelSpecifics, payload: 'test payload');
}

  @override
  Widget build(BuildContext context) {
    if(page == 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Saunamittari'),
          centerTitle: true,
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text("Valitse lämpötila"),
              NumberPicker.decimal(
                  initialValue: _currentValue,
                  minValue: 0,
                  maxValue: 100,
                  onChanged: (newValue) =>
                      setState(() => _currentValue = newValue)),
              Text("Olet valinnut: $_currentValue astetta."),
              RaisedButton(
                child: Text('Käynnistä'),
                onPressed: () {
                  setState(() {
                    page = 0;
                    isCheckOn = true;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
    else{
      return Scaffold(
        appBar: AppBar(
          title: Text('Saunamittari'),
          centerTitle: true,
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text('$tempC \u{00B0}C/$_currentValue \u{00B0}C', style: Theme.of(context).textTheme.headline4,),
              RaisedButton(
                child: Text('Peruuta'),
                onPressed: () {
                  setState(() {
                    page = 1;
                    _currentValue = 1.0;
                    isCheckOn = false;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}

class PassID {
  String id;

  PassID(this.id);
}
