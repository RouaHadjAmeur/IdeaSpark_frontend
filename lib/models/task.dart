enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  final String planId;
  final String title;
  final String description;
  final String? assignedTo;
  final TaskStatus status;
  final DateTime? deadline;
  final String? deliverableId;

  const Task({
    required this.id,
    required this.planId,
    required this.title,
    required this.description,
    this.assignedTo,
    this.status = TaskStatus.todo,
    this.deadline,
    this.deliverableId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    TaskStatus parseStatus(String? status) {
      switch (status) {
        case 'in_progress':
          return TaskStatus.inProgress;
        case 'done':
          return TaskStatus.done;
        default:
          return TaskStatus.todo;
      }
    }

    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      planId: json['planId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedTo: json['assignedTo'],
      status: parseStatus(json['status']),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      deliverableId: json['deliverableId'],
    );
  }

  Map<String, dynamic> toJson() {
    String statusString(TaskStatus s) {
      switch (s) {
        case TaskStatus.inProgress:
          return 'in_progress';
        case TaskStatus.done:
          return 'done';
        default:
          return 'todo';
      }
    }

    return {
      'id': id,
      'planId': planId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'status': statusString(status),
      'deadline': deadline?.toIso8601String(),
      'deliverableId': deliverableId,
    };
  }
}
