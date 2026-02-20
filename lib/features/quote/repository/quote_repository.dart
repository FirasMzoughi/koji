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

  Future<String> saveQuote(String userId, Map<String, dynamic> quoteData, {String? quoteId}) async {
    _logger.i('💾 [QuoteRepository] Saving quote for user: $userId (Update: ${quoteId != null})');
    try {
      // Extract nested data
      final client = quoteData['client'] as Map<String, dynamic>?;
      final totals = quoteData['totals'] as Map<String, dynamic>?; // Ensure totals is map
      
      // Build metadata
      final metadata = {
        'quoteNumber': quoteData['quoteNumber'],
        'date': quoteData['date'],
        'validity': quoteData['validity'],
        'siteAddress': quoteData['siteAddress'],
        'company': quoteData['company'],
        'totals': totals,
      };
      
      // Build flat data structure
      final data = {
        'user_id': userId,
        'status': quoteData['status'] ?? 'en_cours',
        'created_at': quoteData['createdAt'] ?? DateTime.now().toIso8601String(),
        'client_name': client?['name'],
        'client_email': client?['email'],
        'client_phone': client?['phone'],
        'client_address': client?['address'],
        'rooms': quoteData['expenses'],
        // Store raw tasks map for UI reconstruction if needed, though we allow parsing
        'tasks': quoteData['tasks'], 
        'notes': metadata,
        'total_amount': totals?['ttc'],
      };

      // Generate signature URL logic
      final clientEmail = client?['email'] ?? '';
      final signatureUrl = 'https://koji-signature.vercel.app/?quoteId=\${quoteId ?? "TEMP"}&email=${Uri.encodeComponent(clientEmail)}';
      data['signature_url'] = signatureUrl;

      String finalQuoteId = quoteId ?? '';

      if (quoteId != null) {
        await _supabase.from('quotes').upsert(data);
        finalQuoteId = quoteId;
      } else {
        data.remove('signature_url');
        final response = await _supabase.from('quotes').insert(data).select().single();
        finalQuoteId = response['id'] as String;
        
        // Update signature URL
        final correctSignatureUrl = 'https://koji-signature.vercel.app/?quoteId=$finalQuoteId&email=${Uri.encodeComponent(clientEmail)}';
        await _supabase.from('quotes').update({'signature_url': correctSignatureUrl}).eq('id', finalQuoteId);
      }
      
      // ---------------------------------------------------------
      // AUTO-CREATE PROJECT & TASKS from Quote
      // ---------------------------------------------------------
      try {
        _logger.i('🏗️ [QuoteRepository] Starting auto-creation of project & tasks...');
        
        // 1. Create/Update Project
        final projectData = {
          'user_id': userId, // Explicitly set owner
          'title': "Chantier ${client?['name'] ?? 'Client'}", 
          'client_name': client?['name'] ?? 'Client Inconnu',
          'address': quoteData['siteAddress'] ?? client?['address'],
          'status': 'En Cours',
        };

        _logger.i('📋 [QuoteRepository] Creating project: ${projectData['title']}');
        final projectRes = await _supabase.from('projects').insert(projectData).select().single();
        final projectId = projectRes['id'] as String;
        _logger.i('✅ [QuoteRepository] Project created with ID: $projectId');

        // 2. Insert Tasks (Project Tasks)
        // Parse the expenses structure to extract tasks
        final expensesMap = quoteData['expenses'] as Map<String, dynamic>? ?? {};
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
              _logger.w('   ⚠️ Room $roomId has invalid task data type: ${roomTasksData.runtimeType}');
              return;
            }
            
            final roomTasks = roomTasksData as Map<String, dynamic>;
            final roomName = roomId; // expensesMap entries are Lists, so we can't look up 'name' inside them. Use Key.
            
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
          _logger.i('🔍 [QuoteRepository] No tasks in tasksMap, parsing from expenses...');
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
                final taskName = itemData['title'] ?? itemData['label'] ?? 'Tâche';
                
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
          _logger.i('📝 [QuoteRepository] Inserting ${projectTasksToInsert.length} tasks into project_tasks...');
          await _supabase.from('project_tasks').insert(projectTasksToInsert);
          _logger.i('✅ [QuoteRepository] Successfully inserted ${projectTasksToInsert.length} tasks');
        } else {
          _logger.w('⚠️ [QuoteRepository] No tasks found to insert for project $projectId');
          _logger.w('   Debug info - expensesMap structure: ${expensesMap.toString().substring(0, 200)}...');
          _logger.w('   Debug info - tasksMap structure: ${tasksMap.toString().substring(0, 200)}...');
        }

        _logger.i('✅ [QuoteRepository] Project & Tasks creation completed for Quote: $finalQuoteId');

      } catch (projError, stackTrace) {
        _logger.e('❌ [QuoteRepository] Failed to auto-create project/tasks: $projError');
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
          // Transform flat database structure to nested format expected by UI
          return data.map((quote) {
            // Reconstruct client object from flat columns
            final client = {
              'name': quote['client_name'],
              'email': quote['client_email'],
              'phone': quote['client_phone'],
              'address': quote['client_address'],
            };
            
            // Helper function to safely convert JSONB fields
            Map<String, dynamic> _safeMapConvert(dynamic field) {
              if (field == null) return {};
              if (field is Map<String, dynamic>) return field;
              if (field is Map) return Map<String, dynamic>.from(field);
              return {};
            }
            
            // Get metadata from notes field (contains company, totals, etc.)
            final metadata = _safeMapConvert(quote['notes']);
            final rooms = _safeMapConvert(quote['rooms']);
            final tasks = _safeMapConvert(quote['tasks']);
            
            return {
              'id': quote['id'],
              'status': quote['status'],
              'client': client,
              'quoteNumber': metadata['quoteNumber'] ?? 'N/A',
              'date': metadata['date'] ?? '',
              'validity': metadata['validity'] ?? '',
              'siteAddress': metadata['siteAddress'] ?? '',
              'company': metadata['company'] ?? {},
              'totals': metadata['totals'] ?? {'ht': 0, 'tva': 0, 'ttc': quote['total_amount'] ?? 0},
              'expenses': rooms, // rooms contains expense data
              'tasks': tasks,
            };
          }).toList();
        });
  }
}
