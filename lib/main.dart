import 'dart:async';
import 'dart:typed_data';

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
        },
      theme: ThemeData(
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
    return Scaffold(
      appBar: AppBar(
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

  final String id;
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  double tempC = 0;
  bool notScanningYet = true;
  Timer timer;

  var _currentDate = new DateTime.now();
  DateTime dateValue; //valittu päivämäärä

  @override
  void initState(){
    super.initState();
    startScan();
    timer = Timer.periodic(Duration(seconds:10),(timer) => startScan());
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

  startScan(){
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sääkalenteri'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Etusivu') {
                timer.cancel();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Etusivu'}.map((String choice) {
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
    );
  }
}

class ThirdRoute extends StatefulWidget{
  static const routeName = '/third';
  ThirdRoute({Key key, this.id}) : super(key: key);

  final String id;
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  _ThirdRouteState createState() => _ThirdRouteState();
}

class _ThirdRouteState extends State<ThirdRoute> {
  double tempC = 0;
  bool notScanningYet = true;

  double _currentValue = 1.0;
  int page = 1;
  bool isCheckOn = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  Timer timer;

  @override
  void initState(){
    super.initState();
    startScan();
    timer = Timer.periodic(Duration(seconds:10),(timer) {
      startScan();
      temperatureCheck();
    });
  }

  startScan(){
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
