import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChantierListScreen extends ConsumerStatefulWidget {
  const ChantierListScreen({super.key});

  @override
  ConsumerState<ChantierListScreen> createState() => _ChantierListScreenState();
}

class _ChantierListScreenState extends ConsumerState<ChantierListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    "Tous",
    "En cours",
    "Acceptés",
    "Refusés",
  ];

  // Mock data matching the UI exactly
  final List<Map<String, dynamic>> _mockChantiers = [
    {
      'name': 'Jean Dupont',
      'type': 'Rénovation Cuisine',
      'ref': '#DEV-2026-010',
      'date': '24 Oct',
      'status': 'En cours',
      'price': '4 500 €',
    },
    {
      'name': 'Carla Balti',
      'type': 'Sous sol',
      'ref': '#DEV-2026-120',
      'date': '4 Oct',
      'status': 'Accepté',
      'price': '12 500 €',
    },
    {
      'name': 'Marie Martin',
      'type': 'Installattion SDB',
      'ref': '#DEV-2026-020',
      'date': '21 Oct',
      'status': 'Refusé',
      'price': '500 €',
      'hasTrash': true,
    },
    {
      'name': 'Carla Balti',
      'type': 'Sous sol',
      'ref': '#DEV-2026-120',
      'date': '4 Oct',
      'status': 'Accepté',
      'price': '12 500 €',
    },
    {
      'name': 'Jean Dupont',
      'type': 'Rénovation Cuisine',
      'ref': '#DEV-2026-010',
      'date': '24 Oct',
      'status': 'En cours',
      'price': '4 500 €',
    },
    {
      'name': 'Carla Balti',
      'type': 'Sous sol',
      'ref': '#DEV-2026-120',
      'date': '4 Oct',
      'status': 'Terminé',
      'price': '12 500 €',
      'hasTrash': true,
      'hasDownload': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    'Chantiers',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  // Bell Icon
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_none_outlined,
                          color: Color(0xFF0F172A),
                          size: 24,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444), // Red dot
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _tabController.index == index;
                  return GestureDetector(
                    onTap: () {
                      _tabController.animateTo(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0A1128) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: _mockChantiers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _mockChantiers[index];
                  return _buildChantierCard(item, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChantierCard(Map<String, dynamic> item, BuildContext context) {
    return GestureDetector(
      onTap: () {
         // Create mock extra data to pass to dashboard
         final Map<String, dynamic> extraData = {
           'reference': item['ref'],
           // Dummy budget values
           'mainOeuvreReal': 2500.0,
           'mainOeuvreEstimated': 3000.0,
           'fournitureReal': 1500.0,
           'fournitureEstimated': 2000.0,
         };
         context.push('/chantier/dashboard', extra: extraData);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['type']} • ${item['ref']}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['date'],
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatusChip(item['status']),
                    if (item['hasTrash'] == true) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.delete_outline,
                          color: Color(0xFFEF4444), size: 22),
                    ],
                    if (item['hasDownload'] == true) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.file_download_outlined,
                          color: Color(0xFF3B82F6), size: 22),
                    ],
                  ],
                ),
                Text(
                  item['price'],
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'En cours':
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF3B82F6);
        icon = Icons.circle; // small dot
        break;
      case 'Accepté':
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF10B981);
        icon = Icons.check_circle;
        break;
      case 'Terminé':
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF10B981);
        icon = Icons.check_circle;
        break;
      case 'Refusé':
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFEF4444);
        icon = Icons.cancel;
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}