import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/core/supabase_config.dart';
import 'package:koji/features/synchronization/data/scheduled_task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final scheduledTaskRepositoryProvider = Provider<ScheduledTaskRepository>(
  (ref) => ScheduledTaskRepository(SupabaseConfig.client),
);

/// Fetches every scheduled task for the current user on a given day, with
/// worker + chantier fields joined for display.
final scheduledTasksForDayProvider =
    FutureProvider.family<List<ScheduledTask>, DateTime>((ref, day) async {
  final repo = ref.watch(scheduledTaskRepositoryProvider);
  return repo.fetchForDate(day);
});

final scheduledTasksForChantierProvider =
    FutureProvider.family<List<ScheduledTask>, String>((ref, chantierId) async {
  final repo = ref.watch(scheduledTaskRepositoryProvider);
  return repo.fetchForChantier(chantierId);
});

class ScheduledTaskRepository {
  final SupabaseClient _client;

  ScheduledTaskRepository(this._client);

  /// Select with nested reads on the worker and chantier FKs so the UI gets
  /// everything it needs in one round-trip (same pattern as
  /// lib/features/calendar/data/calendar_repository.dart).
  static const _selectWithJoins = '''
*,
workers ( first_name, last_name, profession ),
chantiers ( reference, city )
''';

  Future<ScheduledTask> create(ScheduledTask task) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final payload = task.toInsertJson();
    payload['user_id'] = userId;

    final row = await _client
        .from('scheduled_tasks')
        .insert(payload)
        .select(_selectWithJoins)
        .single();

    return ScheduledTask.fromJson(row);
  }

  Future<ScheduledTask> update(ScheduledTask task) async {
    final payload = task.toInsertJson()
      ..remove('user_id'); // immutable after insert

    final row = await _client
        .from('scheduled_tasks')
        .update(payload)
        .eq('id', task.id)
        .select(_selectWithJoins)
        .single();

    return ScheduledTask.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('scheduled_tasks').delete().eq('id', id);
  }

  Future<ScheduledTask?> fetchById(String id) async {
    final rows = await _client
        .from('scheduled_tasks')
        .select(_selectWithJoins)
        .eq('id', id)
        .limit(1);
    if (rows.isEmpty) return null;
    return ScheduledTask.fromJson(rows.first);
  }

  Future<List<ScheduledTask>> fetchForDate(DateTime day) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final dateStr = _dateOnly(day);

    final rows = await _client
        .from('scheduled_tasks')
        .select(_selectWithJoins)
        .eq('user_id', userId)
        .eq('scheduled_date', dateStr)
        .order('start_time', ascending: true);

    return (rows as List)
        .map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScheduledTask>> fetchForWorker(
      String workerId, DateTime day) async {
    final dateStr = _dateOnly(day);
    final rows = await _client
        .from('scheduled_tasks')
        .select(_selectWithJoins)
        .eq('worker_id', workerId)
        .eq('scheduled_date', dateStr)
        .order('start_time', ascending: true);

    return (rows as List)
        .map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ScheduledTask>> fetchForChantier(String chantierId) async {
    final rows = await _client
        .from('scheduled_tasks')
        .select(_selectWithJoins)
        .eq('chantier_id', chantierId)
        .order('scheduled_date', ascending: true)
        .order('start_time', ascending: true);

    return (rows as List)
        .map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Range fetch for month-level stats (e.g. planning month view totals).
  Future<List<ScheduledTask>> fetchForRange(
      DateTime from, DateTime to) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('scheduled_tasks')
        .select(_selectWithJoins)
        .eq('user_id', userId)
        .gte('scheduled_date', _dateOnly(from))
        .lte('scheduled_date', _dateOnly(to))
        .order('scheduled_date', ascending: true)
        .order('start_time', ascending: true);

    return (rows as List)
        .map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the first existing scheduled task that overlaps with the
  /// proposed slot, or `null` if the worker is free.
  Future<ScheduledTask?> checkConflict({
    required String workerId,
    required DateTime date,
    required String startTime,
    required int durationMinutes,
    String? excludeTaskId,
  }) async {
    final existing = await fetchForWorker(workerId, date);
    final probe = ScheduledTask(
      id: '__probe__',
      userId: '',
      chantierId: '',
      workerId: workerId,
      title: '',
      scheduledDate: date,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );
    for (final t in existing) {
      if (excludeTaskId != null && t.id == excludeTaskId) continue;
      if (probe.overlaps(t)) return t;
    }
    return null;
  }

  static String _dateOnly(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
