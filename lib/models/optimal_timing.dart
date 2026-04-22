class OptimalTiming {
  final List<TimeSlot> bestTimes;
  final List<TimeSlot> worstTimes;

  OptimalTiming({
    required this.bestTimes,
    required this.worstTimes,
  });

  factory OptimalTiming.fromJson(Map<String, dynamic> json) {
    return OptimalTiming(
      bestTimes: (json['bestTimes'] as List?)
              ?.map((e) => TimeSlot.fromJson(e))
              .toList() ??
          [],
      worstTimes: (json['worstTimes'] as List?)
              ?.map((e) => TimeSlot.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TimeSlot {
  final String day;
  final String time;
  final int score;
  final String reason;
  final String? expectedEngagement;

  TimeSlot({
    required this.day,
    required this.time,
    required this.score,
    required this.reason,
    this.expectedEngagement,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      day: json['day'] ?? '',
      time: json['time'] ?? '',
      score: json['score'] ?? 0,
      reason: json['reason'] ?? '',
      expectedEngagement: json['expectedEngagement'],
    );
  }

  String get dayFr {
    const days = {
      'monday': 'Lundi',
      'tuesday': 'Mardi',
      'wednesday': 'Mercredi',
      'thursday': 'Jeudi',
      'friday': 'Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
    };
    return days[day.toLowerCase()] ?? day;
  }
}
