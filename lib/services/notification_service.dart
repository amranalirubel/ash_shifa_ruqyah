import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    // flutter_local_notifications 17.x: initialize() uses
    // InitializationSettings as the first positional argument.
    await plugin.initialize(initializationSettings);

    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // Prayer Reminder-এর existing API রাখা হয়েছে।
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _scheduleDaily(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      channelId: 'prayer_reminder_channel',
      channelName: 'Prayer Reminder',
      channelDescription: 'Daily prayer reminder notification',
      payload: payload,
    );
  }

  // Mom & Child Care medicine reminder এবং future generic daily reminder.
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    required String channelName,
    String channelDescription = 'Daily reminder notification',
    String? payload,
  }) async {
    await _scheduleDaily(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      payload: payload,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? payload,
  }) async {
    await initialize();

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    // flutter_local_notifications 17.x:
    // first 5 arguments are positional.
    await plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    // flutter_local_notifications 17.x: cancel() takes id positionally.
    await plugin.cancel(id);
  }
}
