import 'package:koji/features/synchronization/data/project_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Project>> fetchProjects() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('projects')
          .select()
          .eq('user_id', userId) // Explicit filter
          .order('created_at', ascending: false);

      return (response as List).map((e) => Project.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  Future<List<ProjectAssignment>> fetchAssignmentsForProject(
      String projectId) async {
    try {
      final response = await _client
          .from('project_assignments')
          .select()
          .eq('project_id', projectId);

      return (response as List)
          .map((e) => ProjectAssignment.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch assignments: $e');
    }
  }

  Future<void> assignWorkersToProject(
      String projectId, List<String> workerIds) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      final updates = workerIds
          .map((workerId) => {
                'user_id': userId,
                'project_id': projectId,
                'worker_id': workerId,
                'assigned_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _client.from('project_assignments').insert(updates);
    } catch (e) {
      throw Exception('Failed to assign workers: $e');
    }
  }

  Future<void> removeWorkerAssignment(String projectId, String workerId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      await _client
          .from('project_assignments')
          .delete()
          .eq('project_id', projectId)
          .eq('worker_id', workerId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove worker assignment: $e');
    }
  }

  Future<List<TaskItem>> fetchProjectTasks(String projectId) async {
    try {
      final response = await _client
          .from('project_tasks')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => TaskItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch project tasks: $e');
    }
  }

  Future<void> createDummyProject() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('projects').insert({
      'user_id': userId,
      'title': 'Rénovation Appartement T3',
      'client_name': 'M. Robert Durand',
      'address': '12 Rue des Lilas, 75011 Paris',
      'status': 'En Cours',
      'image_url':
          'https://images.unsplash.com/photo-1503387762-592deb58ef4e?q=80&w=2831&auto=format&fit=crop',
    });

    await _client.from('projects').insert({
      'user_id': userId,
      'title': 'Construction Bureau',
      'client_name': 'Mme. Claire Martin',
      'address': '45 Avenue des Champs-Élysées, 75008 Paris',
      'status': 'Terminé',
      'image_url':
          'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=2301&auto=format&fit=crop',
    });
  }

  Future<List<TaskItem>> fetchUserPlanning(DateTime date) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // Fetch tasks assigned to user
      // Since we don't have date column, we'll fetch all 'À Faire' or 'En Cours'
      final response = await _client
          .from('project_tasks')
          .select()
          .eq('user_id', userId)
          //.neq('status', 'Terminé') // Optional: filter completed
          .order('created_at', ascending: false);

      return (response as List).map((e) => TaskItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch planning: $e');
    }
  }

  Future<void> updateTaskSchedule(
      String taskId, DateTime date, String startTime, String duration) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      // Update scheduled_date and details needed for Planning
      // We will perform a simple update for now.
      // Ideally we should merge 'details' but Supabase update replaces the column value.
      await _client.from('project_tasks').update({
        'scheduled_date': date.toIso8601String(),
        'details': {
          'start_time': startTime,
          'duration': duration,
        }
      }).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task schedule: $e');
    }
  }

  Future<void> updateTaskScheduleAdvanced(
    String taskId, {
    required DateTime startDate,
    required DateTime endDate,
    required String startTime,
    required String endTime,
    String? workerId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      final updateData = {
        'scheduled_date': startDate
            .toIso8601String(), // Keep for legacy/simple view compatibility
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'start_time': startTime,
        'end_time': endTime,
        // Calculate duration? Optional.
        'details': {
          'start_time': startTime,
          'end_time': endTime,
        }
      };

      if (workerId != null) {
        updateData['user_id'] =
            userId; // Ensure we keep owner but maybe add assigned_worker_id column?
        // Wait, schema says worker_id. Let's use worker_id.
        updateData['worker_id'] = workerId;
      }

      await _client.from('project_tasks').update(updateData).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task schedule: $e');
    }
  }
}
