import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:koji/models/trade_data.dart';
import 'package:koji/providers/trade_dashboard_provider.dart';
import 'package:koji/features/trades/presentation/widgets/room_selector_widget.dart';
import 'package:koji/features/trades/presentation/widgets/job_posts_table_widget.dart';
import 'package:koji/features/trades/presentation/widgets/tasks_checklist_widget.dart';

class TradeDashboardScreen extends ConsumerWidget {
  final Trade trade;

  const TradeDashboardScreen({
    super.key,
    required this.trade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(tradeDashboardProvider(trade));
    final notifier = ref.read(tradeDashboardProvider(trade).notifier);
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard ${trade.displayName}'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // En-tête avec total
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A237E).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForTrade(trade),
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      trade.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total HT',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(dashboardState.totalHT),
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.room,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${dashboardState.rooms.length} pièce(s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Section Pièces
          RoomSelectorWidget(
            rooms: dashboardState.rooms,
            onRoomAdded: (roomName) => notifier.addRoom(roomName),
            onRoomRemoved: (roomId) => notifier.removeRoom(roomId),
          ),
          const SizedBox(height: 32),

          // Section Postes par pièce
          if (dashboardState.rooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ajoutez une pièce pour voir les postes',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...dashboardState.rooms.map((room) {
              return Column(
                children: [
                  JobPostsTableWidget(
                    room: room,
                    onPostUpdated: (post) => notifier.updatePost(room.id, post),
                    onPostRemoved: (postId) => notifier.removePost(room.id, postId),
                    onAddCustomPost: (postName) =>
                        notifier.addCustomPost(room.id, postName),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),

          const Divider(height: 48),

          // Section Tâches détaillées
          TasksChecklistWidget(
            tasks: dashboardState.globalTasks,
            onTaskToggled: (taskId) => notifier.toggleTask(taskId),
            onTaskRemoved: (taskId) => notifier.removeTask(taskId),
            onAddCustomTask: (taskName) => notifier.addCustomTask(taskName),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  IconData _getIconForTrade(Trade trade) {
    switch (trade) {
      case Trade.painter:
        return Icons.format_paint;
      case Trade.electrician:
        return Icons.electric_bolt;
      case Trade.plumber:
        return Icons.water_drop;
      case Trade.tiler:
        return Icons.grid_view;
      case Trade.carpenter:
        return Icons.carpenter;
      case Trade.tce:
        return Icons.construction;
      case Trade.drywall:
        return Icons.layers;
      case Trade.masonry:
        return Icons.foundation;
      default:
        return Icons.handyman;
    }
  }
}
