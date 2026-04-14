import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:koji/features/quote/model/custom_task.dart';

final taskRepositoryProvider =
    Provider((ref) => TaskRepository(Supabase.instance.client));

class TaskRepository {
  final SupabaseClient _supabase;

  TaskRepository(this._supabase);

  /// Fetch ALL tasks for a profession from the backend:
  /// - Global/admin tasks (no user_id or shared)
  /// - The current user's own custom tasks
  Future<List<CustomTask>> getTasks(String profession) async {
    try {
      // Fetch tasks matching the profession (all users see them via RLS or public)
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('profession', profession)
          .order('created_at', ascending: true);

      final all = (response as List).map((e) => CustomTask.fromMap(e)).toList();

      // Deduplicate by id
      final seen = <String>{};
      return all.where((t) => seen.add(t.id)).toList();
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<CustomTask> createTask({
    required String title,
    String? description,
    required String profession,
    List<File> images = const [],
    Map<String, dynamic> defaultProducts = const {},
  }) async {
    try {
      // 1. Upload Images
      final List<String> imageUrls = [];
      for (var image in images) {
        final path =
            'task_${DateTime.now().millisecondsSinceEpoch}_${image.path.split(Platform.pathSeparator).last}';
        await _supabase.storage.from('task_images').upload(path, image);
        final url = _supabase.storage.from('task_images').getPublicUrl(path);
        imageUrls.add(url);
      }

      // 2. Insert Task
      final taskData = {
        'title': title,
        'description': description,
        'profession': profession,
        'image_urls': imageUrls,
        'default_products': defaultProducts,
        'user_id': _supabase.auth.currentUser!.id,
      };

      final response =
          await _supabase.from('tasks').insert(taskData).select().single();
      return CustomTask.fromMap(response);
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }
}
