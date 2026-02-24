import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ChantierDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChantierDocumentsScreen({super.key, required this.data});

  @override
  State<ChantierDocumentsScreen> createState() =>
      _ChantierDocumentsScreenState();
}

class _ChantierDocumentsScreenState extends State<ChantierDocumentsScreen> {
  static const _kDark = Color(0xFF0F172A);
  static const _kBg = Color(0xFFF5F0EB);

  late List<Map<String, dynamic>> _docs;

  @override
  void initState() {
    super.initState();
    _docs = List<Map<String, dynamic>>.from(
      (widget.data['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: GestureDetector(
                onTap: _showAddOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kDark,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _kDark.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Ajouter un document',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _docs.isEmpty ? _buildEmpty() : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.chevron_left_rounded,
                  color: _kDark, size: 30),
            ),
          ),
          const Text(
            'Ajouter Documents',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 38),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Aucune Document',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: _docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildDocTile(_docs[i], i),
    );
  }

  Widget _buildDocTile(Map<String, dynamic> doc, int index) {
    final String name = doc['name'] as String? ?? 'Document';
    final String date = doc['date'] as String? ?? '—';
    final String size = doc['size'] as String? ?? '—';
    final bool isImage = doc['isImage'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImage
                  ? Icons.add_photo_alternate_outlined
                  : Icons.description_outlined,
              color: _kDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$date  $size',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Three-dot menu
          GestureDetector(
            onTap: () => _showDocMenu(context, index),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.more_vert_rounded,
                  color: Color(0xFF64748B), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _showDocMenu(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            _menuOption(
              icon: Icons.download_outlined,
              label: 'Télécharger',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _menuOption(
              icon: Icons.share_outlined,
              label: 'Partager',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _menuOption(
              icon: Icons.delete_outline_rounded,
              label: 'Supprimer',
              color: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                setState(() => _docs.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF0F172A),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final ImagePicker _picker = ImagePicker();

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            _menuOption(
              icon: Icons.camera_alt_outlined,
              label: 'Prendre une photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _menuOption(
              icon: Icons.photo_library_outlined,
              label: 'Choisir depuis la galerie',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        final length = await image.length();
        final sizeMb = (length / (1024 * 1024)).toStringAsFixed(1);
        final dateStr = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
        
        setState(() {
          _docs.add({
            'name': image.name.isNotEmpty ? image.name : 'Photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            'date': dateStr,
            'size': '${sizeMb} MB',
            'isImage': true,
            'path': image.path,
          });
          widget.data['documents'] = _docs;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
}
