import '../utils/easy_home_format.dart';

enum ComplaintStatus { pending, inProgress, resolved }

enum Priority { low, medium, urgent }

class ComplaintModel {
  const ComplaintModel({
    required this.id,
    required this.authorUid,
    required this.flatCode,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.response = '',
  });
  final String id, authorUid, flatCode, title, description, response;
  final ComplaintStatus status;
  final Priority priority;
  final DateTime createdAt;
  String get statusLabel => switch (status) {
    ComplaintStatus.pending => 'অপেক্ষায়',
    ComplaintStatus.inProgress => 'কাজ চলছে',
    ComplaintStatus.resolved => 'সমাধান হয়েছে',
  };
  factory ComplaintModel.fromMap(Map<String, dynamic> m) => ComplaintModel(
    id: m['id'] as String,
    authorUid: m['authorUid'] as String,
    flatCode: m['flatCode'] as String,
    title: m['title'] as String,
    description: m['description'] as String,
    response: m['response'] as String? ?? '',
    status: ComplaintStatus.values.firstWhere((s) => s.name == m['status']),
    priority: Priority.values.firstWhere((s) => s.name == m['priority']),
    createdAt: readDate(m['createdAt']),
  );
}
