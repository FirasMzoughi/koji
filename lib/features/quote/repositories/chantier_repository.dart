import 'package:supabase_flutter/supabase_flutter.dart';

class ChantierRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ────────────────────────────────────────────────────────
  // 1. Chantiers
  // ────────────────────────────────────────────────────────

  /// Create a new chantier and its initial budget row
  Future<String> createChantier(Map<String, dynamic> data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Insert the Chantier
    final chantierResponse = await _client
        .from('chantiers')
        .insert({
          'user_id': userId,
          'reference': data['reference'],
          'street': data['street'],
          'postal_code': data['postalCode'],
          'city': data['city'],
          'property_type': data['propertyType'],
          'status': 'En attente',
        })
        .select('id')
        .single();

    final chantierId = chantierResponse['id'] as String;

    // 2. Insert the empty Budget row for this chantier
    await _client.from('chantier_budgets').insert({
      'chantier_id': chantierId,
      'main_oeuvre_real': 0,
      'main_oeuvre_estimated': 0,
      'fourniture_real': 0,
      'fourniture_estimated': 0,
    });

    return chantierId;
  }

  /// Get all chantiers for the current user
  Future<List<Map<String, dynamic>>> getChantiers() async {
    final response = await _client
        .from('chantiers')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Stream all chantiers for the current user (real-time)
  Stream<List<Map<String, dynamic>>> streamChantiers(String userId) {
    return _client
        .from('chantiers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // ────────────────────────────────────────────────────────
  // 2. Tasks (À faire)
  // ────────────────────────────────────────────────────────

  /// Fetch tasks for a specific chantier
  Future<List<Map<String, dynamic>>> getTasks(String chantierId) async {
    final response = await _client
        .from('chantier_tasks')
        .select()
        .eq('chantier_id', chantierId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Stream tasks for a specific chantier (real-time)
  Stream<List<Map<String, dynamic>>> streamTasks(String chantierId) {
    return _client
        .from('chantier_tasks')
        .stream(primaryKey: ['id'])
        .eq('chantier_id', chantierId)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Add a new task (À faire)
  Future<void> addTask(String chantierId, String label) async {
    await _client.from('chantier_tasks').insert({
      'chantier_id': chantierId,
      'label': label,
      'is_done': false,
    });
  }

  /// Toggle a task\'s done status
  Future<void> updateTaskStatus(String taskId, bool isDone) async {
    await _client
        .from('chantier_tasks')
        .update({'is_done': isDone}).eq('id', taskId);
  }

  // ────────────────────────────────────────────────────────
  // 3. Budgets
  // ────────────────────────────────────────────────────────

  /// Fetch budget for a chantier
  Future<Map<String, dynamic>?> getBudget(String chantierId) async {
    final response = await _client
        .from('chantier_budgets')
        .select()
        .eq('chantier_id', chantierId)
        .maybeSingle();
    return response;
  }

  /// Stream budget for a chantier (real-time)
  Stream<Map<String, dynamic>?> streamBudget(String chantierId) {
    return _client
        .from('chantier_budgets')
        .stream(primaryKey: ['id'])
        .eq('chantier_id', chantierId)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  /// Update budget fields
  Future<void> updateBudget(
      String chantierId, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _client
        .from('chantier_budgets')
        .update(updates)
        .eq('chantier_id', chantierId);
  }

  /// Update Chantier Status
  Future<void> updateChantierStatus(String chantierId, String status) async {
    await _client.from('chantiers').update({'status': status}).eq('id', chantierId);
  }

  /// Stream all quotes for a specific chantier (real-time)
  Stream<List<Map<String, dynamic>>> streamChantierQuotes(String chantierId) {
    return _client
        .from('quotes')
        .stream(primaryKey: ['id'])
        .eq('chantier_id', chantierId)
        .order('created_at', ascending: false)
        .map((data) => data.map((q) {
              final metadata = (q['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
              return {
                'id': q['id'],
                'status': q['status'] ?? 'Draft',
                'reference': metadata['quoteNumber'] ?? q['reference'] ?? 'N/A',
                'total_ht': q['total_ht'] ?? 0,
                'total_ttc': q['total_ttc'] ?? 0,
                'date': metadata['date'] ?? '',
                'client': (metadata['client'] as Map?)?.cast<String, dynamic>() ?? {},
              };
            }).toList());
  }

  /// Get all open tasks across all chantiers for the current user
  Future<List<Map<String, dynamic>>> getOpenTasksForUser(String userId) async {
    // 1. Get user's chantiers
    final chantiers = await _client
        .from('chantiers')
        .select('id')
        .eq('user_id', userId);
        
    if (chantiers.isEmpty) return [];
    
    final chantierIds = chantiers.map((c) => c['id']).toList();
    
    // 2. Fetch tasks
    final tasksResponse = await _client
        .from('chantier_tasks')
        .select()
        .inFilter('chantier_id', chantierIds)
        .eq('is_done', false)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(tasksResponse);
  }
}
