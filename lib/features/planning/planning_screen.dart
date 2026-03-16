import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/synchronization/data/project_model.dart';
import 'package:koji/features/synchronization/data/project_repository.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final ProjectRepository _repository = ProjectRepository();
  bool _isDayView = true;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Project> _projects = [];
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  // Color palette for mission cards
  static const List<Color> _missionColors = [
    Color(0xFF2E65F3), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final projects = await _repository.fetchProjects();
      final tasks = await _repository.fetchUserPlanning(_selectedDate);
      if (mounted) {
        setState(() {
          _projects = projects;
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading planning: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Get the start of the week (Monday) for the selected date
  DateTime get _weekStart {
    final weekday = _selectedDate.weekday; // 1=Mon, 7=Sun
    return _selectedDate.subtract(Duration(days: weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    const darkNavy = Color(0xFF0A1227);
    const appBg = Color(0xFFFBFBFC);

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(darkNavy),

                // Toggle
                _buildViewToggle(darkNavy),

                const SizedBox(height: 20),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF2E65F3)))
                      : _isDayView
                          ? _buildDayView(darkNavy)
                          : _buildMonthView(darkNavy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ───────────────────────────────
  Widget _buildHeader(Color darkNavy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
              child: Icon(Icons.chevron_left, color: darkNavy, size: 28),
            ),
          ),
          Expanded(
            child: Text(
              "Planning individuelle",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ─── VIEW TOGGLE ──────────────────────────
  Widget _buildViewToggle(Color darkNavy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: darkNavy.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isDayView = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _isDayView ? darkNavy : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Jour",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _isDayView ? Colors.white : darkNavy,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isDayView = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: !_isDayView ? darkNavy : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Mois",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: !_isDayView ? Colors.white : darkNavy,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  DAY VIEW
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildDayView(Color darkNavy) {
    final weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final weekStart = _weekStart;

    // Format month name
    final monthNames = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final monthName = monthNames[_selectedDate.month];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Semaine du ${weekStart.day} $monthName",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
              Row(
                children: [
                  Text(
                    "$monthName ${_selectedDate.year}",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: const Color(0xFF8B95A5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.calendar_month,
                      size: 18, color: const Color(0xFF8B95A5)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Week Day Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final date = weekStart.add(Duration(days: index));
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Column(
                  children: [
                    Text(
                      weekDays[index],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? darkNavy
                            : const Color(0xFF8B95A5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? darkNavy : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${date.day}",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : darkNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // Missions du jour header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Missions du jour",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkNavy,
                ),
              ),
              Text(
                "${_tasks.length} Chantiers",
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: Color(0xFF8B95A5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mission Cards
          if (_tasks.isEmpty)
            _buildDayEmptyState()
          else
            ...List.generate(_tasks.length, (index) {
              return _buildMissionCard(_tasks[index], index);
            }),

          // Mock missions if no real tasks
          if (_tasks.isEmpty) ...[
            _buildMockMissionCard(
              time: "08:30",
              duration: "2h30",
              title: "Installation Pompe à chaleur",
              client: "M. Robert Durand",
              tag: "Peinture Salon & Entrée",
              color: _missionColors[0],
              hasPointer: true,
            ),
            _buildMockMissionCard(
              time: "14:00",
              duration: "4h00",
              title: "Rénovation Électrique",
              client: "Résidence Les Oliviers",
              tag: "+1 ouvrier",
              color: _missionColors[1],
              status: "En attente",
            ),
            _buildMockMissionCard(
              time: "18:00",
              duration: "1h00",
              title: "Rendez-vous Devis",
              client: "Résidence Les Oliviers",
              tag: "+1 ouvrier",
              color: _missionColors[2],
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDayEmptyState() {
    // We'll show mock data, so this is just a placeholder
    return const SizedBox.shrink();
  }

  Widget _buildMissionCard(TaskItem task, int index) {
    final color = _missionColors[index % _missionColors.length];
    final startTime = task.startTime ?? "09:00";
    final duration = task.duration ?? "2h00";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startTime,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Color(0xFF8B95A5),
                  ),
                ),
              ],
            ),
          ),
          // Colored line
          Container(
            width: 4,
            height: 90,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          // Card content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskName,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1227),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: Color(0xFF8B95A5)),
                      const SizedBox(width: 4),
                      Text(
                        task.roomName,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: Color(0xFF8B95A5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockMissionCard({
    required String time,
    required String duration,
    required String title,
    required String client,
    required String tag,
    required Color color,
    bool hasPointer = false,
    String? status,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Color(0xFF8B95A5),
                  ),
                ),
              ],
            ),
          ),
          // Colored line
          Container(
            width: 4,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          // Card content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1227),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: Color(0xFF8B95A5)),
                      const SizedBox(width: 4),
                      Text(
                        client,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: Color(0xFF8B95A5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Worker avatars (mock)
                      ...List.generate(
                        hasPointer ? 2 : 1,
                        (i) => Container(
                          width: 28,
                          height: 28,
                          margin: EdgeInsets.only(right: i == 0 ? 0 : 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(Icons.person,
                              size: 16, color: Colors.blueGrey[300]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (tag.isNotEmpty)
                        Row(
                          children: [
                            if (!tag.startsWith('+'))
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              tag,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: Color(0xFF8B95A5),
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      if (hasPointer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1227),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Pointer",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (status != null)
                        Text(
                          status,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: Color(0xFF8B95A5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  MONTH VIEW
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildMonthView(Color darkNavy) {
    final monthNames = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final monthName = monthNames[_currentMonth.month];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "$monthName ${_currentMonth.year}",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_month,
                      size: 20, color: darkNavy),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _currentMonth = DateTime(
                          _currentMonth.year, _currentMonth.month - 1);
                    }),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEF2F6)),
                      ),
                      child: Icon(Icons.chevron_left,
                          color: darkNavy, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _currentMonth = DateTime(
                          _currentMonth.year, _currentMonth.month + 1);
                    }),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEF2F6)),
                      ),
                      child: Icon(Icons.chevron_right,
                          color: darkNavy, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Calendar Grid
          _buildCalendarGrid(darkNavy),

          const SizedBox(height: 28),

          // Aperçu du mois
          Text(
            "Aperçu du mois",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkNavy,
            ),
          ),

          const SizedBox(height: 16),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_month,
                  label: "Jours de travail",
                  value: "20 jours",
                  darkNavy: darkNavy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time_rounded,
                  label: "Total heures",
                  value: "152 hrs",
                  darkNavy: darkNavy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Chantiers principaux
          Text(
            "Chantiers principaux",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkNavy,
            ),
          ),

          const SizedBox(height: 16),

          // Chantier list
          if (_projects.isEmpty)
            ...[
              _buildChantierItem("Résidence Les Pins", "12 jours - Peinture",
                  _missionColors[0], darkNavy),
              _buildChantierItem("Appartement Durand", "5 jours - Enduit",
                  _missionColors[2], darkNavy),
              _buildChantierItem("Résidence Les Pins", "8 jours - Électricité",
                  _missionColors[1], darkNavy),
            ]
          else
            ...List.generate(
              _projects.length > 5 ? 5 : _projects.length,
              (index) {
                final project = _projects[index];
                return _buildChantierItem(
                  project.title,
                  "${project.status} - ${project.clientName}",
                  _missionColors[index % _missionColors.length],
                  darkNavy,
                );
              },
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Color darkNavy) {
    final dayHeaders = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday; // 1=Monday
    final today = DateTime.now();

    // Build calendar cells
    List<Widget> cells = [];

    // Day headers
    for (final d in dayHeaders) {
      cells.add(Center(
        child: Text(
          d,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8B95A5),
            letterSpacing: 0.5,
          ),
        ),
      ));
    }

    // Previous month fill
    final prevMonthEnd =
        DateTime(_currentMonth.year, _currentMonth.month, 0).day;
    for (int i = startWeekday - 1; i > 0; i--) {
      cells.add(Center(
        child: Text(
          "${prevMonthEnd - i + 1}",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: const Color(0xFF8B95A5).withValues(alpha: 0.4),
          ),
        ),
      ));
    }

    // Current month days
    for (int day = 1; day <= lastDay.day; day++) {
      final isToday = today.day == day &&
          today.month == _currentMonth.month &&
          today.year == _currentMonth.year;

      // Mock: some days have events
      final hasEvent = day % 7 == 1 || day % 7 == 6;

      cells.add(GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = DateTime(
                _currentMonth.year, _currentMonth.month, day);
            _isDayView = true;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isToday ? darkNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$day",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isToday ? Colors.white : darkNavy,
                ),
              ),
              if (hasEvent && !isToday)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 6,
                  height: 6,
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

    // Next month fill to complete the grid
    final remaining = 7 - (cells.length - 7) % 7;
    if (remaining < 7) {
      for (int i = 1; i <= remaining; i++) {
        cells.add(Center(
          child: Text(
            "$i",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: const Color(0xFF8B95A5).withValues(alpha: 0.4),
            ),
          ),
        ));
      }
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
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
        children: cells,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color darkNavy,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: darkNavy),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: Color(0xFF8B95A5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChantierItem(
      String title, String subtitle, Color color, Color darkNavy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Color(0xFF8B95A5),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: const Color(0xFF8B95A5), size: 22),
        ],
      ),
    );
  }
}
