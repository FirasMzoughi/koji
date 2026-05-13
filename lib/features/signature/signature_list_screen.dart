import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/route_args.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/quote/repository/quote_repository.dart';

class SignatureListScreen extends ConsumerWidget {
  const SignatureListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final quotesAsync = user != null
        ? ref.watch(quoteRepositoryProvider).getUserQuotes(user.id)
        : const Stream<List<Map<String, dynamic>>>.empty();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Signer un devis',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2648))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0F2648), size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: quotesAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }

          final quotes = snapshot.data ?? [];

          if (quotes.isEmpty)
            return const Center(child: Text("Aucun devis à signer."));

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: quotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _SignatureQuoteCard(
                  quote: quotes[index],
                  onTap: () {
                    context.push('/signature/sign',
                        extra: SignatureArgs(quote: quotes[index]));
                  });
            },
          );
        },
      ),
    );
  }
}

class _SignatureQuoteCard extends StatelessWidget {
  final Map<String, dynamic> quote;
  final VoidCallback onTap;

  const _SignatureQuoteCard({required this.quote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final client = quote['client'] ?? {};
    final status = quote['status'] ?? 'pending';
    final totals = quote['totals'] ?? {};
    final totalTTC = totals['ttc'] ?? 0.0;

    // Determine Status Badge
    String statusLabel = 'Brouillon';
    Color statusColor = Colors.orange;
    Color statusBg = Colors.orange.withAlpha((0.1 * 255).round());

    if (status == 'en_cours' || status == 'pending') {
      statusLabel = 'Prêt à Signer';
      statusColor = Colors.green;
      statusBg = Colors.green.withAlpha((0.1 * 255).round());
    } else if (status == 'envoye') {
      statusLabel = 'Envoyé';
      statusColor = Colors.blue;
      statusBg = Colors.blue.withAlpha((0.1 * 255).round());
    } else if (status == 'signed' || status == 'completed') {
      statusLabel = 'Signé';
      statusColor = Colors.grey;
      statusBg = Colors.grey.withAlpha((0.1 * 255).round());
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha((0.03 * 255).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Devis N° #${quote['quoteNumber'] ?? '??'}",
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withAlpha((0.2 * 255).round())),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status == 'en_cours' || status == 'pending')
                            Icon(Icons.check_circle,
                                size: 12, color: statusColor),
                          if (status == 'en_cours' || status == 'pending')
                            const SizedBox(width: 4),
                          Text(statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  // Use Quote Title or Client Name
                  quote['company']?['name'] != null
                      ? "Rénovation ${quote['client']?['name']?.split(' ').first}"
                      : "Rénovation",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2648)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(client['name'] ?? 'Client Inconnu',
                        style: const TextStyle( color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text("Crée le ${quote['date'] ?? '??'}",
                        style: const TextStyle( color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total TTC",
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8))),
                        Text(
                            "${(totalTTC as num).toDouble().toStringAsFixed(2)} €",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F2648))),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Détails",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D3557))),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward,
                            size: 16, color: Color(0xFF1D3557)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
