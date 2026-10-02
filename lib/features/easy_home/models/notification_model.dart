import '../utils/easy_home_format.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.senderId,
    required this.audience,
    required this.content,
    required this.createdAt,
    this.emergency = false,
  });
  final String id, senderId, audience, content;
  final bool emergency;
  final DateTime createdAt;
  factory NotificationModel.fromMap(Map<String, dynamic> m) =>
      NotificationModel(
        id: m['id'] as String,
        senderId: m['senderId'] as String,
        audience: m['audience'] as String,
        content: m['content'] as String,
        emergency: m['emergency'] == true,
        createdAt: readDate(m['createdAt']),
      );
}
