import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:koji/features/synchronization/data/worker_model.dart';

class WorkerRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Worker>> getWorkers({String? query}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      var dbQuery = _client.from('workers').select().eq('user_id', userId);

      if (query != null && query.isNotEmpty) {
        dbQuery = dbQuery.or(
            'first_name.ilike.%$query%,last_name.ilike.%$query%,profession.ilike.%$query%');
      }

      final response = await dbQuery.order('created_at', ascending: false);

      return (response as List).map((e) => Worker.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch workers: $e');
    }
  }

  Future<Worker> createWorker(Worker worker) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final data = worker.toJson();
      data['user_id'] = userId;

      final response = await _client
          .from('workers')
          .insert(data)
          .select()
          .single();

      return Worker.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create worker: $e');
    }
  }

  Future<void> updateWorker(Worker worker) async {
    try {
      await _client.from('workers').update(worker.toJson()).eq('id', worker.id);
    } catch (e) {
      throw Exception('Failed to update worker: $e');
    }
  }

  Future<String> uploadWorkerImage(File file, String path) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      final storagePath = 'workers/$fileName';

      await _client.storage.from('worker_docs').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl =
          _client.storage.from('worker_docs').getPublicUrl(storagePath);
      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Upload Error: $e');
      }
      throw Exception('Failed to upload image: $e');
    }
  }
}
