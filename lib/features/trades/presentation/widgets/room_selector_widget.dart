import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koji/providers/trade_dashboard_provider.dart';

class RoomSelectorWidget extends ConsumerStatefulWidget {
  final Function(String) onRoomAdded;
  final List<SelectedRoom> rooms;
  final Function(String) onRoomRemoved;

  const RoomSelectorWidget({
    super.key,
    required this.onRoomAdded,
    required this.rooms,
    required this.onRoomRemoved,
  });

  @override
  ConsumerState<RoomSelectorWidget> createState() =>
      _RoomSelectorWidgetState();
}

class _RoomSelectorWidgetState extends ConsumerState<RoomSelectorWidget> {
  final List<String> _defaultRooms = [
    'Salon',
    'Chambre',
    'Cuisine',
    'Salle de bain',
    'Couloir',
    'Entrée',
  ];

  void _showAddRoomDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une pièce'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nom de la pièce',
                hintText: 'Ex: Bureau, Garage...',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onRoomAdded(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showRoomSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner une pièce'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _defaultRooms.map((room) {
              return ListTile(
                title: Text(room),
                leading: const Icon(Icons.room_outlined),
                onTap: () {
                  widget.onRoomAdded(room);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pièces',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _showRoomSelectionDialog,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Pièce type'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showAddRoomDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Personnalisée'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.rooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.room_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune pièce sélectionnée',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez une pièce pour commencer',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.rooms.map((room) {
              return Chip(
                label: Text(room.name),
                avatar: const Icon(Icons.room, size: 18),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => widget.onRoomRemoved(room.id),
                backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
