import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/core/supabase_config.dart';
import 'package:koji/features/subscription/data/subscription_repository.dart';

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(SupabaseConfig.client);
});

/// Resolves and caches the current access status (trial / subscribed / expired)
/// for the signed-in entreprise. Re-fetched after a purchase via [refresh].
class SubscriptionStatusNotifier
    extends StateNotifier<AsyncValue<SubscriptionStatus>> {
  SubscriptionStatusNotifier(this._repo)
      : super(const AsyncValue.loading());

  final SubscriptionRepository _repo;

  Future<void> load() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data(SubscriptionStatus.unknown);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final status = await _repo.resolveStatus(userId);
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// After a purchase/restore is persisted, re-read the status so the gate
  /// reopens immediately.
  Future<void> refresh() => load();
}

final subscriptionStatusProvider = StateNotifierProvider<
    SubscriptionStatusNotifier, AsyncValue<SubscriptionStatus>>((ref) {
  return SubscriptionStatusNotifier(
      ref.watch(subscriptionRepositoryProvider));
});

/// Convenience: true when the entreprise may use gated features (trial active
/// OR subscribed). Defaults to true while still loading/unknown so we never
/// block on a transient state — the explicit `expired` state is what gates.
final hasAccessProvider = Provider<bool>((ref) {
  final async = ref.watch(subscriptionStatusProvider);
  return async.maybeWhen(
    data: (s) => s.state != AccessState.expired,
    orElse: () => true,
  );
});
