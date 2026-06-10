import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Store product ids for the entreprise subscription. These must be created
/// (with the 7-day free trial) in App Store Connect and Google Play Console
/// using EXACTLY these ids.
class SubscriptionProducts {
  static const monthly = 'koji_entreprise_monthly';
  static const yearly = 'koji_entreprise_yearly';
  static const all = <String>{monthly, yearly};
}

/// Resolved access state used by the gate.
enum AccessState {
  /// Free trial is still running.
  trial,

  /// Paid subscription is active.
  subscribed,

  /// Trial ended and no active subscription — show the paywall.
  expired,

  /// Couldn't determine yet (still loading).
  unknown,
}

class SubscriptionStatus {
  final AccessState state;
  final DateTime? trialEndsAt;
  final int trialDaysLeft;

  const SubscriptionStatus({
    required this.state,
    this.trialEndsAt,
    this.trialDaysLeft = 0,
  });

  bool get hasAccess =>
      state == AccessState.trial || state == AccessState.subscribed;

  static const unknown = SubscriptionStatus(state: AccessState.unknown);
}

/// Single source of truth for the trial + subscription. Talks to Supabase for
/// the persisted state and to the store (`in_app_purchase`) for buying.
class SubscriptionRepository {
  SubscriptionRepository(this._supabase);

  final SupabaseClient _supabase;
  final InAppPurchase _iap = InAppPurchase.instance;

  // ── Trial / status from Supabase ──────────────────────────────────────────

  /// Ensure a trial exists for this entreprise user and return the current
  /// access status. Call this right after an entreprise logs in.
  Future<SubscriptionStatus> resolveStatus(String userId) async {
    try {
      // Start the trial the first time (idempotent server-side).
      await _supabase.rpc('start_trial_if_absent', params: {
        'p_user_id': userId,
      });

      final row = await _supabase
          .from('users')
          .select(
              'trial_ends_at, subscription_status, subscription_expires_at')
          .eq('id', userId)
          .maybeSingle();

      return _statusFromRow(row);
    } catch (e) {
      debugPrint('resolveStatus failed: $e');
      // Fail OPEN during the trial window is impossible to know — fail to
      // "unknown" so the UI can decide (we don't want to wrongly lock people
      // out on a transient network error).
      return SubscriptionStatus.unknown;
    }
  }

  SubscriptionStatus _statusFromRow(Map<String, dynamic>? row) {
    if (row == null) return SubscriptionStatus.unknown;

    final status = (row['subscription_status'] as String?)?.toLowerCase();
    final now = DateTime.now();

    // Active paid subscription (optionally still within its store expiry).
    if (status == 'active') {
      final exp = DateTime.tryParse(
          (row['subscription_expires_at'] as String?) ?? '');
      if (exp == null || exp.isAfter(now)) {
        return const SubscriptionStatus(state: AccessState.subscribed);
      }
    }

    // Otherwise fall back to the trial window.
    final trialEnds =
        DateTime.tryParse((row['trial_ends_at'] as String?) ?? '');
    if (trialEnds != null && trialEnds.isAfter(now)) {
      final daysLeft = trialEnds.difference(now).inHours / 24;
      return SubscriptionStatus(
        state: AccessState.trial,
        trialEndsAt: trialEnds,
        trialDaysLeft: daysLeft.ceil(),
      );
    }

    return SubscriptionStatus(state: AccessState.expired, trialEndsAt: trialEnds);
  }

  /// Persist a verified purchase result to Supabase.
  Future<void> _persistActive(PurchaseDetails purchase) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _supabase.rpc('set_subscription_status', params: {
      'p_status': 'active',
      'p_platform': platform,
      'p_product': purchase.productID,
      // The store auto-renews; we don't always get an explicit expiry here.
      // Leaving it null means "active until the store says otherwise"; a server
      // webhook (future) can refine this.
      'p_expires_at': null,
    });
  }

  // ── In-App Purchase ───────────────────────────────────────────────────────

  /// Whether the device store is available (e.g. false on an emulator without
  /// Play services, or if IAP is restricted).
  Future<bool> isStoreAvailable() => _iap.isAvailable();

  /// Load the subscription products configured in the stores.
  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(SubscriptionProducts.all);
    if (response.error != null) {
      debugPrint('queryProductDetails error: ${response.error}');
    }
    return response.productDetails;
  }

  /// Listen to the purchase stream. The caller must keep the subscription and
  /// cancel it on dispose. For each successful/restored purchase we persist the
  /// active status and complete the transaction.
  StreamSubscription<List<PurchaseDetails>> listen({
    required void Function() onActivated,
    required void Function(String message) onError,
  }) {
    return _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        switch (p.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            try {
              await _persistActive(p);
              onActivated();
            } catch (e) {
              onError('Activation: $e');
            }
            break;
          case PurchaseStatus.error:
            onError(p.error?.message ?? 'Achat échoué');
            break;
          case PurchaseStatus.canceled:
            onError('Achat annulé');
            break;
          case PurchaseStatus.pending:
            // In progress — nothing to do; UI shows a spinner.
            break;
        }
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
      }
    });
  }

  /// Start the buy flow for a subscription product.
  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    // Subscriptions are non-consumable.
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restore previous purchases (App Store / Play). Results arrive on the
  /// purchase stream as `restored`.
  Future<void> restore() => _iap.restorePurchases();
}
