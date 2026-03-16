import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:koji/core/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(SupabaseConfig.client);
});

class UserRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger();

  UserRepository(this._supabase);

  Future<void> saveUser(String uid, String email, {bool isPro = false}) async {
    _logger.i('💾 [UserRepository] Saving user to Supabase');
    try {
      await _supabase.from('users').upsert({
        'id': uid,
        'email': email,
        'is_pro': isPro,
        'created_at': DateTime.now().toIso8601String(),
      });
      _logger.i('✅ [UserRepository] User saved successfully');
    } catch (e) {
      _logger.e('❌ [UserRepository] Failed to save user', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    _logger.i('🔍 [UserRepository] Fetching user from Supabase');
    try {
      final response =
          await _supabase.from('users').select().eq('id', uid).maybeSingle();

      if (response != null) {
        _logger.i('✅ [UserRepository] User found in Supabase');
      } else {
        _logger.i('⚠️ [UserRepository] User not found in Supabase');
      }
      return response;
    } catch (e) {
      _logger.e('❌ [UserRepository] Failed to fetch user', error: e);
      rethrow;
    }
  }

  Future<String?> uploadBusinessLogo(String uid, String filePath) async {
    _logger.i('📸 [UserRepository] Uploading business logo');
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final fileExt = filePath.split('.').last;
      final fileName = '$uid/logo.$fileExt';

      // Upload to Supabase Storage
      await _supabase.storage.from('business-logos').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true, // Replace if exists
              contentType: 'image/$fileExt',
            ),
          );

      // Get public URL
      final logoUrl =
          _supabase.storage.from('business-logos').getPublicUrl(fileName);

      _logger.i('✅ [UserRepository] Logo uploaded successfully');
      return logoUrl;
    } catch (e) {
      _logger.e('❌ [UserRepository] Failed to upload logo', error: e);
      rethrow;
    }
  }

  Future<String?> getLogoUrl(String uid) async {
    _logger.i('🔍 [UserRepository] Fetching logo URL');
    try {
      final userData = await getUser(uid);
      final logoUrl = userData?['logo_url'] as String?;

      if (logoUrl != null) {
        _logger.i('✅ [UserRepository] Logo URL found');
      } else {
        _logger.i('⚠️ [UserRepository] No logo URL found');
      }
      return logoUrl;
    } catch (e) {
      _logger.e('❌ [UserRepository] Failed to fetch logo URL', error: e);
      return null;
    }
  }

  Future<void> updateBusinessInfo({
    required String uid,
    required String raisonSociale,
    required String formeJuridique,
    required String siret,
    required String emailPro,
    required String phone,
    required String address,
    required String tva,
    String? logoUrl,
    double? dailyRate,
    double? hoursPerDay,
  }) async {
    _logger.i('💼 [UserRepository] Updating business info');
    try {
      final updateData = {
        'business_info': {
          'raisonSociale': raisonSociale,
          'formeJuridique': formeJuridique,
          'siret': siret,
          'emailPro': emailPro,
          'phone': phone,
          'address': address,
          'tva': tva,
          if (dailyRate != null) 'dailyRate': dailyRate,
          if (hoursPerDay != null) 'hoursPerDay': hoursPerDay,
        },
        'is_business_info_complete': true,
      };

      // Add logo URL if provided
      if (logoUrl != null) {
        updateData['logo_url'] = logoUrl;
      }

      await _supabase.from('users').update(updateData).eq('id', uid);
      _logger.i('✅ [UserRepository] Business info updated successfully');
    } catch (e) {
      _logger.e('❌ [UserRepository] Failed to update business info', error: e);
      rethrow;
    }
  }

  Future<void> updateProfession(String uid, List<String> professions) async {
    final professionsString = professions.join(',');
    _logger.i('👔 [UserRepository] Updating professions');
    try {
      await _supabase.from('users').update({
        'profession': professionsString,
        'is_profile_complete': true,
      }).eq('id', uid);
      _logger.i(
          '✅ [UserRepository] Professions updated successfully - Profile marked complete');
    } catch (e) {
      _logger.e('❌ [UserRepository] Failed to update professions', error: e);
      rethrow;
    }
  }
}
