import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteTaskRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ────────────────────────────────────────────────────────
  // 1. Quotes
  // ────────────────────────────────────────────────────────

  /// Fetch a complete quote by its chantier_id
  Future<Map<String, dynamic>?> getQuoteByChantierId(String chantierId) async {
    final response = await _client
        .from('quotes')
        .select()
        .eq('chantier_id', chantierId)
        .maybeSingle();
    return response;
  }

  /// Create or update a root quote
  Future<String> upsertQuote(Map<String, dynamic> data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final payload = {
      'user_id': userId,
      'chantier_id': data['chantier_id'],
      'status': data['status'] ?? 'Draft',
      'total_ht': data['total_ht'] ?? 0,
      'total_ttc': data['total_ttc'] ?? 0,
      'tva_rate': data['tva_rate'] ?? 20.0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (data['id'] != null) {
      // Update
      payload['id'] = data['id'];
      await _client.from('quotes').upsert(payload);
      return data['id'] as String;
    } else {
      // Insert
      final res = await _client.from('quotes').insert(payload).select('id').single();
      return res['id'] as String;
    }
  }

  // ────────────────────────────────────────────────────────
  // 2. Quote Rooms
  // ────────────────────────────────────────────────────────

  /// Fetch rooms for a quote
  Future<List<Map<String, dynamic>>> getQuoteRooms(String quoteId) async {
    final response = await _client
        .from('quote_rooms')
        .select()
        .eq('quote_id', quoteId)
        .order('room_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Save or update a room context
  Future<String> upsertQuoteRoom(Map<String, dynamic> data) async {
    final payload = {
      'quote_id': data['quote_id'],
      'name': data['name'],
      'surface': data['surface'] ?? 0,
      'access_factor': data['access_factor'] ?? 1.0,
      'condition_factor': data['condition_factor'] ?? 1.0,
      'room_order': data['room_order'] ?? 0,
    };

    if (data['id'] != null) {
      payload['id'] = data['id'];
    }

    final res = await _client.from('quote_rooms').upsert(payload, onConflict: 'id').select('id').single();
    return res['id'] as String;
  }

  // ────────────────────────────────────────────────────────
  // 3. Quote Tasks
  // ────────────────────────────────────────────────────────

  /// Fetch tasks for a specific room
  Future<List<Map<String, dynamic>>> getQuoteTasks(String roomId) async {
    final response = await _client
        .from('quote_tasks')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create or update a task selection within a room
  Future<String> upsertQuoteTask(Map<String, dynamic> data) async {
    final payload = {
      'room_id': data['room_id'],
      'task_id': data['task_id'],
      'label': data['label'],
      'inputs': data['inputs'] ?? {},
      'selected_products': data['selected_products'] ?? {},
      'note': data['note'] ?? '',
      'photo_paths': data['photo_paths'] ?? [],
      'unit_price_ht': data['unit_price_ht'] ?? 0,
      'total_price_ht': data['total_price_ht'] ?? 0,
      'is_custom': data['is_custom'] ?? false,
    };

    if (data['id'] != null) {
      payload['id'] = data['id'];
    }

    final res = await _client.from('quote_tasks').upsert(payload, onConflict: 'id').select('id').single();
    return res['id'] as String;
  }

  /// Delete a task from a room
  Future<void> deleteQuoteTask(String id) async {
    await _client.from('quote_tasks').delete().eq('id', id);
  }
}
