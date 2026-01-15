import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:skoring/screens/introduction/onboarding.dart';
import 'package:skoring/screens/walikelas/home.dart';
import 'package:skoring/firebase/notification.dart';
import 'package:skoring/firebase/tokenfcm.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((message) {
    NotificationService.instance.showNotificationFromMessage(message);
  });

  await NotificationService.instance.init();
  await FcmTokenService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skoring App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/introduction',
      routes: {
        '/introduction': (context) => const IntroductionScreen(),
        '/walikelas': (context) => const WalikelasMainScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const IntroductionScreen(),
        );
      },
    );
  }
}
