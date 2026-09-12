enum ComplaintStatus { pending, inProgress, resolved }

enum Priority { low, medium, urgent }

class ComplaintModel {
  final String id;
  final String tenantId;
  final String title;
  final String description;
  final String? imageUrl;
  final ComplaintStatus status;
  final Priority priority;

  const ComplaintModel({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.priority,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    return ComplaintModel(
      id: map['id'],
      tenantId: map['tenantId'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      status: ComplaintStatus.values.firstWhere((e) => e.name == map['status']),
      priority: Priority.values.firstWhere((e) => e.name == map['priority']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.name,
      'priority': priority.name,
    };
  }
}
