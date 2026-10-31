import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_tokens.dart';
import 'package:koji/design/koji_widgets.dart';
import 'package:koji/features/marketplace/repository/marketplace_repository.dart';

/// Secure payment for marketplace offer via Stripe Connect escrow.
/// Opens the Stripe Checkout session URL in a WebView.
/// Web equivalent: /api/marketplace/offres/[id]/paiement/[step]
class MarketplaceOfferPaymentScreen extends ConsumerStatefulWidget {
  final String offerId;
  final String step; // 'review', 'details', 'checkout', 'validate'

  const MarketplaceOfferPaymentScreen({
    super.key,
    required this.offerId,
    this.step = 'review',
  });

  @override
  ConsumerState<MarketplaceOfferPaymentScreen> createState() =>
      _MarketplaceOfferPaymentScreenState();
}

class _MarketplaceOfferPaymentScreenState
    extends ConsumerState<MarketplaceOfferPaymentScreen> {
  late WebViewController _webViewController;
  bool _loading = true;
  String? _error;
  String? _checkoutUrl;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadCheckoutSession();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _loading = true);
          },
          onPageFinished: (String url) {
            setState(() => _loading = false);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = 'Erreur de chargement: ${error.description}';
              _loading = false;
            });
          },
        ),
      );
  }

  Future<void> _loadCheckoutSession() async {
    try {
      final data = await ref
          .read(marketplaceRepositoryProvider)
          .getPaymentCheckoutUrl(
            offerId: widget.offerId,
            step: widget.step,
          );
      final url = data['checkoutUrl'] as String?;
      if (url == null) throw Exception('No checkout URL returned');
      if (!mounted) return;
      setState(() {
        _checkoutUrl = url;
        _error = null;
      });
      _webViewController.loadRequest(Uri.parse(url));
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger le paiement. Réessayez.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KojiPage(
      title: 'Paiement sécurisé',
      appBarOnPhone: true,
      main: [Stack(
        children: [
          if (_checkoutUrl != null)
            WebViewWidget(controller: _webViewController),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Center(
              child: KojiEmptyState(
                icon: Icons.error_outline,
                title: 'Erreur de paiement',
                subtitle: _error,
                action: KojiButton(
                  label: 'Réessayer',
                  variant: KojiButtonVariant.secondary,
                  onPressed: _loadCheckoutSession,
                ),
              ),
            ),
        ],
      )],
    );
  }
}
