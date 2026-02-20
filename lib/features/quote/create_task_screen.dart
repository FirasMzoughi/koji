
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/quote/product_selection_screen.dart';
import 'package:koji/features/quote/repository/task_repository.dart';
import 'package:koji/features/quote/models/quote_models.dart';
import 'package:koji/features/quote/repository/product_repository.dart'; // For Product model if needed

class CreateTaskScreen extends ConsumerStatefulWidget {
  final String profession;

  const CreateTaskScreen({super.key, required this.profession});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  List<File> _selectedImages = [];
  Map<String, double> _selectedProducts = {}; // ProductID -> Quantity
  final ImagePicker _picker = ImagePicker();
  
  bool _isSaving = false;

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductSelectionScreen(roomId: 'temp', taskId: 'temp'),
      ),
    );

    if (result != null && result is Map) {
      final Product product = result['product'];
      final double qty = result['quantity'];
      setState(() {
        _selectedProducts[product.id] = qty;
      });
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      await ref.read(taskRepositoryProvider).createTask(
        title: _titleController.text,
        description: _descController.text,
        profession: widget.profession,
        images: _selectedImages,
        defaultProducts: _selectedProducts,
      );
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error saving task: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Créer une tâche', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF0F2648))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F2648)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                validator: (v) => v!.isEmpty ? 'Titre requis' : null,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Nom de la tâche',
                  hintText: 'ex: Pose de fenêtre spéciale',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 20),
              
              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Notes / Description',
                  hintText: 'Détails techniques, instructions...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 24),
              
              // Images
              Text('Photos', style: AppTheme.headingStyle(context).copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Icon(Icons.add_a_photo, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ..._selectedImages.map((f) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(f, width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4, top: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.remove(f)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Products
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Produits par défaut', style: AppTheme.headingStyle(context).copyWith(fontSize: 16)),
                  TextButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              if (_selectedProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Aucun produit sélectionné', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
              
              ..._selectedProducts.entries.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.darkNavy),
                  title: FutureBuilder(
                    future: ref.read(productRepositoryProvider).getProducts(), // Correct method name
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Text(e.key); // Fallback ID
                      final prod = (snapshot.data as List<Product>).firstWhere((p) => p.id == e.key, orElse: () => Product(id: e.key, name: 'Produit inconnu', imageUrl: '', priceHT: 0, unit: ''));
                      return Text(prod.name);
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Text('x${e.value}'),
                       IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _selectedProducts.remove(e.key)))
                    ],
                  ),
                ),
              )),
              
              const SizedBox(height: 40),
              
              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                   ? const CircularProgressIndicator(color: Colors.white) 
                   : const Text('Enregistrer la tâche', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
