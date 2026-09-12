import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  static Future scheduleNotification(
    int id,
    String title,
    String body,
    DateTime time,
  ) async {
    try {
      final scheduledTime = tz.TZDateTime.from(time, tz.local);

      // ❗ past time skip
      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint("Schedule Error: $e");
    }
  }
}
