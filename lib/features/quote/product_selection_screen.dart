
import 'package:flutter/material.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/quote/models/quote_models.dart';
import 'package:koji/features/quote/product_details_screen.dart';

class ProductSelectionScreen extends StatefulWidget {
  final String roomId;
  final String taskId;

  const ProductSelectionScreen({
    super.key,
    required this.roomId,
    required this.taskId,
  });

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _selectedFilter = 'Tous'; // 'Tous', 'Catégoris', 'Fournisseur' mock

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    // Load all products from the data source
    _allProducts = getAllProducts();
    _filteredProducts = List.from(_allProducts);
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesQuery = p.name.toLowerCase().contains(query.toLowerCase()) || 
                             p.brand.toLowerCase().contains(query.toLowerCase()) ||
                             p.category.toLowerCase().contains(query.toLowerCase());
        return matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkNavy, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Recherche de Produits',
                        style: AppTheme.headingStyle(context).copyWith(
                          fontSize: 18,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance back button
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterProducts,
                  style: const TextStyle(fontFamily: 'Outfit'),
                  decoration: InputDecoration(
                    hintText: 'Peinture, Enduit, Outillage...',
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.grey[400],
                    ),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('Catégoris', true),
                  const SizedBox(width: 12),
                  _buildFilterChip('Fournisseur', false),
                  const SizedBox(width: 12),
                  _buildFilterChip('Récents', false),
                ],
              ),
            ),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredProducts.length} Résultats trouvés',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Tirer par',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E3A8A), size: 20),
                    ],
                  ),
                ],
              ),
            ),

            // Product List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(_filteredProducts[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[200]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: isSelected ? Colors.white : Colors.grey[500],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () async {
        // Navigate to details
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              initialQuantity: 1.0,
            ),
          ),
        );

        if (result != null && result is double) {
          // Return product and quantity
          if (mounted) {
            Navigator.pop(context, {'product': product, 'quantity': result});
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product.imageUrl.isNotEmpty
                    ? (product.imageUrl.startsWith('http')
                        ? Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey))
                        : Image.asset(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, color: Colors.grey)))
                    : const Icon(Icons.image, color: Colors.grey, size: 40),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 100), // Ensure min height to match image
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand.toUpperCase() + " PREMIUM", 
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16, // Slightly reduced font size to 16
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '10m²/L • 15L', 
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Spacer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.priceHT.toStringAsFixed(2)}€ HT/U',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D74FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
