import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:koji/models/trade_data.dart';
import 'package:koji/providers/trade_dashboard_provider.dart';

class JobPostsTableWidget extends StatelessWidget {
  final SelectedRoom room;
  final Function(JobPost) onPostUpdated;
  final Function(String) onPostRemoved;
  final Function(String) onAddCustomPost;

  const JobPostsTableWidget({
    super.key,
    required this.room,
    required this.onPostUpdated,
    required this.onPostRemoved,
    required this.onAddCustomPost,
  });

  void _showAddCustomPostDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un poste personnalisé'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom du poste',
            hintText: 'Ex: Traitement spécial...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAddCustomPost(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Postes - ${room.name}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF263238),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddCustomPostDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un poste'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF1A237E).withOpacity(0.1),
            ),
            columns: const [
              DataColumn(label: Text('Poste')),
              DataColumn(label: Text('Unité')),
              DataColumn(label: Text('Quantité')),
              DataColumn(label: Text('Prix MO (€)')),
              DataColumn(label: Text('Prix Four. (€)')),
              DataColumn(label: Text('Total HT (€)')),
              DataColumn(label: Text('')),
            ],
            rows: [
              ...room.posts.map((post) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          post.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      DropdownButton<JobUnit>(
                        value: post.unit,
                        underline: const SizedBox(),
                        items: JobUnit.values.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit.displayName),
                          );
                        }).toList(),
                        onChanged: (newUnit) {
                          if (newUnit != null) {
                            onPostUpdated(post.copyWith(unit: newUnit));
                          }
                        },
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          controller: TextEditingController(
                            text: post.quantity > 0 ? post.quantity.toString() : '',
                          ),
                          onChanged: (value) {
                            final qty = double.tryParse(value) ?? 0;
                            onPostUpdated(post.copyWith(quantity: qty));
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          controller: TextEditingController(
                            text: post.laborPrice > 0
                                ? post.laborPrice.toString()
                                : '',
                          ),
                          onChanged: (value) {
                            final price = double.tryParse(value) ?? 0;
                            onPostUpdated(post.copyWith(laborPrice: price));
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          controller: TextEditingController(
                            text: post.suppliesPrice > 0
                                ? post.suppliesPrice.toString()
                                : '',
                          ),
                          onChanged: (value) {
                            final price = double.tryParse(value) ?? 0;
                            onPostUpdated(post.copyWith(suppliesPrice: price));
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        currencyFormat.format(post.totalHT),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red.shade400,
                        onPressed: () => onPostRemoved(post.id),
                      ),
                    ),
                  ],
                );
              }),
              // Ligne de total
              DataRow(
                color: WidgetStateProperty.all(
                  const Color(0xFFFF6F00).withOpacity(0.1),
                ),
                cells: [
                  const DataCell(
                    Text(
                      'TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  DataCell(
                    Text(
                      currencyFormat.format(
                        room.posts.fold(0.0, (sum, post) => sum + post.totalHT),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFFF6F00),
                      ),
                    ),
                  ),
                  const DataCell(Text('')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
