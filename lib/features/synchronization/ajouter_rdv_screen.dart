import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/synchronization/data/worker_model.dart';

class AjouterRdvScreen extends StatefulWidget {
  final Worker? worker;
  const AjouterRdvScreen({super.key, this.worker});

  @override
  State<AjouterRdvScreen> createState() => _AjouterRdvScreenState();
}

class _AjouterRdvScreenState extends State<AjouterRdvScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;
  int _selectedHour = 2;
  int _selectedMinute = 0;
  String _selectedDuration = '1h';
  final List<String> _durations = ['30 min', '1h', '2h', '½ journée', 'Journée'];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkNavy = Color(0xFF0A1227);
    const appBg = Color(0xFFFBFBFC);

    final monthNames = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];

    return Scaffold(
      backgroundColor: appBg,
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFBE4D2).withValues(alpha: 0.6),
                    const Color(0xFFFBE4D2).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: darkNavy.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.chevron_left,
                              color: darkNavy, size: 28),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "Ajouter un RDV",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: darkNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // Scrollable form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Intitulé
                        const Text(
                          "Intitulé",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFEEF2F6)),
                          ),
                          child: TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontSize: 15,
                              color: darkNavy,
                            ),
                            decoration: InputDecoration(
                              hintText: "Ex: Pose carrelage",
                              hintStyle: TextStyle(
                                color: const Color(0xFF8B95A5)
                                    .withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Calendar
                        _buildCalendar(darkNavy, monthNames),

                        const SizedBox(height: 28),

                        // Time Picker
                        const Center(
                          child: Text(
                            "Choisissez L'heure",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkNavy,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildTimePicker(darkNavy),

                        const SizedBox(height: 28),

                        // Duration
                        const Text(
                          "Durée",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkNavy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDurationChips(darkNavy),

                        const SizedBox(height: 28),

                        // Ajouter une personne
                        const Text(
                          "Ajouter une personne",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFEEF2F6)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  child: Text(
                                    widget.worker != null
                                        ? "${widget.worker!.firstName} ${widget.worker!.lastName}"
                                        : "Invité un sous-traitant / Ouvrier",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: widget.worker != null
                                          ? darkNavy
                                          : const Color(0xFF8B95A5)
                                              .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 12),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2F6),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Color(0xFF8B95A5),
                                      size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Note
                        const Text(
                          "Note",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFEEF2F6)),
                          ),
                          child: TextField(
                            controller: _noteController,
                            maxLines: 3,
                            style: const TextStyle(
                              fontSize: 15,
                              color: darkNavy,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  "Informations complémentaires...",
                              hintStyle: TextStyle(
                                color: const Color(0xFF8B95A5)
                                    .withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Conflict warning
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0)
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFFF9800), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Conflit avec un autre RDV (Pose fenêtre)",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFFFF9800)
                                        .withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enregistrer button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24.0, right: 24.0, bottom: 32.0),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Save RDV to Supabase
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('RDV enregistré avec succès!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    context.pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E65F3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Enregistrer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CALENDAR ──────────────────────────
  Widget _buildCalendar(Color darkNavy, List<String> monthNames) {
    final dayHeaders = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final today = DateTime.now();

    List<Widget> cells = [];

    // Headers
    for (final d in dayHeaders) {
      cells.add(Center(
        child: Text(
          d,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8B95A5),
            letterSpacing: 0.5,
          ),
        ),
      ));
    }

    // Previous month
    final prevEnd =
        DateTime(_currentMonth.year, _currentMonth.month, 0).day;
    for (int i = startWeekday - 1; i > 0; i--) {
      cells.add(Center(
        child: Text(
          "${prevEnd - i + 1}",
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF8B95A5).withValues(alpha: 0.35),
          ),
        ),
      ));
    }

    // Current month
    for (int day = 1; day <= lastDay.day; day++) {
      final isToday = today.day == day &&
          today.month == _currentMonth.month &&
          today.year == _currentMonth.year;
      final isSelected = _selectedDay == day;

      cells.add(GestureDetector(
        onTap: () => setState(() => _selectedDay = day),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2E65F3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$day",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? const Color(0xFF2E65F3)
                          : darkNavy,
                ),
              ),
              if (isToday && !isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E65F3),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "${monthNames[_currentMonth.month]} ${_currentMonth.year}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.calendar_month,
                      size: 18, color: darkNavy),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _currentMonth = DateTime(
                          _currentMonth.year, _currentMonth.month - 1);
                    }),
                    child: Icon(Icons.chevron_left,
                        color: darkNavy, size: 22),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _currentMonth = DateTime(
                          _currentMonth.year, _currentMonth.month + 1);
                    }),
                    child: Icon(Icons.chevron_right,
                        color: darkNavy, size: 22),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
            children: cells,
          ),
        ],
      ),
    );
  }

  // ─── TIME PICKER ───────────────────────
  Widget _buildTimePicker(Color darkNavy) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hours
          Column(
            children: [
              GestureDetector(
                onTap: () => setState(() =>
                    _selectedHour = (_selectedHour + 1) % 24),
                child: Text(
                  "${(_selectedHour + 1).toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF2E65F3).withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedHour.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() =>
                    _selectedHour = (_selectedHour - 1 + 24) % 24),
                child: Text(
                  "${(_selectedHour - 1 + 24) % 24}".padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF2E65F3).withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              ":",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
          ),

          // Minutes
          Column(
            children: [
              GestureDetector(
                onTap: () => setState(() =>
                    _selectedMinute = (_selectedMinute + 5) % 60),
                child: Text(
                  "${(_selectedMinute + 5) % 60}".padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF2E65F3).withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedMinute.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() =>
                    _selectedMinute = (_selectedMinute - 5 + 60) % 60),
                child: Text(
                  "${(_selectedMinute - 5 + 60) % 60}".padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF2E65F3).withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DURATION CHIPS ────────────────────
  Widget _buildDurationChips(Color darkNavy) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _durations.map((d) {
        final isSelected = _selectedDuration == d;
        return GestureDetector(
          onTap: () => setState(() => _selectedDuration = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2E65F3)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: isSelected
                  ? null
                  : Border.all(color: const Color(0xFFE0E7FF)),
            ),
            child: Text(
              d,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : darkNavy,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
