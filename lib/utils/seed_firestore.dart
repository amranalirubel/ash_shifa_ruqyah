// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart'; // ← এই লাইনটি নতুন যোগ করুন

// /// ====================== HEALTH TIPS ======================
// Future<void> seedHealthTips() async {
//   final firestore = FirebaseFirestore.instance;

//   // Diseases + Food Map
//   await firestore.collection('health_tips').doc('diseases').set({
//     'data': {
//       'ডায়াবেটিস': {
//         'eat': ['শাকসবজি', 'ওটস', 'মাছ', 'ডিম', 'বাদাম', 'দই', 'ব্রাউন রাইস'],
//         'avoid': ['চিনি', 'মিষ্টি', 'সাদা চাল', 'ফাস্টফুড', 'ফলের জুস'],
//         'extra': 'প্রতিদিন ৩০ মিনিট হাঁটুন + ডাক্তারের পরামর্শ নিন',
//       },
//       'উচ্চ রক্তচাপ': {
//         'eat': ['কলা', 'পালং শাক', 'ওটস', 'মাছ', 'টমেটো', 'রসুন'],
//         'avoid': ['লবণ', 'চিপস', 'প্রক্রিয়াজাত খাবার'],
//         'extra': 'দৈনিক পর্যাপ্ত পানি + যোগাসন করুন',
//       },
//     },
//   });

//   // Daily Tips
//   await firestore.collection('health_tips').doc('daily_tips').set({
//     'list': [
//       'প্রতিদিন সকালে হালকা ব্যায়াম করুন।',
//       'পানি বেশি পান করুন।',
//       '৭–৮ ঘণ্টা ঘুমান।',
//       'রাতে মোবাইল কম ব্যবহার করুন।',
//     ],
//   });

//   debugPrint('✅ Health Tips seeded successfully!');
// }

// /// ====================== EASY HOME ======================
// Future<void> seedEasyHomeData() async {
//   final firestore = FirebaseFirestore.instance;

//   // Flats
//   await firestore.collection('easy_home').doc('flats').set({
//     'list': [
//       {'id': 'flat_101', 'floor': '1', 'unit': 'A', 'code': '101A'},
//       {'id': 'flat_102', 'floor': '1', 'unit': 'B', 'code': '101B'},
//       {'id': 'flat_201', 'floor': '2', 'unit': 'A', 'code': '201A'},
//       {'id': 'flat_202', 'floor': '2', 'unit': 'B', 'code': '201B'},
//     ],
//   });

//   // Tenants
//   await firestore.collection('easy_home').doc('tenants').set({
//     'list': [
//       {
//         'id': 'tenant_1',
//         'userId': 'user_abc123',
//         'flatId': 'flat_101',
//         'rentAmount': 6500.0,
//         'startDate': '2026-01-01',
//       },
//       {
//         'id': 'tenant_2',
//         'userId': 'user_xyz789',
//         'flatId': 'flat_102',
//         'rentAmount': 7200.0,
//         'startDate': '2026-02-01',
//       },
//     ],
//   });

//   // Rents
//   await firestore.collection('easy_home').doc('rents').set({
//     'list': [
//       {
//         'id': 'rent_001',
//         'tenantId': 'tenant_1',
//         'month': '2026-03',
//         'amount': 6500.0,
//         'status': 'due',
//         'createdAt': DateTime.now().toIso8601String(),
//       },
//       {
//         'id': 'rent_002',
//         'tenantId': 'tenant_2',
//         'month': '2026-03',
//         'amount': 7200.0,
//         'status': 'paid',
//         'createdAt': DateTime.now().toIso8601String(),
//       },
//     ],
//   });

//   // Complaints
//   await firestore.collection('easy_home').doc('complaints').set({
//     'list': [
//       {
//         'id': 'comp_001',
//         'tenantId': 'tenant_1',
//         'title': 'পানির সমস্যা',
//         'description': 'বাথরুমে পানি আসছে না',
//         'status': 'pending',
//         'priority': 'urgent',
//         'imageUrl': null,
//       },
//     ],
//   });

//   debugPrint('✅ EasyHome data seeded successfully!');
// }
