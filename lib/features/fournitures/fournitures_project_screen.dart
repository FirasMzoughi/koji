import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/quote/repository/quote_repository.dart';

// Helper provider to fetch quotes stream
final userQuotesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(quoteRepositoryProvider).getUserQuotes(user.id);
});

class FournituresProjectScreen extends ConsumerWidget {
  const FournituresProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(userQuotesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Fournitures', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF0F2648))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F2648), size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Color(0xFF0F2648)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F2648)), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Mes Chantiers",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B).withOpacity(0.8),
              ),
            ),
          ),
          
          Expanded(
            child: quotesAsync.when(
              data: (quotes) {
                if (quotes.isEmpty) {
                  return const Center(child: Text("Aucun chantier trouvé."));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: quotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final quote = quotes[index];
                    return ProjectCard(
                      quote: quote,
                      onTap: () {
                         context.push(
                           '/fournitures/detail', 
                           extra: quote, // Pass the entire quote map
                         );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> quote;
  final VoidCallback onTap;

  const ProjectCard({super.key, required this.quote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Extract Data
    final client = quote['client'] ?? {};
    final clientName = client['name'] ?? 'Client Inconnu';
    final address = client['address'] ?? 'Adresse non renseignée';
    final quoteNumber = quote['quoteNumber'] ?? 'Devis'; // Use as title?
    // Title logic: If we have a project name, use it. Otherwise "Rénovation [Client]"
    final title = "Chantier ${clientName.split(' ').first}"; 
    
    // Status Logic
    final String statusRaw = quote['status'] ?? 'en_cours';
    String statusLabel = 'En Cours';
    Color statusColor = const Color(0xFF1D74FF);
    Color statusBg = const Color(0xFFEFF6FF);
    
    if (statusRaw == 'completed') {
       statusLabel = 'Terminé';
       statusColor = Colors.green;
       statusBg = Colors.green.withOpacity(0.1);
    }

    // Mock Progress (since we don't have real progress data yet)
    final double progress = 0.65; 

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w800, // Extra Bold
                          color: Color(0xFF0F2648),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Client Info
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text(
                      clientName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                 Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Avancement', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFF0F2648), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D3557)), // Dark Navy
                  ),
                ),
                
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Détails',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D3557),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF1D3557)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
