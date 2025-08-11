import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Su Seviyesi Projesi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String distance = '';
  Timer? _timer;
  double parsedDistance = 0.0;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    _requestPermissions();

    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = const IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    fetchDistance();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      fetchDistance();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.scheduleExactAlarm.request();
    if (status.isGranted) {
      print('Permission granted');
    } else {
      
      print('Permission denied');
    }
  }

  Future<void> fetchDistance() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.99.232/sonar'));
      print(response);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        setState(() {
          distance = response.body;
          parsedDistance = double.tryParse(distance) ?? 0.0;
          parsedDistance = 500 - parsedDistance;
          distance = 'Suyun seviyesi: ${parsedDistance.truncate()} cm';
          _showNotification('Uyarı', 'Su seviyesi şu anda $parsedDistance');
        });
      } else {
        setState(() {
          distance = 'Şuan veri alınamıyor';
        });
      }
    } catch (e) {
      setState(() {
        distance = 'Şuan veri alınamıyor';
      });
    }
  }

  Future<void> _showNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'water_level_channel', 'Water Level Notifications',
        channelDescription: 'notification for water alerts',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
    var iOSPlatformChannelSpecifics = const IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(
        0, title, body, RepeatInterval.hourly, platformChannelSpecifics,
        androidAllowWhileIdle: true, payload: 'item x');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Su Seviyesi'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(275, 600),
              painter: TankPainter(parsedDistance),
            ),
            const SizedBox(height: 20),
            Text(
              distance,
              style: const TextStyle(fontSize: 25),
            ),
          ],
        ),
      ),
    );
  }
}

class TankPainter extends CustomPainter {
  final double waterHeight;

  TankPainter(this.waterHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final double tankWidth = size.width;
    final double tankHeight = size.height;
    final double tankX = (size.width - tankWidth) / 2;
    final double tankY = (size.height - tankHeight) / 2;
    final double radius = tankWidth / 2;

    final tankPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade300, Colors.grey.shade700],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(tankX, tankY, tankWidth, tankHeight));

    final topEllipse = Rect.fromLTWH(tankX, tankY, tankWidth, radius);
    final bottomEllipse =
        Rect.fromLTWH(tankX, tankY + tankHeight - radius, tankWidth, radius);

    canvas.drawOval(topEllipse, tankPaint);
    canvas.drawRect(
        Rect.fromLTWH(
            tankX, tankY + radius / 2, tankWidth, tankHeight - radius),
        tankPaint);
    canvas.drawOval(bottomEllipse, tankPaint);

    final waterPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.shade600.withOpacity(0.5),
          Colors.blue.shade900.withOpacity(0.5)
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(
          tankX, tankY + tankHeight - waterHeight, tankWidth, waterHeight));

    if (waterHeight > 0) {
      final waterBottomEllipse =
          Rect.fromLTWH(tankX, tankY + tankHeight - radius, tankWidth, radius);
      canvas.drawOval(waterBottomEllipse, waterPaint);

      final waterRect = Rect.fromLTWH(tankX, tankY + tankHeight - radius + 75,
          tankWidth, -waterHeight + 30);
      canvas.drawRect(waterRect, waterPaint);

      final waterTopEllipse = Rect.fromLTWH(tankX,
          tankY + tankHeight - radius - waterHeight + 36, tankWidth, radius);
      canvas.drawOval(waterTopEllipse, waterPaint);
    } else if (waterHeight == 0) {
      final waterTopEllipse =
          Rect.fromLTWH(tankX, tankY + tankHeight - radius, tankWidth, radius);
      canvas.drawOval(waterTopEllipse, waterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
