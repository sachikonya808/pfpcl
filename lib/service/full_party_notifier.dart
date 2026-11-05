import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FPNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'fp_alert_v1', 
    'Full Party Alert',
    description: 'Alerts when the party reaches its max player count',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('full_party')
  );

  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      )
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(_channel);
  }

  Future<void> show(String title, String body) {
    return _plugin.show(
      id: 808,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, 
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          sound: _channel.sound
        )
      )
    );
  }
}