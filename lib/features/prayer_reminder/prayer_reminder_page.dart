import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/notification_service.dart';

class PrayerReminderPage extends StatefulWidget {
  const PrayerReminderPage({super.key});

  @override
  State<PrayerReminderPage> createState() => _PrayerReminderPageState();
}

class _PrayerReminderPageState extends State<PrayerReminderPage> {
  String currentDistrict = 'ঢাকা';
  final List<String> districts = ['ঢাকা', 'চট্টগ্রাম', 'সিলেট', 'রাজশাহী'];

  final Map<String, Map<String, TimeOfDay>> prayerTimesByDistrict = {
    'ঢাকা': {
      'ফজর': const TimeOfDay(hour: 4, minute: 45),
      'সূর্যোদয়': const TimeOfDay(hour: 6, minute: 5),
      'যোহর': const TimeOfDay(hour: 12, minute: 15),
      'আসর': const TimeOfDay(hour: 15, minute: 40),
      'মাগরিব': const TimeOfDay(hour: 18, minute: 20),
      'এশা': const TimeOfDay(hour: 19, minute: 40),
    },
    'চট্টগ্রাম': {
      'ফজর': const TimeOfDay(hour: 4, minute: 50),
      'সূর্যোদয়': const TimeOfDay(hour: 6, minute: 10),
      'যোহর': const TimeOfDay(hour: 12, minute: 20),
      'আসর': const TimeOfDay(hour: 15, minute: 45),
      'মাগরিব': const TimeOfDay(hour: 18, minute: 25),
      'এশা': const TimeOfDay(hour: 19, minute: 45),
    },
    'সিলেট': {
      'ফজর': const TimeOfDay(hour: 4, minute: 55),
      'সূর্যোদয়': const TimeOfDay(hour: 6, minute: 15),
      'যোহর': const TimeOfDay(hour: 12, minute: 25),
      'আসর': const TimeOfDay(hour: 15, minute: 50),
      'মাগরিব': const TimeOfDay(hour: 18, minute: 30),
      'এশা': const TimeOfDay(hour: 19, minute: 50),
    },
    'রাজশাহী': {
      'ফজর': const TimeOfDay(hour: 4, minute: 40),
      'সূর্যোদয়': const TimeOfDay(hour: 6, minute: 0),
      'যোহর': const TimeOfDay(hour: 12, minute: 10),
      'আসর': const TimeOfDay(hour: 15, minute: 35),
      'মাগরিব': const TimeOfDay(hour: 18, minute: 15),
      'এশা': const TimeOfDay(hour: 19, minute: 35),
    },
  };

  late Map<String, TimeOfDay> prayerTimes = Map.from(
    prayerTimesByDistrict[currentDistrict]!,
  );
  late Map<String, TimeOfDay> reminderTimes = Map.from(prayerTimes);
  final Map<String, bool> reminderEnabled = {};
  String nextPrayer = '';
  Duration remaining = Duration.zero;
  Timer? _timer;
  final _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    for (final name in prayerTimes.keys) {
      reminderEnabled[name] = false;
    }
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    _updateNextPrayer();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateNextPrayer(),
    );
  }

  Future<void> _requestPermissions() async {
    final notif = await Permission.notification.request();

    if (!notif.isGranted) {
      debugPrint("Notification permission denied");
    }

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateNextPrayer() {
    final now = DateTime.now();
    DateTime? nextTime;
    String nextName = '';

    for (var entry in prayerTimes.entries) {
      final t = entry.value;
      final prayerDate = DateTime(
        now.year,
        now.month,
        now.day,
        t.hour,
        t.minute,
      );
      if (prayerDate.isAfter(now)) {
        nextTime = prayerDate;
        nextName = entry.key;
        break;
      }
    }

    if (nextTime == null) {
      final fajr = prayerTimes['ফজর']!;
      nextTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        fajr.hour,
        fajr.minute,
      );
      nextName = 'ফজর';
    }

    if (mounted) {
      setState(() {
        nextPrayer = nextName;
        remaining = nextTime!.difference(now);
      });
    }
  }

  void updatePrayerTimes(String district) {
    setState(() {
      prayerTimes = Map.from(prayerTimesByDistrict[district]!);
      reminderTimes = Map.from(prayerTimes);
      currentDistrict = district;
      reminderEnabled
        ..clear()
        ..addEntries(prayerTimes.keys.map((k) => MapEntry(k, false)));
    });
    _updateNextPrayer();
  }

  String formatTime(TimeOfDay time) {
    final dt = DateTime(0, 0, 0, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _schedulePrayerNotification(
    String prayerName,
    TimeOfDay time,
  ) async {
    try {
      final now = DateTime.now();

      DateTime scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationService.scheduleDailyNotification(
        id: prayerName.hashCode,
        title: 'নামাজের সময় হয়েছে',
        body: '$prayerName ওয়াক্ত শুরু হয়েছে',
        scheduledDate: scheduledDate,
        payload: prayerName,
      );
    } catch (e) {
      debugPrint("Schedule error: $e");

      // ✅ ফিক্স: await এর পর context ব্যবহারের আগে মাউন্টেড চেক
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Notification error")));
    }
  }

  Widget prayerTile(String name) {
    final prayerTime = prayerTimes[name]!;
    final remTime = reminderTimes[name]!;
    return Card(
      color: const Color(0xFF1B1B1B),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Colors.orangeAccent),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          'নামাজ: ${formatTime(prayerTime)} | রিমাইন্ডার: ${formatTime(remTime)}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Switch(
          value: reminderEnabled[name] ?? false,
          onChanged: (value) async {
            try {
              setState(() => reminderEnabled[name] = value);

              if (value) {
                await _schedulePrayerNotification(name, reminderTimes[name]!);
              } else {
                await _notificationService.cancel(name.hashCode);
              }
            } catch (e) {
              debugPrint("Switch error: $e");
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayerTimeStr = nextPrayer.isNotEmpty
        ? formatTime(prayerTimes[nextPrayer]!)
        : '--:--';
    final remainingStr =
        '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        title: const Text('Prayer Reminder'),
        backgroundColor: const Color(0xFF0B0B0B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: currentDistrict,
              dropdownColor: Colors.black,
              items: districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) {
                if (val != null) updatePrayerTimes(val);
              },
            ),
            const SizedBox(height: 20),
            Text(
              '$nextPrayer নামাজ শুরু হবে',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              nextPrayerTimeStr,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'সময় বাকি: $remainingStr',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ...prayerTimes.keys.map(prayerTile),
          ],
        ),
      ),
    );
  }
}
