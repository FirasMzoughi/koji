import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:koji/features/quote/model/custom_task.dart';

final taskRepositoryProvider =
    Provider((ref) => TaskRepository(Supabase.instance.client));

class TaskRepository {
  final SupabaseClient _supabase;

  TaskRepository(this._supabase);

  /// Fetch all tasks visible to the current user, assembled as parent→children tree.
  Future<List<CustomTask>> getTasks(String profession) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .order('famille', ascending: true)
          .order('code', ascending: true);

      final all = (response as List).map((e) => CustomTask.fromMap(e)).toList();

      // Deduplicate by id
      final seen = <String>{};
      final unique = all.where((t) => seen.add(t.id)).toList();

      // Build parent→children map
      // Strategy 1: Use parent_id if available
      // Strategy 2: Fallback to code convention (CARSOL-001-01 → parent CARSOL-001)
      final bool hasParentIds = unique.any((t) => t.parentId != null);

      final Map<String, List<CustomTask>> childrenMap = {};

      if (hasParentIds) {
        // DB has parent_id populated
        for (final t in unique) {
          if (t.parentId != null) {
            childrenMap.putIfAbsent(t.parentId!, () => []).add(t);
          }
        }
      } else {
        // Fallback: match by code convention
        // SOUS-POSTEs have codes like CARSOL-001-01, parent is CARSOL-001
        final codeToId = <String, String>{};
        for (final t in unique) {
          if (t.code != null && t.typePoste == 'POSTE') {
            codeToId[t.code!] = t.id;
          }
        }
        for (final t in unique) {
          if (t.code != null && t.typePoste == 'SOUS-POSTE') {
            // Strip last -NN from code to find parent code
            final parentCode = t.code!.replaceAll(RegExp(r'-\d{2}$'), '');
            final parentId = codeToId[parentCode];
            if (parentId != null) {
              childrenMap.putIfAbsent(parentId, () => []).add(t);
            }
          }
        }
      }

      // Attach children to parents, return only top-level tasks
      final parents = unique.where((t) {
        if (hasParentIds) return t.parentId == null;
        return t.typePoste != 'SOUS-POSTE';
      }).map((t) {
        t.subTasks = childrenMap[t.id] ?? [];
        return t;
      }).toList();

      return parents;
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
    String? code,
    String? famille,
    String? unite,
    double? tempsHU,
    String? parentId,
    String? typePoste,
  }) async {
    try {
      // 1. Auto-generate code if this is a sub-task
      String? finalCode = code;
      if (parentId != null && (code == null || code.trim().isEmpty)) {
        // Count existing children to determine next suffix
        final siblings = await _supabase
            .from('tasks')
            .select('id')
            .eq('parent_id', parentId);
        final count = (siblings as List).length + 1;
        // Fetch parent code
        final parentRow = await _supabase
            .from('tasks')
            .select('code')
            .eq('id', parentId)
            .maybeSingle();
        final parentCode = parentRow?['code'] as String? ?? '';
        finalCode = '$parentCode-${count.toString().padLeft(2, '0')}';
      }

      // 2. Upload images
      final List<String> imageUrls = [];
      for (var image in images) {
        final path =
            'task_${DateTime.now().millisecondsSinceEpoch}_${image.path.split(Platform.pathSeparator).last}';
        await _supabase.storage.from('task_images').upload(path, image);
        final url = _supabase.storage.from('task_images').getPublicUrl(path);
        imageUrls.add(url);
      }

      // 3. Insert task
      final taskData = <String, dynamic>{
        'title': title,
        'description': description,
        'profession': profession,
        'image_urls': imageUrls,
        'default_products': defaultProducts,
        'user_id': _supabase.auth.currentUser!.id,
        if (finalCode != null) 'code': finalCode,
        if (famille != null) 'famille': famille,
        if (unite != null) 'unite': unite,
        if (tempsHU != null) 'temps_hu': tempsHU,
        if (parentId != null) 'parent_id': parentId,
        'type_poste': parentId != null ? 'SOUS-POSTE' : (typePoste ?? 'POSTE'),
      };

      final response =
          await _supabase.from('tasks').insert(taskData).select().single();
      return CustomTask.fromMap(response);
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }
}
