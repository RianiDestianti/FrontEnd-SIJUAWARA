import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skoring/config/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmTokenService {
  FcmTokenService.internal();

  static final FcmTokenService instance = FcmTokenService.internal();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await messaging.requestPermission();
    await messaging.setAutoInitEnabled(true);

    await syncTokenWithRetry();

    messaging.onTokenRefresh.listen((newToken) {
      sendToken(newToken);
    });
  }

  Future<void> syncToken() async {
    await syncTokenWithRetry();
  }

  Future<void> syncTokenWithRetry() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final token = await messaging.getToken();
        if (token != null) {
          await sendToken(token);
        }
        return;
      } on FirebaseException catch (e) {
        debugPrint(
          'FCM getToken failed (attempt $attempt): ${e.code} ${e.message}',
        );
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        }
      } catch (e) {
        debugPrint('FCM getToken error: $e');
      }
      return;
    }
  }

  Future<void> sendToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final nip = prefs.getString('walikelas_id') ?? '';
    if (nip.isEmpty) {
      return;
    }

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm-token'),
        headers: {'Accept': 'application/json'},
        body: {'nip': nip, 'token': token, 'device_name': 'android'},
      );
    } catch (error) {
      // Ignore token sync errors to avoid blocking app flow.
    }
  }
}
