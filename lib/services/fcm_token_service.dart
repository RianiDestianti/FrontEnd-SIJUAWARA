import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skoring/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmTokenService {
  FcmTokenService._internal();

  static final FcmTokenService instance = FcmTokenService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission();
    await _messaging.setAutoInitEnabled(true);

    await _syncTokenWithRetry();

    _messaging.onTokenRefresh.listen((newToken) {
      _sendToken(newToken);
    });
  }

  Future<void> syncToken() async {
    await _syncTokenWithRetry();
  }

  Future<void> _syncTokenWithRetry() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          await _sendToken(token);
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

  Future<void> _sendToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final nip = prefs.getString('walikelas_id') ?? '';
    if (nip.isEmpty) {
      return;
    }

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm-token'),
        headers: {'Accept': 'application/json'},
        body: {
          'nip': nip,
          'token': token,
          'device_name': 'android',
        },
      );
    } catch (_) {
      // Ignore token sync errors to avoid blocking app flow.
    }
  }
}
