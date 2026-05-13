import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:koji/features/fournitures/models/fourniture_model.dart';

class FournitureRepository {
  final SupabaseClient _client;

  FournitureRepository(this._client);

  // ─── FOURNISSEURS ─────────────────────────

  Future<List<Fournisseur>> getFournisseurs() async {
    final data = await _client
        .from('fournisseurs')
        .select()
        .order('name', ascending: true);
    return (data as List).map((e) => Fournisseur.fromMap(e)).toList();
  }

  Future<Fournisseur> addFournisseur(String name, {String? logoUrl}) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.from('fournisseurs').insert({
      'user_id': userId,
      'name': name,
      if (logoUrl != null) 'logo_url': logoUrl,
    }).select().single();
    return Fournisseur.fromMap(data);
  }

  Future<void> deleteFournisseur(String id) async {
    await _client.from('fournisseurs').delete().eq('id', id);
  }

  // ─── FOURNITURES ──────────────────────────

  Future<List<Fourniture>> getAllFournitures() async {
    final data = await _client
        .from('fournitures')
        .select('*, fournisseurs(name)')
        .order('created_at', ascending: false);
    return (data as List).map((e) => Fourniture.fromMap(e)).toList();
  }

  Future<List<Fourniture>> getFournituresByFournisseur(String fournisseurId) async {
    final data = await _client
        .from('fournitures')
        .select('*, fournisseurs(name)')
        .eq('fournisseur_id', fournisseurId)
        .order('name', ascending: true);
    return (data as List).map((e) => Fourniture.fromMap(e)).toList();
  }

  Future<List<Fourniture>> getRecentFournitures({int limit = 20}) async {
    final data = await _client
        .from('fournitures')
        .select('*, fournisseurs(name)')
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Fourniture.fromMap(e)).toList();
  }

  Future<List<Fourniture>> getDiversFournitures() async {
    final data = await _client
        .from('fournitures')
        .select('*, fournisseurs(name)')
        .isFilter('fournisseur_id', null)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Fourniture.fromMap(e)).toList();
  }

  Future<Fourniture> addFourniture(Map<String, dynamic> fournitureData) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.from('fournitures').insert({
      ...fournitureData,
      'user_id': userId,
    }).select('*, fournisseurs(name)').single();
    return Fourniture.fromMap(data);
  }

  Future<void> updateFourniture(String id, Map<String, dynamic> updates) async {
    await _client.from('fournitures').update(updates).eq('id', id);
  }

  Future<void> deleteFourniture(String id) async {
    await _client.from('fournitures').delete().eq('id', id);
  }
}

// ─── PROVIDERS ──────────────────────────────

final fournitureRepositoryProvider = Provider<FournitureRepository>((ref) {
  return FournitureRepository(Supabase.instance.client);
});

final fournisseursProvider = FutureProvider<List<Fournisseur>>((ref) {
  return ref.read(fournitureRepositoryProvider).getFournisseurs();
});

final recentFournituresProvider = FutureProvider<List<Fourniture>>((ref) {
  return ref.read(fournitureRepositoryProvider).getRecentFournitures();
});

final allFournituresProvider = FutureProvider<List<Fourniture>>((ref) {
  return ref.read(fournitureRepositoryProvider).getAllFournitures();
});

final diversFournituresProvider = FutureProvider<List<Fourniture>>((ref) {
  return ref.read(fournitureRepositoryProvider).getDiversFournitures();
});

final fournisseurFournituresProvider =
    FutureProvider.family<List<Fourniture>, String>((ref, fournisseurId) {
  return ref.read(fournitureRepositoryProvider).getFournituresByFournisseur(fournisseurId);
});
