import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:koji/features/subscription/data/subscription_repository.dart';
import 'package:koji/features/subscription/providers/subscription_provider.dart';

/// Paywall shown when the 14-day trial has expired (or when the entreprise taps
/// "S'abonner"). Buying goes through Apple IAP (iOS) / Google Play Billing
/// (Android) via the in_app_purchase package.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  static const _navy = Color(0xFF0A1227);
  static const _accent = Color(0xFFA18B73);

  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  SubscriptionRepository get _repo =>
      ref.read(subscriptionRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // Listen for purchase results.
    _sub = _repo.listen(
      onActivated: () async {
        await ref.read(subscriptionStatusProvider.notifier).refresh();
        if (mounted) {
          setState(() => _purchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Abonnement activé. Merci !')),
          );
          Navigator.of(context).maybePop();
        }
      },
      onError: (msg) {
        if (mounted) {
          setState(() {
            _purchasing = false;
            _error = msg;
          });
        }
      },
    );

    try {
      final available = await _repo.isStoreAvailable();
      if (!available) {
        setState(() {
          _loading = false;
          _error =
              "La boutique n'est pas disponible sur cet appareil. Connectez-vous avec un compte ${Platform.isIOS ? 'App Store' : 'Google Play'} valide.";
        });
        return;
      }
      final products = await _repo.loadProducts();
      if (mounted) {
        setState(() {
          _products = products
            ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
          _loading = false;
          if (products.isEmpty) {
            _error =
                "Aucune formule disponible. Vérifiez la configuration des produits dans la console ${Platform.isIOS ? 'App Store' : 'Google Play'}.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      await _repo.buy(product);
    } catch (e) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _navy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 20),
              const Text(
                'Continuez avec Koji',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: _navy),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre essai gratuit de 14 jours est terminé. Abonnez-vous pour continuer à créer vos devis, chantiers et gérer vos ouvriers.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 24),

              ..._benefits(),

              const SizedBox(height: 24),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                for (final p in _products) _productCard(p),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.red[400]),
                  ),
                ],
              ],

              const SizedBox(height: 16),
              TextButton(
                onPressed: _purchasing
                    ? null
                    : () async {
                        setState(() => _error = null);
                        await _repo.restore();
                      },
                child: const Text('Restaurer mes achats'),
              ),
              const SizedBox(height: 8),
              Text(
                "Paiement géré par ${Platform.isIOS ? 'l’App Store' : 'Google Play'}. Annulable à tout moment dans les réglages de votre compte.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _benefits() {
    const items = [
      'Devis illimités',
      'Gestion des chantiers',
      'Suivi des ouvriers',
      'Signature en ligne',
    ];
    return items
        .map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _accent, size: 20),
                  const SizedBox(width: 10),
                  Text(t,
                      style:
                          const TextStyle(fontSize: 15, color: _navy)),
                ],
              ),
            ))
        .toList();
  }

  Widget _productCard(ProductDetails p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: _purchasing ? null : () => _buy(p),
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _purchasing
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Column(
                children: [
                  Text(p.title.isNotEmpty ? p.title : 'Abonnement',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(p.price,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFFCBD5E1))),
                ],
              ),
      ),
    );
  }
}
