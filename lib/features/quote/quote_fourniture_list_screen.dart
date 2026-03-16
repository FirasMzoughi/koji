import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';

class QuoteFournitureListScreen extends ConsumerWidget {
  const QuoteFournitureListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quoteCreationProvider);

    // Extract and aggregate fournitures (materials)
    final Map<String, List<Map<String, dynamic>>> fournituresByRoom = {};
    double totalMaterialCost = 0.0;
    int totalItemsCount = 0;

    state.roomEstimations.forEach((roomId, items) {
      if (items is List) {
        final List<Map<String, dynamic>> roomFournitures = [];
        for (var item in items) {
          // Identify materials cost
          final qty = (item.quantity as num).toDouble();
          final materialUnitPrice = (item.materialCost as num).toDouble();
          
          if (materialUnitPrice > 0) {
            final totalLine = qty * materialUnitPrice;
            roomFournitures.add({
              'title': item.title,
              'quantity': qty,
              'unitPrice': materialUnitPrice,
              'total': totalLine,
            });
            totalMaterialCost += totalLine;
            totalItemsCount++;
          }
        }
        if (roomFournitures.isNotEmpty) {
          fournituresByRoom[roomId] = roomFournitures;
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.darkNavy, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Liste des fournitures',
          style: AppTheme.headingStyle(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: fournituresByRoom.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "Aucune fourniture nécessaire",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Total Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total estimé des matériaux',
                          style: TextStyle(fontFamily: 'Outfit', color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${totalMaterialCost.toStringAsFixed(2)} €',
                          style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalItemsCount éléments',
                            style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),

                  // List of items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: fournituresByRoom.keys.length,
                      itemBuilder: (context, index) {
                        final roomId = fournituresByRoom.keys.elementAt(index);
                        final items = fournituresByRoom[roomId]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
                              child: Text(
                                _getRoomLabel(roomId),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkNavy,
                                ),
                              ),
                            ),
                            ...items.map((item) => _buildFournitureItem(item)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              // Usually they just return or continue validation
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkNavy,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Retour au résumé",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFournitureItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.build_circle_outlined, color: AppTheme.darkNavy),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['quantity']} × ${item['unitPrice'].toStringAsFixed(2)} €',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item['total'].toStringAsFixed(2)} €',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoomLabel(String id) {
    if (id.toLowerCase().contains('salon')) return 'Salon';
    if (id.toLowerCase().contains('cuisine')) return 'Cuisine';
    if (id.toLowerCase().contains('chambre')) return 'Chambre';
    if (id.toLowerCase().contains('bain')) return 'Salle de bain';
    if (id.toLowerCase().contains('wc')) return 'WC';
    if (id.toLowerCase().contains('entree')) return 'Entrée';
    return id.substring(0, 1).toUpperCase() + id.substring(1);
  }
}
