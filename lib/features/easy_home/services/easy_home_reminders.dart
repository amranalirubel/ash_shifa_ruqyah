import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Opt-in Android reminder with no personal or financial data on the lock screen.
class EasyHomeReminders {
  EasyHomeReminders._();
  static final instance = EasyHomeReminders._();
  static const notificationId = 864201;
  static const _ownerKey = 'easy_home_reminder_owner';
  final _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<User?>? _auth;
  Future<void> _queue = Future.value();
  bool _initialized = false;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void bind() {
    if (!supported || _auth != null) return;
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      _queue = _queue
          .then((_) => _restore(user?.uid))
          .catchError((Object _) {});
    });
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  Future<void> _restore(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_ownerKey);
    if (previous != null && previous != uid) {
      await _initialize();
      await _plugin.cancel(id: notificationId);
      await prefs.remove(_ownerKey);
    }
    if (uid == null || FirebaseAuth.instance.currentUser?.uid != uid) return;
    final day = prefs.getInt('easy_home_reminder_$uid');
    if (day != null) await _schedule(uid, day);
  }

  Future<void> setDay(int day) async {
    if (!supported)
      throw StateError(
        'এই ডিভাইসে মাসিক স্মরণ সমর্থিত নয়। অ্যাপের বকেয়া তালিকা ব্যবহার করুন।',
      );
    if (day < 1 || day > 28) throw ArgumentError('১–২৮ তারিখ নির্বাচন করুন।');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('আগে লগইন করুন।');
    bind();
    final operation = _queue.then((_) async {
      await _initialize();
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _schedule(uid, day);
      await (await SharedPreferences.getInstance()).setInt(
        'easy_home_reminder_$uid',
        day,
      );
    });
    _queue = operation.catchError((Object _) {});
    await operation;
  }

  Future<void> disable() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final operation = _queue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (uid != null) await prefs.remove('easy_home_reminder_$uid');
      await _initialize();
      await _plugin.cancel(id: notificationId);
      await prefs.remove(_ownerKey);
    });
    _queue = operation.catchError((Object _) {});
    await operation;
  }

  Future<void> _schedule(String uid, int day) async {
    if (FirebaseAuth.instance.currentUser?.uid != uid)
      throw StateError('অ্যাকাউন্ট বদলে গেছে। আবার চেষ্টা করুন।');
    await _initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.areNotificationsEnabled() != true)
      throw StateError('ফোনের সেটিংসে অ্যাপের নোটিফিকেশন চালু করুন।');
    final location = tz.getLocation('Asia/Dhaka');
    final now = tz.TZDateTime.now(location);
    var next = tz.TZDateTime(location, now.year, now.month, day, 9);
    if (!next.isAfter(now))
      next = tz.TZDateTime(location, now.year, now.month + 1, day, 9);
    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'EasyHome • ভাড়ার সময়',
      body: 'এই মাসের ভাড়া ও জমার হিসাব দেখে নিন।',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'easy_home_rent',
          'EasyHome rent reminders',
          channelDescription: 'Monthly rent reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      await _plugin.cancel(id: notificationId);
      throw StateError('অ্যাকাউন্ট বদলে গেছে। আবার চেষ্টা করুন।');
    }
    await (await SharedPreferences.getInstance()).setString(_ownerKey, uid);
  }
}
