import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChantierAFaireScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChantierAFaireScreen({super.key, required this.data});

  @override
  State<ChantierAFaireScreen> createState() => _ChantierAFaireScreenState();
}

class _ChantierAFaireScreenState extends State<ChantierAFaireScreen> {
  static const _kDark = Color(0xFF0F172A);

  // Sample tasks — in a real app these come from the chantier data
  late List<Map<String, dynamic>> _tasks;

  @override
  void initState() {
    super.initState();
    final existingTasks = widget.data['afaire'] as List?;
    if (existingTasks == null || existingTasks.isEmpty) {
      _tasks = [
        {'title': 'Début peinture', 'subtitle': 'J - 2', 'done': false},
        {'title': 'Validation devis élec', 'subtitle': 'Client', 'done': false},
        {'title': 'Commander carrelage', 'subtitle': 'Fourniture', 'done': false},
      ];
      widget.data['afaire'] = _tasks;
    } else {
      _tasks = List<Map<String, dynamic>>.from(existingTasks.cast<Map<String, dynamic>>());
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: _tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _buildTaskTile(_tasks[i]),
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

  Widget _buildTaskTile(Map<String, dynamic> task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: _kDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] as String,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task['subtitle'] as String,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nouvelle tâche',
          style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: _kDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Titre (ex: Début peinture)',
                hintStyle: TextStyle(fontFamily: 'Outfit'),
              ),
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: subCtrl,
              decoration: const InputDecoration(
                hintText: 'Sous-titre (ex: J - 2)',
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
                style: TextStyle(
                    fontFamily: 'Outfit', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _tasks.add({
                    'title': titleCtrl.text.trim(),
                    'subtitle': subCtrl.text.trim(),
                    'done': false,
                  });
                  widget.data['afaire'] = _tasks;
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Ajouter',
                style:
                    TextStyle(fontFamily: 'Outfit', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
