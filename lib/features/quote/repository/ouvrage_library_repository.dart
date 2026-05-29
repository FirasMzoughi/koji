import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:koji/features/quote/model/library_ouvrage.dart';

class OuvrageLibraryRepository {
  final SupabaseClient _client;
  OuvrageLibraryRepository(this._client);

  static const _table = 'ouvrage_library';

  Future<List<LibraryOuvrage>> getAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('famille', ascending: true)
        .order('code', ascending: true);
    return (rows as List)
        .map((e) => LibraryOuvrage.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<LibraryOuvrage> create(LibraryOuvrage ouvrage) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from(_table)
        .insert(ouvrage.toInsertMap(userId))
        .select()
        .single();
    return LibraryOuvrage.fromMap(data);
  }

  Future<LibraryOuvrage> update(LibraryOuvrage ouvrage) async {
    final data = await _client
        .from(_table)
        .update(ouvrage.toUpdateMap())
        .eq('id', ouvrage.id)
        .select()
        .single();
    return LibraryOuvrage.fromMap(data);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

final ouvrageLibraryRepositoryProvider =
    Provider<OuvrageLibraryRepository>((ref) {
  return OuvrageLibraryRepository(Supabase.instance.client);
});

final ouvrageLibraryProvider =
    FutureProvider<List<LibraryOuvrage>>((ref) async {
  return ref.read(ouvrageLibraryRepositoryProvider).getAll();
});
