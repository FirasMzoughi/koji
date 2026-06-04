import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:koji/core/supabase_config.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:koji/features/signature/repository/signature_repository.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(
    SupabaseConfig.client,
    ref.read(userRepositoryProvider),
  );
});

/// Client-side ("Espace Client" / particulier) data access.
///
/// A client never owns chantiers or quotes — those belong to the entreprise.
/// The client is linked purely by the **email** the entreprise typed into
/// `chantiers.client_email` when creating the chantier. Everything a client can
/// see (their devis, the works to follow, the per-devis discussion) is resolved
/// from that email match.
///
/// All reads here depend on Supabase RLS allowing a logged-in client to read
/// rows where `client_email = auth.jwt() ->> 'email'` (see
/// supabase/client_access.sql). When the policy is missing the queries return
/// empty/throw and the UI shows an empty state rather than crashing.
class ClientRepository {
  ClientRepository(this._client, this._userRepository);

  final SupabaseClient _client;
  final UserRepository _userRepository;

  /// The logged-in client's email, lower-cased, or empty if signed out.
  String get clientEmail =>
      (_client.auth.currentUser?.email ?? '').trim().toLowerCase();

  String? get _uid => _client.auth.currentUser?.id;

  /// All devis addressed to this client (matched by email), newest first,
  /// normalized to the UI shape used across the app.
  Future<List<Map<String, dynamic>>> getQuotes() async {
    final uid = _uid;
    if (uid == null) return [];
    return _userRepository.getClientQuotes(uid, email: clientEmail);
  }

  /// Only the finalized devis (signed / accepted) — used for the Documents tab.
  Future<List<Map<String, dynamic>>> getSignedDocuments() async {
    final quotes = await getQuotes();
    return quotes.where((q) => isSigned(q['status'])).toList();
  }

  /// Read-only works (tasks) across this client's chantiers, each tagged with
  /// its chantier reference for grouping.
  Future<List<Map<String, dynamic>>> getTasks() async {
    final uid = _uid;
    if (uid == null) return [];
    return _userRepository.getClientTasks(uid, email: clientEmail);
  }

  /// Persist the client's signature for [quoteId] and flip the devis to
  /// `signed`. Reuses the shared signature pipeline.
  Future<void> signQuote({
    required String quoteId,
    required String clientName,
    required Uint8List signatureBytes,
  }) async {
    await SignatureRepository().saveSignature(
      quoteId,
      clientName,
      signatureBytes,
    );
  }

  /// True when a devis status represents a pending/awaiting-signature state.
  static bool isPending(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    return s == 'generated' ||
        s == 'en_cours' ||
        s == 'draft' ||
        s == 'pending' ||
        s.contains('attente') ||
        s.contains('envoy');
  }

  /// True when a devis status represents a finalized/signed state.
  static bool isSigned(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    return s == 'signed' ||
        s == 'accepted' ||
        s == 'validated' ||
        s.contains('sign') ||
        s.contains('accept');
  }
}
