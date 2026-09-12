enum NotificationType { all, floor, flat, emergency }

class NotificationModel {
  final String id;
  final String senderId;
  final NotificationType type;
  final String target;
  final String content;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.senderId,
    required this.type,
    required this.target,
    required this.content,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      senderId: map['senderId'],
      type: NotificationType.values.firstWhere((e) => e.name == map['type']),
      target: map['target'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'type': type.name,
      'target': target,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
