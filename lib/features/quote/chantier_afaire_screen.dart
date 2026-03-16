import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/quote/providers/chantier_provider.dart';
import 'package:koji/features/quote/repositories/chantier_repository.dart';

class ChantierAFaireScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const ChantierAFaireScreen({super.key, required this.data});

  @override
  ConsumerState<ChantierAFaireScreen> createState() => _ChantierAFaireScreenState();
}

class _ChantierAFaireScreenState extends ConsumerState<ChantierAFaireScreen> {
  static const _kDark = Color(0xFF0F172A);

  final _repository = ChantierRepository();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final chantierId = widget.data['id'] as String?;
    
    // Fallback if no ID is provided
    if (chantierId == null) {
      return const Scaffold(body: Center(child: Text("ID Chantier manquant")));
    }

    final tasksAsync = ref.watch(chantierTasksProvider(chantierId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: GestureDetector(
                onTap: _addTask,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kDark,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _kDark.withValues(alpha: 0.15),
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
                        'Ajouter une tâche',
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
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _kDark)),
                error: (err, stack) => Center(child: Text('Erreur: $err')),
                data: (tasks) {
                  final activeTasks = tasks.where((t) => t['is_done'] != true).toList();
                  final archivedTasks = tasks.where((t) => t['is_done'] == true).toList();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: CustomScrollView(
                    slivers: [
                      if (activeTasks.isEmpty && archivedTasks.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'Aucune tâche pour le moment',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        
                      if (activeTasks.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final task = activeTasks[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTaskTile(
                                  task,
                                  i,
                                  false,
                                  () async {
                                    try {
                                      await _repository.updateTaskStatus(task['id'], true);
                                    } catch (e) {
                                      debugPrint('Error toggling task: $e');
                                    }
                                  },
                                ),
                              );
                            },
                            childCount: activeTasks.length,
                          ),
                        ),
                        
                      if (archivedTasks.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.archive_outlined, color: Color(0xFF64748B), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Archives (${archivedTasks.length})',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                      if (archivedTasks.isNotEmpty)
                         SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final task = archivedTasks[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTaskTile(
                                  task,
                                  i,
                                  true,
                                  () async {
                                    try {
                                      await _repository.updateTaskStatus(task['id'], false);
                                    } catch (e) {
                                      debugPrint('Error toggling task: $e');
                                    }
                                  },
                                ),
                              );
                            },
                            childCount: archivedTasks.length,
                          ),
                        ),
                    ],
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F0EB),
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
            'À faire',
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

  Widget _buildTaskTile(
      Map<String, dynamic> task, int index, bool isDone, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDone ? const Color(0xFF94A3B8) : _kDark,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nouvelle tâche',
          style: TextStyle(
              fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: _kDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Titre de la tâche',
                hintStyle: TextStyle(fontFamily: 'Outfit'),
              ),
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style:
                    TextStyle(fontFamily: 'Outfit', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                final chantierId = widget.data['id'] as String?;
                if (chantierId != null) {
                  Navigator.pop(ctx);
                  try {
                    await _repository.addTask(
                        chantierId, titleCtrl.text.trim());
                  } catch (e) {
                    debugPrint('Error adding task: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Ajouter',
                style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
