import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/quote/repositories/chantier_repository.dart';
import 'package:koji/features/quote/repositories/document_repository.dart';

final chantierRepositoryProvider = Provider<ChantierRepository>((ref) {
  return ChantierRepository();
});

final userChantiersProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.watch(chantierRepositoryProvider).streamChantiers(userId);
});

// FutureProvider (not Stream) because Supabase Realtime is not enabled on
// chantier_tasks — `.stream()` only emits the initial snapshot, so new rows
// inserted by the same client never appear until the screen is rebuilt.
// Using a Future + explicit `ref.invalidate(...)` after each mutation keeps
// the list in sync without depending on the realtime publication.
final chantierTasksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, chantierId) {
  return ref.watch(chantierRepositoryProvider).getTasks(chantierId);
});

final chantierBudgetProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, chantierId) {
  return ref.watch(chantierRepositoryProvider).streamBudget(chantierId);
});

final openChantierTasksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.watch(chantierRepositoryProvider).getOpenTasksForUser(userId);
});

// --- Documents ---
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});

final chantierDocumentsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chantierId) {
  return ref.watch(documentRepositoryProvider).streamChantierDocuments(chantierId);
});

final chantierQuotesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chantierId) {
  return ref.watch(chantierRepositoryProvider).streamChantierQuotes(chantierId);
});
