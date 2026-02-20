import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/quote/models/quote_models.dart';
import 'package:koji/features/quote/product_details_screen.dart';
import 'package:koji/features/quote/repository/product_repository.dart';

class ProductSelectionScreen extends ConsumerStatefulWidget {
  final String? roomId;
  final String? taskId;
  final String? categoryFilter;

  const ProductSelectionScreen({
    super.key,
    this.roomId,
    this.taskId,
    this.categoryFilter,
  });

  @override
  ConsumerState<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends ConsumerState<ProductSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _packagingController = TextEditingController();

  String _searchQuery = '';
  // String _selectedFilter = 'Tous'; // Removed as UI doesn't seem to use logic for it yet, or add it back if needed. Keeping simple.
  
  String _selectedCategory = 'Peinture'; // Default
  String _selectedUnit = 'u'; // Default
  
  // Options matching SQL comments/schema
  final List<String> _categories = ['Peinture', 'Enduit', 'Outillage', 'Materiaux', 'Autre'];
  final List<String> _units = ['u', 'L', 'kg', 'm2', 'ml'];

  @override
  void initState() {
    super.initState();
  }

  void _showAddProductDialog() {
    // Reset fields
    _nameController.clear();
    _brandController.clear();
    _priceController.clear();
    _imageUrlController.clear();
    _packagingController.clear();
    setState(() {
      _selectedCategory = 'Peinture';
      _selectedUnit = 'u';
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to update dropdowns within Dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Nouveau Produit", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Nom du produit*", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: "Catégorie", border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setDialogState(() => _selectedCategory = val!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: "Prix HT*", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(labelText: "Unité", border: OutlineInputBorder()),
                            items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (val) => setDialogState(() => _selectedUnit = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _packagingController,
                      decoration: const InputDecoration(labelText: "Conditionnement (ex: Pot 10L)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _brandController,
                      decoration: const InputDecoration(labelText: "Marque", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: "URL Image (Optionnel)", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkNavy),
                  onPressed: () async {
                     if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
                        final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
                        
                        // Payload matching Supabase Schema
                        final newProduct = {
                          'name': _nameController.text,
                          'brand': _brandController.text.isNotEmpty ? _brandController.text : null,
                          'price_ht': price,
                          'image_url': _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
                          'category': _selectedCategory, 
                          'unit': _selectedUnit,
                          'packaging': _packagingController.text.isNotEmpty ? _packagingController.text : null,
                          
                          // Defaults from SQL Schema (explicitly sending them ensures consistency)
                          'consumption_rule_type': 'fixed',
                          'consumption_rule_factor': 1.0,
                        };
                        
                        try {
                          await ref.read(productRepositoryProvider).addProduct(newProduct);
                          ref.invalidate(productsProvider); // Refresh list
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          debugPrint("Error adding product: $e");
                        }
                     }
                  },
                  child: const Text("Créer", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer ?"),
          content: Text("Voulez-vous vraiment supprimer ${product.name} ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(productRepositoryProvider).deleteProduct(product.id);
                ref.invalidate(productsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final isSelectionMode = widget.roomId != null && widget.taskId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: !isSelectionMode 
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: AppTheme.darkNavy,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
                        isSelectionMode ? 'Recherche de Produits' : 'Fournitures',
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

            // Use AsyncValue to handle loading/error
            Expanded(
              child: productsAsync.when(
                data: (allProducts) {
                  // Filter logic
                  final filteredProducts = allProducts.where((p) {
                    // Category Filter (Pre-filter)
                    if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
                       // Normalize checking
                       if (p.category.trim().toLowerCase() != widget.categoryFilter!.trim().toLowerCase()) {
                          return false;
                       }
                    }

                    if (_searchQuery.isEmpty) return true;
                    final q = _searchQuery.toLowerCase();
                    return p.name.toLowerCase().contains(q) || 
                           p.brand.toLowerCase().contains(q) ||
                           p.category.toLowerCase().contains(q);
                  }).toList();

                  return Column(
                    children: [
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
                  onChanged: (val) => setState(() => _searchQuery = val), // Trigger rebuild
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
                    '${filteredProducts.length} Résultats trouvés',
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
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(filteredProducts[index], isSelectionMode);
                },
              ),
            ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erreur: $err')),
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

  Widget _buildProductCard(Product product, bool isSelectionMode) {
    return GestureDetector(
      onLongPress: !isSelectionMode ? () => _confirmDelete(product) : null,
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
          if (mounted && isSelectionMode) {
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
