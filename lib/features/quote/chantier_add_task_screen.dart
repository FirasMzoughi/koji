import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChantierAddTaskScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChantierAddTaskScreen({super.key, required this.data});

  @override
  State<ChantierAddTaskScreen> createState() => _ChantierAddTaskScreenState();
}

class _ChantierAddTaskScreenState extends State<ChantierAddTaskScreen> {
  static const _kDark = Color(0xFF0F172A);
  static const _kBg = Color(0xFFF5F0EB);
  static const _kBorder = Color(0xFFE2E8F0);

  late List<Map<String, dynamic>> _tasks;
  bool _showForm = false;

  // Form state
  final _titleCtrl = TextEditingController();
  final _personCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _lierA = 'Aucun';

  final List<String> _lierAOptions = [
    'Aucun',
    'Budget',
    'Devis',
    'Prochain RDV',
    'Documents',
  ];

  @override
  void initState() {
    super.initState();
    _tasks = List<Map<String, dynamic>>.from(
      (widget.data['afaire'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _personCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            if (!_showForm)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _showForm = true),
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
              child: _showForm
                  ? _buildForm()
                  : (_tasks.isEmpty ? _buildEmpty() : _buildTaskList()),
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
              onTap: () {
                if (_showForm) {
                  setState(() => _showForm = false);
                } else {
                  context.pop();
                }
              },
              child: const Icon(Icons.chevron_left_rounded,
                  color: _kDark, size: 30),
            ),
          ),
          const Text(
            'Ajouter tâche',
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

  // ── Empty state ──
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
            'Aucune tâche',
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

  // ── Task list ──
  Widget _buildTaskList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildTaskTile(i),
    );
  }

  Widget _buildTaskTile(int i) {
    final task = _tasks[i];
    final bool done = task['done'] as bool? ?? false;
    final String title = task['title'] as String? ?? '';
    final String subtitle = task['subtitle'] as String? ?? '';

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
          // Circle checkbox
          GestureDetector(
            onTap: () => setState(() => _tasks[i]['done'] = !done),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? _kDark : Colors.white,
                border: Border.all(
                  color: done ? _kDark : const Color(0xFFCBD5E1),
                  width: 1.8,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                    decoration:
                        done ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8), size: 22),
        ],
      ),
    );
  }

  // ── Add form ──
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intitulé *
          _label('Intitulé', required: true),
          _field(
            controller: _titleCtrl,
            hint: 'Ex: Commander carrelage',
          ),
          const SizedBox(height: 20),

          // Date
          _label('Date'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                        : '10/27/2023',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: _selectedDate != null
                          ? _kDark
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      size: 20, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Lier à
          _label('Lier à'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _lierA,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF94A3B8)),
                style: const TextStyle(
                    fontFamily: 'Outfit', fontSize: 14, color: _kDark),
                items: _lierAOptions
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => setState(() => _lierA = v ?? 'Aucun'),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Personne
          _label('Personne'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 20, color: Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _personCtrl,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Sélectionner un contact',
                      hintStyle: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          color: Color(0xFF94A3B8)),
                    ),
                    style: const TextStyle(
                        fontFamily: 'Outfit', fontSize: 14, color: _kDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Note (optionnel)
          _label('Note (optionnel)'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              controller: _noteCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Ajouter des détails...',
                hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: Color(0xFF94A3B8)),
              ),
              style: const TextStyle(
                  fontFamily: 'Outfit', fontSize: 14, color: _kDark),
            ),
          ),
          const SizedBox(height: 32),

          // Enregistrer
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kDark,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(
      {required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          hintText: hint,
          hintStyle: const TextStyle(
              fontFamily: 'Outfit', fontSize: 14, color: Color(0xFF94A3B8)),
        ),
        style: const TextStyle(
            fontFamily: 'Outfit', fontSize: 14, color: _kDark),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveTask() {
    if (_titleCtrl.text.trim().isEmpty) return;

    final now = DateTime.now();
    final date = _selectedDate ?? now;
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isTomorrow =
        date.difference(DateTime(now.year, now.month, now.day)).inDays == 1;

    String subtitle;
    if (isToday) {
      subtitle = "Aujourd'hui";
    } else if (isTomorrow) {
      subtitle = 'Demain';
    } else {
      final months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      subtitle = '${date.day} ${months[date.month - 1]}';
    }

    setState(() {
      _tasks.add({
        'title': _titleCtrl.text.trim(),
        'subtitle': subtitle,
        'done': false,
        'lierA': _lierA,
        'person': _personCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
      });
      widget.data['afaire'] = _tasks;
      // Reset form
      _titleCtrl.clear();
      _personCtrl.clear();
      _noteCtrl.clear();
      _selectedDate = null;
      _lierA = 'Aucun';
      _showForm = false;
    });
  }
}
