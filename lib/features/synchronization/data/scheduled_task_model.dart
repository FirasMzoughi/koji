import 'package:flutter/material.dart';

/// A planned task: a specific worker, on a specific date, at a specific start
/// time, for a specific duration. This is the single source of truth for the
/// contractor's planning view (/planning).
///
/// Optionally linked to a [chantier_task] (the checklist entry it came from).
class ScheduledTask {
  final String id;
  final String userId;
  final String chantierId;
  final String? chantierTaskId;
  final String workerId;
  final String title;
  final String? notes;

  /// Date portion only (time is in [startTime]).
  final DateTime scheduledDate;

  /// "HH:mm" 24-hour format.
  final String startTime;

  final int durationMinutes;

  /// "À faire" | "En cours" | "Terminé" | "Annulé".
  final String status;

  // Joined fields populated by repository select with FK joins — read-only.
  final String? workerFirstName;
  final String? workerLastName;
  final String? workerProfession;
  final String? chantierReference;
  final String? chantierCity;

  const ScheduledTask({
    required this.id,
    required this.userId,
    required this.chantierId,
    this.chantierTaskId,
    required this.workerId,
    required this.title,
    this.notes,
    required this.scheduledDate,
    required this.startTime,
    required this.durationMinutes,
    this.status = 'À faire',
    this.workerFirstName,
    this.workerLastName,
    this.workerProfession,
    this.chantierReference,
    this.chantierCity,
  });

  /// "HH:mm" end time computed from [startTime] + [durationMinutes], clamped
  /// to 23:59 if the task would spill past midnight.
  String get endTime {
    final parts = startTime.split(':');
    final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final end = (startMinutes + durationMinutes).clamp(0, 24 * 60 - 1);
    final h = (end ~/ 60).toString().padLeft(2, '0');
    final m = (end % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay get startTimeOfDay {
    final parts = startTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String get workerFullName {
    final f = workerFirstName ?? '';
    final l = workerLastName ?? '';
    final name = '$f $l'.trim();
    return name.isEmpty ? 'Ouvrier' : name;
  }

  /// True if two tasks assigned to the same worker overlap on the same date.
  /// Used for conflict detection.
  bool overlaps(ScheduledTask other) {
    if (workerId != other.workerId) return false;
    if (scheduledDate.year != other.scheduledDate.year ||
        scheduledDate.month != other.scheduledDate.month ||
        scheduledDate.day != other.scheduledDate.day) {
      return false;
    }
    final a = _toMinutes(startTime);
    final b = _toMinutes(other.startTime);
    return a < b + other.durationMinutes && b < a + durationMinutes;
  }

  static int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    final worker = json['workers'] as Map<String, dynamic>?;
    final chantier = json['chantiers'] as Map<String, dynamic>?;
    return ScheduledTask(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      chantierId: json['chantier_id'] as String,
      chantierTaskId: json['chantier_task_id'] as String?,
      workerId: json['worker_id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      startTime: _normaliseTime(json['start_time'] as String),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      status: json['status'] as String? ?? 'À faire',
      workerFirstName: worker?['first_name'] as String?,
      workerLastName: worker?['last_name'] as String?,
      workerProfession: worker?['profession'] as String?,
      chantierReference: chantier?['reference'] as String?,
      chantierCity: chantier?['city'] as String?,
    );
  }

  /// Postgres TIME can come back as "HH:mm:ss" — we only keep "HH:mm".
  static String _normaliseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'chantier_id': chantierId,
      if (chantierTaskId != null) 'chantier_task_id': chantierTaskId,
      'worker_id': workerId,
      'title': title,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'scheduled_date':
          '${scheduledDate.year.toString().padLeft(4, '0')}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'status': status,
    };
  }

  ScheduledTask copyWith({
    String? title,
    String? notes,
    DateTime? scheduledDate,
    String? startTime,
    int? durationMinutes,
    String? status,
    String? workerId,
    String? chantierId,
    String? chantierTaskId,
  }) {
    return ScheduledTask(
      id: id,
      userId: userId,
      chantierId: chantierId ?? this.chantierId,
      chantierTaskId: chantierTaskId ?? this.chantierTaskId,
      workerId: workerId ?? this.workerId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      workerFirstName: workerFirstName,
      workerLastName: workerLastName,
      workerProfession: workerProfession,
      chantierReference: chantierReference,
      chantierCity: chantierCity,
    );
  }
}

/// Standard duration options shown in the scheduling UI.
class ScheduleDuration {
  static const options = <({String label, int minutes})>[
    (label: '30 min', minutes: 30),
    (label: '1h', minutes: 60),
    (label: '2h', minutes: 120),
    (label: '½ journée', minutes: 240),
    (label: 'Journée', minutes: 480),
  ];

  static String labelFor(int minutes) {
    for (final o in options) {
      if (o.minutes == minutes) return o.label;
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}
