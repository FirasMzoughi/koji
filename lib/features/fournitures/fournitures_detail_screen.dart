import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/quote/models/quote_models.dart';
import 'package:koji/features/quote/product_selection_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/quote/repository/product_repository.dart';

class FournituresDetailScreen extends StatefulWidget {
  final Map<String, dynamic> quote;

  const FournituresDetailScreen({super.key, required this.quote});

  @override
  State<FournituresDetailScreen> createState() => _FournituresDetailScreenState();
}

class _FournituresDetailScreenState extends State<FournituresDetailScreen> {
  // Aggregated Products: Map<ProductId, Quantity>
  final Map<String, double> _products = {};

  @override
  void initState() {
    super.initState();
    _processQuoteData();
  }

  void _processQuoteData() {
    // Structure: quote['tasks'] -> Map<roomId, taskMap>
    // taskMap -> Map<taskId, taskDetails>
    // taskDetails['selectedProducts'] -> Map<prodId, qty>
    
    final tasksByRoom = widget.quote['tasks'] as Map<String, dynamic>? ?? {};
    
    tasksByRoom.forEach((roomId, roomTasks) {
       if (roomTasks is Map) {
         roomTasks.forEach((taskId, taskDetails) {
            if (taskDetails is Map && taskDetails.containsKey('selectedProducts')) {
               final products = taskDetails['selectedProducts'];
               if (products is Map) {
                 products.forEach((prodId, qty) {
                    final q = (qty is num) ? qty.toDouble() : 0.0;
                    _products[prodId.toString()] = (_products[prodId.toString()] ?? 0) + q;
                 });
               }
            }
         });
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extract Client Info for Title
    final client = widget.quote['client'] ?? {};
    final clientName = client['name'] ?? 'Client';
    // Title usually "Rénovation [Name]"
    final title = "Rénovation ${clientName.split(' ').first}..."; 

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // Light Blue
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left, color: Color(0xFF1D3557)),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F2648),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Color(0xFF0F2648)), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
               alignment: Alignment.center,
               children: [
                 const Icon(Icons.notifications_outlined, color: Color(0xFF0F2648)),
                 Positioned(
                   top: 10,
                   right: 2,
                   child: Container(
                     width: 8, height: 8,
                     decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                   ),
                 )
               ],
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              "Mes Fournitures",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final productsAsync = ref.watch(productsProvider);

                return productsAsync.when(
                  data: (allProds) {
                    if (_products.isEmpty) {
                      return const Center(child: Text("Aucune fourniture enregistrée."));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final entry = _products.entries.elementAt(index);
                        // Find product in fetched list, or fallback
                        final prod = allProds.firstWhere(
                          (p) => p.id == entry.key,
                          orElse: () => const Product(
                              id: 'err',
                              name: 'Produit Inconnu',
                              imageUrl: '',
                              priceHT: 0,
                              unit: ''),
                        );

                        if (prod.id == 'err') return const SizedBox.shrink();

                        return _buildProductCard(prod, entry.value);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Erreur: $err')),
                );
              },
            ),
          ),
          
          // Floating Action Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () async {
                   // Navigate to Product Selection (Global context)
                   final result = await Navigator.push(
                     context,
                     MaterialPageRoute(builder: (_) => const ProductSelectionScreen(roomId: 'global', taskId: 'fourniture_libre')),
                   );
                   
                   if (result != null && result is Map) {
                     final Product product = result['product'];
                     final double quantity = result['quantity'];
                     
                     // Update Local State (Visual only for now, ideally persist to DB)
                     setState(() {
                       _products[product.id] = (_products[product.id] ?? 0) + quantity;
                     });
                     
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text("${product.name} ajouté"), backgroundColor: const Color(0xFF22C55E)),
                     );
                   }
                },
                child: Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D74FF),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x331D74FF), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductCard(Product prod, double quantity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0,0,0,0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Placeholder bg
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                prod.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PRO PREMIUM", 
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B).withOpacity(0.7)),
                    ),
                    const Icon(Icons.star, size: 16, color: Color(0xFFCBD5E1)) // Star icon
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  prod.name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2648),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Grid Icon
                    const Icon(Icons.grid_view, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      "10m²/L • ${(quantity).toStringAsFixed(0)}${prod.unit}", // Mock consumption info
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Footer: Price + Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                             text: "${prod.priceHT.toStringAsFixed(2)}€ ",
                             style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F2648)),
                          ),
                          const TextSpan(
                             text: "HT/U",
                             style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          "Détails",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D3557),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF1D3557)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
