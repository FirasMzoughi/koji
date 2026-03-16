import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SignatureRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final Logger _logger = Logger();

  Future<void> saveSignature(
    String quoteId,
    String clientName,
    Uint8List signatureBytes,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final fileName = '${quoteId}_signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final storagePath = '$userId/$fileName';

      _logger.i('Uploading signature $fileName to signatures bucket');

      // 1. Upload PNG to storage
      await _client.storage.from('signatures').uploadBinary(
        storagePath,
        signatureBytes,
        fileOptions: const FileOptions(contentType: 'image/png'),
      );

      // 2. Get public URL
      final fileUrl = _client.storage.from('signatures').getPublicUrl(storagePath);

      // 3. Insert record into `signatures` table
      await _client.from('signatures').insert({
        'user_id': userId,
        'quote_id': quoteId,
        'client_name': clientName,
        'signature_url': fileUrl,
      });

      // 4. Update the quote status to 'signed'
      await _client.from('quotes').update({
        'status': 'signed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', quoteId);

      _logger.i('Successfully saved signature and updated quote $quoteId');
    } catch (e) {
      _logger.e('Failed to save signature', error: e);
      rethrow;
    }
  }
}
