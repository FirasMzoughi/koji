import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChantierRdvScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChantierRdvScreen({super.key, required this.data});

  @override
  State<ChantierRdvScreen> createState() => _ChantierRdvScreenState();
}

class _ChantierRdvScreenState extends State<ChantierRdvScreen> {
  static const _kDark = Color(0xFF0F172A);

  late List<Map<String, dynamic>> _rdvList;

  @override
  void initState() {
    super.initState();
    _rdvList = List<Map<String, dynamic>>.from(
      (widget.data['rdv'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
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
                onTap: _addRdv,
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
                        'Ajouter un rendez-vous',
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
              child: _rdvList.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
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
            'Prochain rendez-vous',
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
            'Aucun rendez-vous planifié',
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
      itemCount: _rdvList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildRdvTile(_rdvList[i]),
    );
  }

  Widget _buildRdvTile(Map<String, dynamic> rdv) {
    final String day = rdv['day'] as String? ?? '—';
    final String month = rdv['month'] as String? ?? '—';
    final String time = rdv['time'] as String? ?? '—';
    final String title = rdv['title'] as String? ?? 'Rendez-vous';
    final String person = rdv['person'] as String? ?? '';

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day $month',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFE2E8F0),
          ),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                if (person.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        person,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addRdv() {
    final titleCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Nouveau rendez-vous',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Ex: Installation Pompe à chaleur',
                    hintStyle: TextStyle(fontFamily: 'Outfit')),
                style: const TextStyle(fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: personCtrl,
                decoration: const InputDecoration(
                    hintText: 'Ex: M. Robert Durand',
                    hintStyle: TextStyle(fontFamily: 'Outfit')),
                style: const TextStyle(fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setDs(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedDate.day} / ${selectedDate.month} / ${selectedDate.year}',
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: _kDark),
                      ),
                    ],
                  ),
                ),
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
                  final months = [
                    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
                  ];
                  setState(() {
                    _rdvList.add({
                      'day': '${selectedDate.day}',
                      'month': months[selectedDate.month - 1],
                      'time': '10:00',
                      'title': titleCtrl.text.trim(),
                      'person': personCtrl.text.trim(),
                    });
                    widget.data['rdv'] = _rdvList;
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
      ),
    );
  }
}
