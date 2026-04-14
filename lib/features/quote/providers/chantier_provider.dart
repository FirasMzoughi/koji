import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/quote/repositories/chantier_repository.dart';
import 'package:koji/features/quote/repositories/document_repository.dart';

final chantierRepositoryProvider = Provider<ChantierRepository>((ref) {
  return ChantierRepository();
});

final userChantiersProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.watch(chantierRepositoryProvider).streamChantiers(userId);
});

final chantierTasksProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chantierId) {
  return ref.watch(chantierRepositoryProvider).streamTasks(chantierId);
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
