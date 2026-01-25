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
      final totals = quoteData['totals'] as Map<String, dynamic>?;
      // Note: Company data is stored in user's business_info, not duplicated here
      
      // Build metadata to preserve all quote information
      final metadata = {
        'quoteNumber': quoteData['quoteNumber'],
        'date': quoteData['date'],
        'validity': quoteData['validity'],
        'siteAddress': quoteData['siteAddress'],
        'company': quoteData['company'], // Store for reference
        'totals': totals,
      };
      
      // Build flat data structure matching database schema
      final data = {
        'user_id': userId,
        'status': quoteData['status'] ?? 'en_cours',
        'created_at': quoteData['createdAt'] ?? DateTime.now().toIso8601String(),
        
        // Flatten client data
        'client_name': client?['name'],
        'client_email': client?['email'],
        'client_phone': client?['phone'],
        'client_address': client?['address'],
        
        // Store complex data as JSONB
        'rooms': quoteData['expenses'], // Store room expenses as JSONB
        'tasks': quoteData['tasks'], // Store tasks as JSONB
        'notes': metadata, // Store metadata including company, quote number, dates, etc.
        
        // Financial data
        'total_amount': totals?['ttc'],
      };

      // Generate signature URL (will be updated with actual ID for new quotes)
      final clientEmail = client?['email'] ?? '';
      final signatureUrl = 'https://koji-signature.vercel.app/?quoteId=\${quoteId ?? "TEMP"}&email=${Uri.encodeComponent(clientEmail)}';
      data['signature_url'] = signatureUrl;


      if (quoteId != null) {
        // Update existing quote - signature URL already set
        await _supabase.from('quotes').upsert(data);
        _logger.i('✅ [QuoteRepository] Quote updated successfully with ID: $quoteId');
        return quoteId;
      } else {
        // Insert new quote first without signature URL
        data.remove('signature_url'); // Remove temp signature URL
        final response = await _supabase.from('quotes').insert(data).select().single();
        final newQuoteId = response['id'] as String;
        
        // Now update with the correct signature URL containing the actual quote ID
        final clientEmail = client?['email'] ?? '';
        final correctSignatureUrl = 'https://koji-signature.vercel.app/?quoteId=$newQuoteId&email=${Uri.encodeComponent(clientEmail)}';
        
        await _supabase.from('quotes').update({
          'signature_url': correctSignatureUrl,
        }).eq('id', newQuoteId);
        
        _logger.i('✅ [QuoteRepository] Quote saved successfully with ID: $newQuoteId');
        return newQuoteId;
      }
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
