import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService.internal();

  static final NotificationService instance = NotificationService.internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'sp_ph_channel',
        'Notifikasi SP/PH',
        channelDescription: 'Notifikasi SP dan PH',
        importance: Importance.max,
        priority: Priority.high,
      );

  static const AndroidNotificationDetails downloadAndroidDetails =
      AndroidNotificationDetails(
        'download_channel',
        'Notifikasi Unduhan',
        channelDescription: 'Notifikasi unduhan laporan',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  static const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );
  static const NotificationDetails downloadNotificationDetails =
      NotificationDetails(android: downloadAndroidDetails);

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await notificationsPlugin.initialize(initSettings);

    final androidPlugin =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> showNotificationFromMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await notificationsPlugin.show(
      notification.hashCode,
      notification.title ?? 'Notifikasi',
      notification.body ?? '',
      notificationDetails,
      payload: message.data['nis']?.toString(),
    );
  }

  Future<void> showDownloadNotification({
    required String title,
    required String body,
  }) async {
    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      downloadNotificationDetails,
    );
  }
}
