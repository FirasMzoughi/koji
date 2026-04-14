import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:koji/core/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(SupabaseConfig.client);
});

class QuoteRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger();

  QuoteRepository(this._supabase);

  Future<String> saveQuote(String userId, Map<String, dynamic> quoteData,
      {String? quoteId}) async {
    _logger.i(
        '💾 [QuoteRepository] Saving quote for user: $userId (Update: ${quoteId != null})');
    try {
      final client = quoteData['client'] as Map<String, dynamic>?;
      final company = quoteData['company'] as Map<String, dynamic>?;
      final totals = quoteData['totals'] as Map<String, dynamic>?;
      
      // Build metadata to persist Snapshot of Client/Company at time of quoting
      final metadata = {
        'quoteNumber': quoteData['quoteNumber'],
        'date': quoteData['date'],
        'validity': quoteData['validity'],
        'siteAddress': quoteData['siteAddress'],
        'company': company,
        'client': client, // We store the whole client snapshot too just in case
      };
      
      // 1. Insert or Update QUOTE
      final quoteDbData = {
        'user_id': userId,
        'chantier_id': quoteData['chantier_id'], // Requires passing chantier_id in quoteData
        'status': quoteData['status'] ?? 'Draft',
        'reference': quoteData['quoteNumber'] ?? 'REF-${DateTime.now().millisecondsSinceEpoch}',
        'total_ht': totals?['ht'] ?? 0,
        'total_ttc': totals?['ttc'] ?? 0,
        'tva_rate': (totals?['tva'] != null && totals?['ht'] != null && totals?['ht'] > 0) 
            ? ((totals!['tva'] / totals['ht']) * 100).round() 
            : 20.0,
        'metadata': metadata,
        'updated_at': DateTime.now().toIso8601String(),
      };

      String finalQuoteId = quoteId ?? '';

      if (quoteId != null && quoteId.isNotEmpty) {
        quoteDbData['id'] = quoteId;
        await _supabase.from('quotes').upsert(quoteDbData);
        finalQuoteId = quoteId;
      } else {
        // If chantier_id is not provided but we need it for Foreign Key, we must create a Chantier first or use a dummy
        if (quoteDbData['chantier_id'] == null) {
          final chantierData = {
            'user_id': userId,
            'reference': quoteDbData['reference'] ?? 'CH-${DateTime.now().millisecondsSinceEpoch}',
            'status': 'En Cours',
          };
          try {
            _logger.i('=> Inserting chantier data: $chantierData');
            final chantierRes = await _supabase.from('chantiers').insert(chantierData).select().single();
            quoteDbData['chantier_id'] = chantierRes['id'];
          } catch(e) {
            _logger.e('Failed on chantiers insert: $e');
            rethrow;
          }
        }

        try {
           final response = await _supabase.from('quotes').insert(quoteDbData).select().single();
           finalQuoteId = response['id'] as String;
        } catch(e) {
           _logger.e('Failed on quotes insert: $e');
           rethrow;
        }
      }

      // Generate signature URL and store in metadata (or it could be its own table later)
      final clientEmail = client?['email'] ?? '';
      final signatureUrl =
          'https://koji-signature.vercel.app/?quoteId=$finalQuoteId'
          '&email=${Uri.encodeComponent(clientEmail)}';
      
      // We'll trigger an update for the metadata's signature link
      metadata['signature_url'] = signatureUrl;
      await _supabase.from('quotes').update({'metadata': metadata}).eq('id', finalQuoteId);

      // 2. Insert QUOTE ROOMS & Tasks
      // First, delete old rooms/tasks if updating
      if (quoteId != null) {
         await _supabase.from('quote_rooms').delete().eq('quote_id', finalQuoteId);
      }

      final expensesMap = quoteData['expenses'] as Map<String, dynamic>? ?? {};
      final tasksMap = quoteData['tasks'] as Map<String, dynamic>? ?? {};

      int roomOrder = 0;
      for (var entry in expensesMap.entries) {
        final roomId = entry.key;
        final roomItems = entry.value as List<dynamic>;

        // Insert Room
        final roomDbData = {
          'quote_id': finalQuoteId,
          'name': roomId,
          'room_order': roomOrder++,
        };
        final roomRes = await _supabase.from('quote_rooms').insert(roomDbData).select().single();
        final insertedRoomId = roomRes['id'] as String;

        // Insert Tasks for this Room
        // We will combine data from expenses array and tasksMap
        final roomTaskDetailsMap = (tasksMap[roomId] as Map<String, dynamic>?) ?? {};

        for (var item in roomItems) {
           final expenseItem = item as Map<String, dynamic>;
           final taskId = expenseItem['id'];
           final detail = roomTaskDetailsMap[taskId] as Map<String, dynamic>? ?? {};

           final taskDbData = {
             'room_id': insertedRoomId,
             'task_id': taskId,
             'label': expenseItem['title'],
             'inputs': detail['inputs'] ?? {},
             'selected_products': detail['selectedProducts'] ?? {},
             'note': detail['note'] ?? expenseItem['subtitle'] ?? '',
             'photo_paths': detail['photoPaths'] ?? [],
             'unit_price_ht': expenseItem['laborCost'],
             'total_price_ht': expenseItem['materialCost'], // We'll store both in the record
             'is_custom': false,
           };
           await _supabase.from('quote_tasks').insert(taskDbData);
        }
      }

      // ---------------------------------------------------------
      // AUTO-CREATE PROJECT & TASKS from Quote
      // ---------------------------------------------------------
      try {
        _logger.i(
            '🏗️ [QuoteRepository] Starting auto-creation of project & tasks...');

        // 1. Create/Update Project
        final projectData = {
          'user_id': userId, // Explicitly set owner
          'client_name': client?['name'] ?? 'Client Inconnu',
          'address': quoteData['siteAddress'] ?? client?['address'],
          'status': 'En Cours',
        };

        _logger.i(
            '📋 [QuoteRepository] Creating project: ${projectData['client_name']}');
        final projectRes = await _supabase
            .from('projects')
            .insert(projectData)
            .select()
            .single();
        final projectId = projectRes['id'] as String;
        _logger.i('✅ [QuoteRepository] Project created with ID: $projectId');

        // 2. Insert Tasks (Project Tasks)
        // Parse the expenses structure to extract tasks
        final expensesMap =
            quoteData['expenses'] as Map<String, dynamic>? ?? {};
        final tasksMap = quoteData['tasks'] as Map<String, dynamic>? ?? {};

        _logger.i('📊 [QuoteRepository] Data structure analysis:');
        _logger.i('   - Expenses rooms: ${expensesMap.keys.length}');
        _logger.i('   - Tasks map keys: ${tasksMap.keys.length}');

        List<Map<String, dynamic>> projectTasksToInsert = [];

        // Strategy 1: Try to parse from 'tasks' map (rich task data with products)
        if (tasksMap.isNotEmpty) {
          _logger.i('🔍 [QuoteRepository] Parsing tasks from tasksMap...');
          tasksMap.forEach((roomId, roomTasksData) {
            if (roomTasksData is! Map) {
              _logger.w(
                  '   ⚠️ Room $roomId has invalid task data type: ${roomTasksData.runtimeType}');
              return;
            }

            final roomTasks = roomTasksData as Map<String, dynamic>;
            final roomName =
                roomId; // expensesMap entries are Lists, so we can't look up 'name' inside them. Use Key.

            _logger.i('   📁 Room: $roomName (${roomTasks.length} tasks)');

            roomTasks.forEach((taskId, taskData) {
              if (taskData is! Map) {
                _logger.w('      ⚠️ Task $taskId has invalid data type');
                return;
              }

              final tData = taskData as Map<String, dynamic>;
              final taskName = tData['label'] ?? tData['taskId'] ?? 'Tâche';

              projectTasksToInsert.add({
                'user_id': userId,
                'project_id': projectId,
                'task_name': taskName,
                'room_name': roomName,
                'status': 'À Faire',
                'details': tData,
              });

              _logger.i('      ✓ Added task: $taskName');
            });
          });
        }

        // Strategy 2: Fallback to parsing from 'expenses' if no tasks found
        if (projectTasksToInsert.isEmpty && expensesMap.isNotEmpty) {
          _logger.i(
              '🔍 [QuoteRepository] No tasks in tasksMap, parsing from expenses...');
          expensesMap.forEach((roomId, roomData) {
            if (roomData is! Map) {
              _logger.w('   ⚠️ Room $roomId has invalid data type');
              return;
            }

            final rData = roomData as Map<String, dynamic>;
            final roomName = rData['name'] ?? roomId;

            // Check if room has tasks or items
            final items = rData['tasks'] ?? rData['items'] ?? [];

            if (items is List && items.isNotEmpty) {
              _logger.i('   📁 Room: $roomName (${items.length} items)');

              for (var item in items) {
                if (item is! Map) continue;
                final itemData = item as Map<String, dynamic>;
                final taskName =
                    itemData['title'] ?? itemData['label'] ?? 'Tâche';

                projectTasksToInsert.add({
                  'user_id': userId,
                  'project_id': projectId,
                  'task_name': taskName,
                  'room_name': roomName,
                  'status': 'À Faire',
                  'details': itemData,
                });

                _logger.i('      ✓ Added task: $taskName');
              }
            } else if (items is Map) {
              _logger.i('   📁 Room: $roomName (${items.length} tasks)');

              items.forEach((taskId, taskData) {
                if (taskData is! Map) return;
                final tData = taskData as Map<String, dynamic>;
                final taskName = tData['label'] ?? tData['title'] ?? 'Tâche';

                projectTasksToInsert.add({
                  'user_id': userId,
                  'project_id': projectId,
                  'task_name': taskName,
                  'room_name': roomName,
                  'status': 'À Faire',
                  'details': tData,
                });

                _logger.i('      ✓ Added task: $taskName');
              });
            }
          });
        }

        if (projectTasksToInsert.isNotEmpty) {
          _logger.i(
              '📝 [QuoteRepository] Inserting ${projectTasksToInsert.length} tasks into project_tasks...');
          await _supabase.from('project_tasks').insert(projectTasksToInsert);
          _logger.i(
              '✅ [QuoteRepository] Successfully inserted ${projectTasksToInsert.length} tasks');
        } else {
          _logger.w(
              '⚠️ [QuoteRepository] No tasks found to insert for project $projectId');
          _logger.w(
              '   Debug info - expensesMap structure: ${expensesMap.toString().substring(0, 200)}...');
          _logger.w(
              '   Debug info - tasksMap structure: ${tasksMap.toString().substring(0, 200)}...');
        }

        _logger.i(
            '✅ [QuoteRepository] Project & Tasks creation completed for Quote: $finalQuoteId');
      } catch (projError, stackTrace) {
        _logger.e(
            '❌ [QuoteRepository] Failed to auto-create project/tasks: $projError');
        _logger.e('Stack trace: $stackTrace');
        // Don't fail the quote save just because project auto-creation failed, but log it.
      }

      return finalQuoteId;
    } catch (e) {
      _logger.e('❌ [QuoteRepository] Failed to save quote', error: e);
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getUserQuotes(String userId) {
    return _supabase
        .from('quotes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          // Transform new flat structure back to UI expected format
          return data.map((quote) {
            
            // Helper function to safely convert JSONB fields
            Map<String, dynamic> _safeMapConvert(dynamic field) {
              if (field == null) return {};
              if (field is Map<String, dynamic>) return field;
              if (field is Map) return Map<String, dynamic>.from(field);
              return {};
            }

            final metadata = _safeMapConvert(quote['metadata']);
            final client = _safeMapConvert(metadata['client']);

            return {
              'id': quote['id'],
              'status': quote['status'] ?? 'Draft',
              'client': client,
              'quoteNumber': metadata['quoteNumber'] ?? quote['reference'] ?? 'N/A',
              'date': metadata['date'] ?? '',
              'validity': metadata['validity'] ?? '',
              'siteAddress': metadata['siteAddress'] ?? '',
              'company': metadata['company'] ?? {},
              'totals': {
                'ht': quote['total_ht'] ?? 0, 
                'tva': ((quote['total_ht'] ?? 0) * (quote['tva_rate'] ?? 20) / 100), 
                'ttc': quote['total_ttc'] ?? 0
              },
              // Since rooms/tasks are fetched later, keep them empty here for the list view
              'expenses': {},
              'tasks': {},
            };
          }).toList();
        });
  }

  /// Update Quote Status
  Future<void> updateQuoteStatus(String quoteId, String status) async {
    await _supabase.from('quotes').update({'status': status}).eq('id', quoteId);
  }
}
