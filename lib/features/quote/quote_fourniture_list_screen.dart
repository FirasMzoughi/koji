import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/fournitures/repository/fourniture_repository.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';

class QuoteFournitureListScreen extends ConsumerWidget {
  const QuoteFournitureListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quoteCreationProvider);
    final catalogAsync = ref.watch(allFournituresProvider);

    // ── Collect items already selected in tasks ──────────────────────────────
    final List<Map<String, dynamic>> selectedItems = [];
    double totalMaterialCost = 0.0;

    state.roomTasks.forEach((roomId, taskDetails) {
      if (taskDetails is Map) {
        taskDetails.forEach((taskId, taskData) {
          if (taskData is Map) {
            final selectedFournitures = taskData['selectedFournitures'];
            if (selectedFournitures is Map) {
              selectedFournitures.forEach((_, productData) {
                if (productData is Map) {
                  final name = productData['name']?.toString() ??
                      productData['title']?.toString() ??
                      'Produit';
                  final qty =
                      (productData['quantity'] as num?)?.toDouble() ?? 1.0;
                  final unitPrice =
                      (productData['unitPrice'] as num?)?.toDouble() ?? 0.0;
                  if (unitPrice > 0 || qty > 0) {
                    final totalLine = qty * unitPrice;
                    final fournisseur =
                        productData['fournisseur']?.toString().trim() ?? '';
                    selectedItems.add({
                      'title': name,
                      'quantity': qty,
                      'unitPrice': unitPrice,
                      'total': totalLine,
                      'fournisseur': fournisseur,
                    });
                    totalMaterialCost += totalLine;
                  }
                }
              });
            }
          }
        });
      }
    });

    // ── If nothing selected, fall back to showing the full catalog ───────────
    final List<Map<String, dynamic>> allItems = selectedItems.isNotEmpty
        ? selectedItems
        : catalogAsync.maybeWhen(
            data: (items) => items
                .map((f) => {
                      'title': f.name,
                      'quantity': 1.0,
                      'unitPrice': f.prixVenteHT,
                      'total': f.prixVenteHT,
                      'fournisseur': f.fournisseurName ?? '',
                    })
                .toList(),
            orElse: () => <Map<String, dynamic>>[],
          );

    final bool isCatalogFallback = selectedItems.isEmpty && allItems.isNotEmpty;
    if (isCatalogFallback) {
      totalMaterialCost = 0.0;
      for (final i in allItems) {
        totalMaterialCost += (i['total'] as num).toDouble();
      }
    }

    // ── Group by fournisseur ─────────────────────────────────────────────────
    // Preserve insertion order; "Divers" always last.
    final Map<String, List<Map<String, dynamic>>> byFournisseur =
        {};
    for (final item in allItems) {
      final key = (item['fournisseur'] as String).isEmpty
          ? 'Divers'
          : item['fournisseur'] as String;
      byFournisseur.putIfAbsent(key, () => []).add(item);
    }

    // Move "Divers" to the end if present
    final divers = byFournisseur.remove('Divers');
    final orderedKeys = byFournisseur.keys.toList();
    if (divers != null) {
      byFournisseur['Divers'] = divers;
      orderedKeys.add('Divers');
    }

    final totalItemsCount = allItems.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.darkNavy, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Liste des fournitures',
          style: AppTheme.headingStyle(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: byFournisseur.isEmpty
            ? catalogAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur de chargement du catalogue: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
                data: (_) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune fourniture disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // ── Total header ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    decoration: const BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isCatalogFallback
                              ? 'Catalogue des fournitures'
                              : 'Total estimé des matériaux',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isCatalogFallback
                              ? '$totalItemsCount fourniture${totalItemsCount > 1 ? 's' : ''}'
                              : '${totalMaterialCost.toStringAsFixed(2)} €',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statChip(
                              context,
                              '$totalItemsCount élément${totalItemsCount > 1 ? 's' : ''}',
                            ),
                            const SizedBox(width: 8),
                            _statChip(
                                context,
                                '${byFournisseur.keys.where((k) => k != 'Divers').length} fournisseur${byFournisseur.keys.where((k) => k != 'Divers').length > 1 ? 's' : ''}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Grouped list ────────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      itemCount: orderedKeys.length,
                      itemBuilder: (context, index) {
                        final fournisseurName = orderedKeys[index];
                        final items = byFournisseur[fournisseurName]!;
                        final isDivers = fournisseurName == 'Divers';
                        final groupTotal = items.fold<double>(
                            0, (sum, i) => sum + (i['total'] as double));

                        return _FournisseurGroup(
                          name: fournisseurName,
                          items: items,
                          groupTotal: groupTotal,
                          isDivers: isDivers,
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
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkNavy,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Retour au résumé',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.surface),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.surface,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Fournisseur group card ───────────────────────────────────────────────────

class _FournisseurGroup extends StatefulWidget {
  final String name;
  final List<Map<String, dynamic>> items;
  final double groupTotal;
  final bool isDivers;

  const _FournisseurGroup({
    required this.name,
    required this.items,
    required this.groupTotal,
    required this.isDivers,
  });

  @override
  State<_FournisseurGroup> createState() => _FournisseurGroupState();
}

class _FournisseurGroupState extends State<_FournisseurGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  // Avatar / icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isDivers
                          ? const Color(0xFFF1F5F9)
                          : AppTheme.darkNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: widget.isDivers
                        ? const Icon(Icons.category_outlined,
                            color: Color(0xFF94A3B8), size: 20)
                        : Center(
                            child: Text(
                              widget.name.isNotEmpty
                                  ? widget.name[0].toUpperCase()
                                  : 'F',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Name + count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.items.length} fourniture${widget.items.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Group total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.groupTotal.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'H.T',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF94A3B8), size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────
          if (_expanded)
            const Divider(height: 1, indent: 16, endIndent: 16,
                color: Color(0xFFF1F5F9)),

          // ── Items ─────────────────────────────────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: widget.items
                    .map((item) => _FournitureRow(item: item))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Single fourniture row inside a group ────────────────────────────────────

class _FournitureRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FournitureRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Bullet icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.build_circle_outlined,
                color: AppTheme.darkNavy, size: 16),
          ),
          const SizedBox(width: 12),

          // Name + qty × price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(item['quantity'] as double).toStringAsFixed(item['quantity'] == item['quantity'].roundToDouble() ? 0 : 2)} × '
                  '${(item['unitPrice'] as double).toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Line total
          Text(
            '${(item['total'] as double).toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }
}
