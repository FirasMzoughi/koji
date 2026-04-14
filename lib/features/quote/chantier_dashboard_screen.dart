import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/quote/providers/chantier_provider.dart';
import 'package:koji/features/quote/repositories/chantier_repository.dart';

class ChantierDashboardScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const ChantierDashboardScreen({super.key, required this.data});

  @override
  ConsumerState<ChantierDashboardScreen> createState() =>
      _ChantierDashboardScreenState();
}

class _ChantierDashboardScreenState extends ConsumerState<ChantierDashboardScreen> {
  final _repository = ChantierRepository();
  @override
  void initState() {
    super.initState();
  }

  String get _chantierName =>
      widget.data['reference'] as String? ?? 'Mon Chantier';

  // ──────────────────────────────────────────
  // Bottom sheet: "Ajouter tâche"
  // ──────────────────────────────────────────
  void _showAddMenu() {
    final data = widget.data;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMenuSheet(
        onItemTap: (label) {
          Navigator.of(context).pop();
          switch (label) {
            case 'À faire':
              context.push('/chantier/afaire', extra: data);
              break;
            case 'Budget':
              context.push('/chantier/budget', extra: data);
              break;
            case 'Devis':
              context.push('/chantier/devis', extra: data);
              break;
            case 'Prochain rendez-vous':
              context.push('/chantier/rdv', extra: data);
              break;
            case 'Ajouter tâche':
              context.push('/chantier/add-task', extra: data);
              break;
            case 'Documents':
              context.push('/chantier/documents', extra: data);
              break;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chantierId = widget.data['id'] as String?;
    
    // Fallback if no ID is provided
    if (chantierId == null) {
      return const Scaffold(body: Center(child: Text("ID Chantier manquant")));
    }

    final tasksAsync = ref.watch(chantierTasksProvider(chantierId));
    final budgetAsync = ref.watch(chantierBudgetProvider(chantierId));
    final documentsAsync = ref.watch(chantierDocumentsProvider(chantierId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      floatingActionButton: _buildFAB(),
      body: SafeArea(
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
          error: (err, stack) => Center(child: Text('Erreur: $err')),
          data: (tasks) {
            return budgetAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
              error: (err, stack) => Center(child: Text('Erreur Budget: $err')),
              data: (budget) {
                return documentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                  error: (err, stack) => Center(child: Text('Erreur Documents: $err')),
                  data: (documents) {
                    return CustomScrollView(
                      slivers: [
                        // ── App Bar ──
                        SliverToBoxAdapter(child: _buildAppBar()),

                        // ── Cards ──
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildAFaireCard(tasks),
                              const SizedBox(height: 14),
                              _buildBudgetCard(budget),
                              const SizedBox(height: 14),
                              _buildDevisRdvRow(), 
                              const SizedBox(height: 14),
                              _buildDocumentsCard(documents),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF0F172A),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  ' Chantier',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _chantierName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Info button
          GestureDetector(
            onTap: () => context.push('/chantier/info', extra: widget.data),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  Widget _buildAFaireCard(List<Map<String, dynamic>> tasks) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 18, color: Color(0xFF0F172A)),
              const SizedBox(width: 8),
              const Text(
                'À faire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Checklist
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Aucune tâche pour le moment',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ),
          ...tasks.asMap().entries.map((e) {
            final task = e.value;
            final bool isDone = task['is_done'] == true;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () async {
                  try {
                    await _repository.updateTaskStatus(task['id'], !isDone);
                  } catch (err) {
                    debugPrint('Error updating task: $err');
                  }
                },
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF0F172A) : Colors.white,
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDone
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  Widget _buildBudgetCard(Map<String, dynamic>? budget) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text(
                'Budget',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBudgetRow(
            'Main d\'œuvre',
            num.tryParse(budget?['main_oeuvre_real']?.toString() ?? '0') ?? 0,
            num.tryParse(
                    budget?['main_oeuvre_estimated']?.toString() ?? '0') ??
                0,
          ),
          const SizedBox(height: 14),
          _buildBudgetRow(
            'Fourniture',
            num.tryParse(budget?['fourniture_real']?.toString() ?? '0') ?? 0,
            num.tryParse(budget?['fourniture_estimated']?.toString() ?? '0') ??
                0,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow(String label, num actual, num estimated) {
    // Prevent division by zero, format appropriately.
    final ratio = estimated > 0 ? (actual / estimated).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${actual}€ ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextSpan(
                    text: '/ $estimated €',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Réel/ Estimé',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFFCBD5E1),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  Widget _buildDevisRdvRow() {
    return Row(
      children: [
        // Devis card
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/chantier/devis', extra: widget.data),
            child: _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 16, color: Color(0xFF0F172A)),
                      SizedBox(width: 6),
                      Text(
                        'Devis',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '0',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Aucun devis',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // RDV card
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/chantier/rdv', extra: widget.data),
            child: _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: Color(0xFF0F172A)),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Prochain RDV',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Réunion chantier',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Demain, 09:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  Widget _buildDocumentsCard(List<Map<String, dynamic>> documents) {
    return GestureDetector(
      onTap: () => context.push('/chantier/documents', extra: widget.data),
      child: _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.folder_outlined,
                        size: 18, color: Color(0xFF0F172A)),
                    SizedBox(width: 8),
                    Text(
                      'Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${documents.length} total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (documents.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                        color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            documents.first['name'] as String? ?? 'Document sans nom',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Récent',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Aucun document',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddMenu,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 4,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}

// ─────────────────────────────────────────────────────
// Reusable white card wrapper
// ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────
// Bottom Sheet: "Ajouter tâche" navigation menu
// ─────────────────────────────────────────────────────
class _AddMenuSheet extends StatelessWidget {
  final void Function(String label) onItemTap;

  const _AddMenuSheet({required this.onItemTap});

  static const _items = [
    'À faire',
    'Budget',
    'Devis',
    'Prochain rendez-vous',
    'Ajouter tâche',
    'Documents',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ajouter tâche',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child:
                    const Icon(Icons.close, color: Color(0xFF94A3B8), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Menu items
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MenuTile(
                label: item,
                onTap: () => onItemTap(item),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
