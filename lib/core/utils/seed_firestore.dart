import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Seed the Firestore database with the app's core data structure.
///
/// Call this once after the Firestore database is ready.
/// Example:
///   await seedFirestoreData();
Future<void> seedFirestoreData() async {
  final firestore = FirebaseFirestore.instance;

  await _setDocument(
    firestore.collection('prayer_reminder'),
    'default_schedule',
    {
      'title': 'Prayer Reminder',
      'description': 'Default reminders for daily prayers.',
      'schedule': [
        {'name': 'Fajr', 'time': '05:00', 'enabled': true},
        {'name': 'Dhuhr', 'time': '13:00', 'enabled': true},
        {'name': 'Asr', 'time': '16:30', 'enabled': true},
        {'name': 'Maghrib', 'time': '18:15', 'enabled': true},
        {'name': 'Isha', 'time': '20:30', 'enabled': true},
      ],
      'createdAt': FieldValue.serverTimestamp(),
    },
  );

  await _setDocument(firestore.collection('health_tips'), 'diseases', {
    'data': {
      'ডায়াবেটিস': {
        'eat': ['শাকসবজি', 'ওটস', 'মাছ', 'ডিম', 'বাদাম', 'দই'],
        'avoid': ['চিনি', 'মিষ্টি', 'সাদা চাল', 'ফাস্টফুড'],
        'extra': 'প্রতিদিন ৩০ মিনিট হাঁটুন এবং ডাক্তারের পরামর্শ নিন।',
      },
      'উচ্চ রক্তচাপ': {
        'eat': ['কলা', 'পালং শাক', 'ওটস', 'টমেটো', 'মাছ'],
        'avoid': ['লবণ', 'চিপস', 'প্রক্রিয়াজাত খাবার'],
        'extra': 'দৈনিক পানি পান করুন ও যোগব্যায়াম করুন।',
      },
    },
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('health_tips'), 'daily_tips', {
    'list': [
      'প্রতিদিন সকালে হালকা ব্যায়াম করুন।',
      'সকালে এক গ্লাস পানি পান করুন।',
      '৭–৮ ঘণ্টা ঘুমের লক্ষ্য রাখুন।',
      'রাতে মোবাইল ব্যবহার কমিয়ে দিন।',
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('health_tips'), 'exercises', {
    'list': [
      {'title': 'হালকা হাঁটা', 'description': 'প্রতিদিন ২০–৩০ মিনিট হাঁটুন।'},
      {
        'title': 'স্ট্রেচিং',
        'description': 'ঘুমাতে যাওয়ার আগে ১০ মিনিট স্ট্রেচ করুন।',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('health_tips'), 'quick_tips', {
    'list': [
      {'title': 'পানি পান', 'description': 'সারা দিন পর্যাপ্ত পানি পান করুন।'},
      {
        'title': 'হালাল খাওয়া',
        'description': 'স্বাস্থ্যকর ও হালাল খাবার বেছে নিন।',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('easy_home'), 'flats', {
    'list': [
      {'id': 'flat_101', 'floor': '1', 'unit': 'A', 'code': '101A'},
      {'id': 'flat_102', 'floor': '1', 'unit': 'B', 'code': '101B'},
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('easy_home'), 'tenants', {
    'list': [
      {
        'id': 'tenant_1',
        'userId': 'user_01',
        'flatId': 'flat_101',
        'rentAmount': 6500.0,
        'startDate': '2026-01-01',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('easy_home'), 'rents', {
    'list': [
      {
        'id': 'rent_001',
        'tenantId': 'tenant_1',
        'month': '2026-09',
        'amount': 6500.0,
        'status': 'paid',
        'createdAt': '2026-09-12',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('easy_home'), 'complaints', {
    'list': [
      {
        'id': 'comp_001',
        'tenantId': 'tenant_1',
        'title': 'পানির সমস্যা',
        'description': 'বাথরুমে পানি আসছে না।',
        'status': 'pending',
        'priority': 'urgent',
        'imageUrl': null,
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('easy_home'), 'notifications', {
    'list': [
      {
        'id': 'note_001',
        'message': 'সামাজিক নিরাপত্তা ও পরিচ্ছন্নতা কার্যক্রম শুরু হয়েছে।',
        'type': 'info',
        'createdAt': '2026-09-12',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('easy_home'), 'users', {
    'list': [
      {
        'id': 'user_01',
        'name': 'Demo Tenant',
        'role': 'tenant',
        'email': 'tenant@example.com',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await seedBasicsOfRuqyah();

  await _setDocument(firestore.collection('ruqyah'), 'problems', {
    'list': [
      {
        'title': 'সাধারণ সমস্যা',
        'items': [
          {
            'title': 'মানসিক অস্বস্তি',
            'description': 'নিয়মিত কুরআন তিলাওয়াত ও দোয়া পড়ুন।',
          },
        ],
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('ruqyah'), 'diagnosis', {
    'list': [
      {
        'title': 'রুকইয়াহ ডায়াগনস্টিক',
        'items': [
          {
            'title': 'প্রথম পদক্ষেপ',
            'description': 'ভালোভাবে শারীরিক ও মানসিক অবস্থা পর্যবেক্ষণ করুন।',
          },
        ],
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('ruqyah'), 'daily_adhkar', {
    'list': [
      {
        'title': 'দৈনিক আযকার',
        'items': [
          {
            'title': 'সুবহানাল্লাহ',
            'description': 'প্রতিদিন সওয়াবের জন্য তাসবিহ করুন।',
          },
        ],
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('ruqyah'), 'step_by_step', {
    'list': [
      {
        'title': 'ধাপে ধাপে রুকইয়াহ',
        'items': [
          {
            'title': 'প্রথম ধাপ',
            'description': 'আল্লাহর উপর পূর্ণ ভরসা রাখুন।',
          },
        ],
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('ruqyah'), 'faqs', {
    'list': [
      {
        'title': 'সাধারণ প্রশ্ন',
        'items': [
          {
            'title': 'রুকইয়াহ কি সবসময় করা যাবে?',
            'description': 'হ্যাঁ, তবে সঠিকভাবে এবং আন্তরিকতার সঙ্গে করা উচিত।',
          },
        ],
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('ruqyah'), 'duas', {
    'list': [
      {
        'title': 'আল্লাহর নিকট সাহায্য',
        'arabic': 'اللّهُمَّ اشْفِهِ',
        'translation': 'হে আল্লাহ, তাঁর শিফা দান করুন।',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('ruqyah'), 'free_audios', {
    'list': [
      {
        'title': 'Free Audio Ruqyah',
        'url': 'https://example.com/free-audio.mp3',
        'duration': '05:00',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(firestore.collection('ruqyah'), 'paid_audios', {
    'list': [
      {
        'title': 'Special Audio Ruqyah',
        'url': 'https://example.com/paid-audio.mp3',
        'duration': '08:00',
      },
    ],
    'createdAt': FieldValue.serverTimestamp(),
  });

  await _setDocument(
    firestore.collection('bazzer_reminder'),
    'default_schedule',
    {
      'title': 'Bazar Reminder',
      'description': 'Default Bazar Reminder configuration.',
      'items': [
        {'name': 'Daily Check-in', 'time': '09:00', 'enabled': true},
        {'name': 'Evening Review', 'time': '20:00', 'enabled': true},
      ],
      'createdAt': FieldValue.serverTimestamp(),
    },
  );

  if (kDebugMode) {
    debugPrint('✅ Firestore seed data uploaded successfully.');
  }
}

Future<void> seedBasicsOfRuqyah() async {
  final firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> data = [
    {
      'title': 'রুকইয়াহ কী?',
      'description':
          'রুকইয়াহ শুধুমাত্র কিছু আয়াত বা দোয়া পড়ার নাম নয়; এটি একজন মুমিনের আল্লাহর প্রতি পূর্ণ নির্ভরতা, আত্মশুদ্ধি ও আধ্যাত্মিক চিকিৎসার একটি গুরুত্বপূর্ণ মাধ্যম।',
    },
    {
      'title': 'রুকইয়াহের মৌলিক বিষয়',
      'items': [
        {
          'title': 'আল্লাহই একমাত্র আরোগ্যদাতা',
          'description':
              'রুকইয়াহর প্রথম ও সবচেয়ে গুরুত্বপূর্ণ ভিত্তি হলো এই বিশ্বাস যে প্রকৃত শিফা একমাত্র আল্লাহর পক্ষ থেকেই আসে।',
        },
        {
          'title': 'তাওহীদ ও আল্লাহর উপর ভরসা',
          'description':
              'রুকইয়াহর সফলতার অন্যতম শর্ত হলো বিশুদ্ধ তাওহীদ এবং আল্লাহর উপর পূর্ণ ভরসা।',
        },
      ],
    },
    {
      'title': 'হৃদয়ের পবিত্রতা',
      'items': [
        {
          'title': 'পাপ থেকে বিরত থাকা',
          'description':
              'পাপ মানুষের হৃদয়কে দুর্বল করে এবং আধ্যাত্মিক ক্ষতির কারণ হতে পারে।',
        },
        {
          'title': 'আন্তরিক তওবা',
          'description': 'তওবা হলো হৃদয়ের অন্যতম বড় চিকিৎসা।',
        },
      ],
    },
    {
      'title': 'ইবাদত ও আমল',
      'items': [
        {
          'title': 'নিয়মিত সালাত ও যিকির',
          'description':
              'পাঁচ ওয়াক্ত সালাত, কুরআন তিলাওয়াত ও যিকির একজন মুমিনের আত্মাকে শক্তিশালী করে।',
        },
        {
          'title': 'কুরআন হলো শিফা',
          'description':
              'আল্লাহ কুরআনকে মুমিনদের জন্য শিফা ও রহমত হিসেবে নাযিল করেছেন।',
        },
      ],
    },
  ];

  await _setDocument(firestore.collection('ruqyah'), 'basics_of_ruqyah', {
    'list': data,
  });

  if (kDebugMode) {
    debugPrint('✅ Basics of Ruqyah successfully uploaded.');
  }
}

Future<void> _setDocument(
  CollectionReference<Map<String, dynamic>> collection,
  String docId,
  Map<String, dynamic> data,
) async {
  final document = await collection.doc(docId).get();

  if (document.exists) {
    if (kDebugMode) {
      debugPrint('ℹ️ Skipped existing ${collection.path}/$docId');
    }
    return;
  }

  await collection.doc(docId).set(data);

  if (kDebugMode) {
    debugPrint('✅ Seeded ${collection.path}/$docId');
  }
}
