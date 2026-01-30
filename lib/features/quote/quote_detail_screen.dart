import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/quote/model/expense_item.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:koji/features/quote/repository/quote_repository.dart';
import 'package:intl/intl.dart';



class QuoteDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const QuoteDetailScreen({super.key, required this.data});

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  bool _isEditing = false;
  late Map<String, List<ExpenseItem>> _expensesByRoom;
  late List<String> _rooms;
  Map<String, dynamic> _roomTasks = {};

  // Header State Variables
  String _companyName = "Koji ";
  String _companyAddress = "8 Av. des artisans, Paris";
  String _companyPhone = "01 42 55 000 77";
  String _companyEmail = "Contact@Koji.fr";
  
  String _clientName = "M. Dubois";
  String _clientAddress = "12 Rue de la Paix, 75001 Paris";
  String _clientEmail = "client@email.com";
  
  String _quoteNumber = "D - 29 - 2025";
  String _quoteDate = "12 Oct 2023";
  String _quoteValidity = "30 Jours";
  
  String _siteAddress = "12 Rue de la Paix, 75001 Paris";
  
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    
    // Check if editing existing quote (has ID)
    final isExisting = widget.data.containsKey('id');
    
    if (isExisting) {
      _loadExistingQuote();
    } else {
      _initializeNewQuote();
    }
  }

    void _initializeNewQuote() {
    // Standard initialization from potential previous steps
    _expensesByRoom = {};
    if (widget.data['expenses'] != null) {
      (widget.data['expenses'] as Map<String, dynamic>).forEach((key, value) {
         if (value is List && value.isNotEmpty && value.first is ExpenseItem) {
           _expensesByRoom[key] = List<ExpenseItem>.from(value);
         }
      });
    }
    _rooms = _expensesByRoom.keys.toList();
    
    // Initialize Client Info from data if available
    if (widget.data['client'] != null) {
      final client = widget.data['client'] as Map<String, dynamic>;
      _clientName = client['name'] ?? _clientName;
      _clientAddress = client['address'] ?? _clientAddress;
      _clientEmail = client['email'] ?? _clientEmail;
      // Add other fields if QuoteDetailScreen supports them
    }

    if (widget.data['tasks'] != null) {
      _roomTasks = widget.data['tasks'] as Map<String, dynamic>;
    }
    
    // Default values
    _quoteNumber = 'D-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _quoteDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    // Fetch user business info
    _fetchBusinessInfo();
  }

  void _loadExistingQuote() {
    final data = widget.data;
    _quoteNumber = data['quoteNumber'] ?? '';
    _quoteDate = data['date'] ?? '';
    _quoteValidity = data['validity'] ?? '30 Jours';
    
    // Helper function to safely convert Maps
    Map<String, dynamic> _safeMapConvert(dynamic field) {
      if (field == null) return {};
      if (field is Map<String, dynamic>) return field;
      if (field is Map) return Map<String, dynamic>.from(field);
      return {};
    }
    
    final client = _safeMapConvert(data['client']);
    _clientName = client['name'] ?? '';
    _clientAddress = client['address'] ?? '';
    _clientEmail = client['email'] ?? '';
    
    final company = _safeMapConvert(data['company']);
    _companyName = company['name'] ?? _companyName;
    _companyAddress = company['address'] ?? _companyAddress;
    _companyPhone = company['phone'] ?? _companyPhone;
    _companyEmail = company['email'] ?? _companyEmail;
    
    _siteAddress = data['siteAddress'] ?? '';

    // Parse Expenses from JSON
    _expensesByRoom = {};
    if (data['expenses'] != null) {
      final expensesMap = _safeMapConvert(data['expenses']);
      expensesMap.forEach((key, value) {
        if (value is List) {
          _expensesByRoom[key] = value.map((e) {
             final item = _safeMapConvert(e);
             return ExpenseItem(
               id: item['id'] ?? UniqueKey().toString(),
               title: item['title'] ?? '',
               subtitle: item['subtitle'] ?? '',
               icon: Icons.circle,
               laborCost: (item['laborCost'] as num?)?.toDouble() ?? 0.0,
               materialCost: (item['materialCost'] as num?)?.toDouble() ?? 0.0,
               quantity: (item['quantity'] as num?)?.toDouble() ?? 1.0,
             );
          }).toList();
        }
      });
    }
    _rooms = _expensesByRoom.keys.toList();
  }


  Future<void> _fetchBusinessInfo() async {
    final user = ref.read(authProvider).value;
    if (user != null) {
      final userData = await ref.read(userRepositoryProvider).getUser(user.id);
      
      if (userData != null) {
        // Get logo URL from Supabase
        final logoUrl = userData['logo_url'] as String?;
        
        // Get business info
        final biz = userData['business_info'] as Map<String, dynamic>?;
        
        if (mounted) {
          setState(() {
            _logoPath = logoUrl; // Now stores URL instead of local path
            if (biz != null) {
              _companyName = biz['raisonSociale'] ?? _companyName;
              _companyAddress = biz['address'] ?? _companyAddress;
              _companyPhone = biz['phone'] ?? _companyPhone;
              _companyEmail = biz['emailPro'] ?? _companyEmail;
            }
          });
        }
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
     // Here you would typically save to backend or pass back
     _toggleEditMode();
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Modifications enregistrées"), backgroundColor: Color(0xFF22C55E)),
     );
  }

  void _cancelChanges() {
     // Revert changes
     setState(() {
       _expensesByRoom = {};
       if (widget.data['expenses'] != null) {
         (widget.data['expenses'] as Map<String, List<ExpenseItem>>).forEach((key, value) {
           _expensesByRoom[key] = List.from(value);
         });
       }
       _rooms = _expensesByRoom.keys.toList();
       
       // Note: We might want to revert header changes too if we stored original values
       // For now, assuming header changes persist for session convenience or separate tracking
       
       _isEditing = false;
     });
  }
  
  void _addRoom() {
    setState(() {
      String newRoomId = "pièce_${_rooms.length + 1}";
      _rooms.add(newRoomId);
      _expensesByRoom[newRoomId] = [];
    });
  }

  void _deleteRoom(String roomId) {
    setState(() {
      _rooms.remove(roomId);
      _expensesByRoom.remove(roomId);
    });
  }
  
  void _addTask(String room) {
     setState(() {
       _expensesByRoom[room]?.add(
          ExpenseItem(
            id: DateTime.now().toString(),
            title: "Nouvelle tâche",
            subtitle: "Description...",
            icon: Icons.build_circle_outlined,
            laborCost: 0,
            materialCost: 0,
            quantity: 1,
          )
       );
     });
  }

  void _deleteTask(String room, ExpenseItem item) {
    setState(() {
      _expensesByRoom[room]?.remove(item);
    });
  }

  Future<void> _generateQuote() async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur: Utilisateur non connecté")));
      return;
    }

    // Identify total amount
    double totalHT = 0;
    _expensesByRoom.forEach((_, items) {
      for (var item in items) {
        totalHT += item.total;
      }
    });
    double tva = totalHT * 0.10; 
    double totalTTC = totalHT + tva;

    // Prepare Data
    final quoteData = {
      'quoteNumber': _quoteNumber,
      'createdAt': DateTime.now().toIso8601String(),
      'validity': _quoteValidity,
      'date': _quoteDate,
      
      'client': {
        'name': _clientName,
        'address': _clientAddress,
        'email': _clientEmail,
      },
      'company': {
        'name': _companyName,
        'address': _companyAddress,
        'phone': _companyPhone,
        'email': _companyEmail,
      },
      'siteAddress': _siteAddress,
      
      'expenses': _expensesByRoom.map((key, value) => MapEntry(key, value.map((e) => {
        'id': e.id,
        'title': e.title,
        'subtitle': e.subtitle,
        // 'icon': e.icon.codePoint, // Store icon code point if needed, or skip
        'laborCost': e.laborCost,
        'materialCost': e.materialCost,
        'quantity': e.quantity,
      }).toList())),
      
      'tasks': _roomTasks, // Persist rich task data including selected products
      
      'totals': {
        'ht': totalHT,
        'tva': tva,
        'ttc': totalTTC,
      }
    };

    try {
      // Save to Supabase
      String? existingId = widget.data['id'];
      final quoteId = await ref.read(quoteRepositoryProvider).saveQuote(user.id, quoteData, quoteId: existingId);
      
      if (mounted) {
         context.go('/quote/success', extra: {
           'quoteId': quoteId, 
           'quoteData': { ...quoteData, 'id': quoteId }
         });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la sauvegarde: $e")));
      }
    }
  }

  void _updateItem(String room, ExpenseItem oldItem, {String? title, double? qty, double? labor, double? material}) {
    setState(() {
      final index = _expensesByRoom[room]?.indexOf(oldItem) ?? -1;
      if (index != -1) {
        _expensesByRoom[room]?[index] = ExpenseItem(
          id: oldItem.id,
          title: title ?? oldItem.title,
          subtitle: oldItem.subtitle,
          icon: oldItem.icon,
          quantity: qty ?? oldItem.quantity,
          laborCost: labor ?? oldItem.laborCost,
          materialCost: material ?? oldItem.materialCost,
        );
      }
    });
  }

// ... existing build method ...

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
           ),
        ],
      ),
      child: Column(
        children: [
          // Company Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _logoPath != null ? Colors.white : AppTheme.darkNavy,
                  borderRadius: BorderRadius.circular(12),
                  image: _logoPath != null
                      ? DecorationImage(
                          image: NetworkImage(_logoPath!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _logoPath == null
                    ? const Icon(Icons.edit_note, color: Colors.white)
                    : null, // Logo placeholder
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEditableText(_companyName, isBold: true, fontSize: 16, onChanged: (v) => _companyName = v),
                    const SizedBox(height: 4),
                    _buildEditableIconText(Icons.location_on_outlined, _companyAddress, (v) => _companyAddress = v),
                    _buildEditableIconText(Icons.phone_outlined, _companyPhone, (v) => _companyPhone = v),
                    _buildEditableIconText(Icons.email_outlined, _companyEmail, (v) => _companyEmail = v),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                   color: const Color(0xFFF3E5D8),
                   borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text("DEVIS N°", style: TextStyle(fontFamily: 'Outfit', fontSize: 8, color: const Color(0xFFA18B73))),
                    _buildEditableText(_quoteNumber, isBold: true, fontSize: 10, color: AppTheme.darkNavy, onChanged: (v) => _quoteNumber = v),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
           const SizedBox(height: 24),
           
           // Client Row
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 12, color: Color(0xFFA18B73)),
                          const SizedBox(width: 4),
                          Text("CLIENT", style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFA18B73))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Container(
                             width: 32,
                             height: 32,
                             decoration: const BoxDecoration(
                               color: Color(0xFFF3E5D8),
                               shape: BoxShape.circle,
                             ),
                             child: const Center(child: Icon(Icons.person_outline, color: Color(0xFFA18B73), size: 18)),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 _buildEditableText(_clientName, isBold: true, fontSize: 14, onChanged: (v) => _clientName = v),
                                 _buildEditableText(_clientAddress, fontSize: 10, color: AppTheme.textLight, onChanged: (v) => _clientAddress = v),
                                 const SizedBox(height: 4),
                                 _buildEditableIconText(Icons.email_outlined, _clientEmail, (v) => _clientEmail = v),
                               ],
                             ),
                           )
                        ],
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                     Text("DATE", style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFA18B73))),
                     _buildEditableText(_quoteDate, fontSize: 12, color: AppTheme.darkNavy, onChanged: (v) => _quoteDate = v),
                     const SizedBox(height: 8),
                     Text("VALIDITE", style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFA18B73))),
                     _buildEditableText(_quoteValidity, fontSize: 12, color: AppTheme.darkNavy, onChanged: (v) => _quoteValidity = v),
                  ],
                )
             ],
           ),
           
            const SizedBox(height: 24),
            
            // Location Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3E5D8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFA18B73)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text("Lieu du chantier", style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: const Color(0xFFA18B73))),
                         _buildEditableText(_siteAddress, isBold: true, fontSize: 12, onChanged: (v) => _siteAddress = v),
                      ],
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildEditableText(String value, {bool isBold = false, double fontSize = 14, Color? color, required Function(String) onChanged}) {
    if (_isEditing) {
      return TextFormField(
        initialValue: value,
        style: TextStyle(fontFamily: 'Outfit', 
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
          color: color ?? AppTheme.darkNavy,
        ),
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
        onChanged: onChanged,
      );
    }
    return Text(
      value,
      style: TextStyle(fontFamily: 'Outfit', 
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontSize: fontSize,
        color: color ?? AppTheme.darkNavy,
      ),
    );
  }

  Widget _buildEditableIconText(IconData icon, String text, Function(String) onChanged) {
    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFFA18B73)),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                initialValue: text,
                style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.textLight),
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      );
    }
    return _buildIconText(icon, text);
  }

  Widget _buildIconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFFA18B73)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // Calculate totals
    double totalHT = 0;
    _expensesByRoom.forEach((_, items) {
      for (var item in items) {
        totalHT += item.total;
      }
    });
    double tva = totalHT * 0.10; // Assuming 10% TVA
    double totalTTC = totalHT + tva;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkNavy, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Détails de la Pièce(s)',
              style: AppTheme.headingStyle(context).copyWith(fontSize: 18),
            ),
             Text(
              'Etape 6/5', // Visual indication of next step
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 12,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsive.width(5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Company & Client Card
              _buildHeaderCard(),
              
              const SizedBox(height: 24),
              
              // 2. Chantier Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Détails du chantier',
                    style: AppTheme.headingStyle(context).copyWith(fontSize: 18),
                  ),
                  if (!_isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5D8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_rooms.length} Pièces",
                        style: TextStyle(fontFamily: 'Outfit', 
                          color: AppTheme.darkNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                     ElevatedButton.icon(
                        onPressed: _addRoom,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Ajouter une pièce"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6), // Blue as per design
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          textStyle: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                     )
                ],
              ),
              const SizedBox(height: 16),
              
              // 3. Rooms Iteration
              if (_rooms.isEmpty)
                 Padding(
                   padding: const EdgeInsets.all(20.0),
                   child: Center(
                     child: Text(
                       "Aucun détail disponible. Ajoutez une pièce.",
                       style: TextStyle(fontFamily: 'Outfit', color: AppTheme.textLight),
                     )
                   ),
                 ),
              
              ..._rooms.map((room) {
                 final items = _expensesByRoom[room] ?? [];
                 // Calculate room total
                 double roomTotal = items.fold(0, (sum, item) => sum + item.total);
                 return _buildRoomAccordion(room, items, roomTotal);
              }),
              
              const SizedBox(height: 32),
              
              // 4. Financial Recap
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RECAPULATIF FINANCIER",
                      style: TextStyle(fontFamily: 'Outfit', 
                        color: AppTheme.darkNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecapRow("Total HT", totalHT),
                    const SizedBox(height: 8),
                    _buildRecapRow("TVA (10%)", tva),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total TTC",
                              style: TextStyle(fontFamily: 'Outfit', 
                                color: const Color(0xFF6B7280),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                             Text(
                              "Payable à la commande",
                              style: TextStyle(fontFamily: 'Outfit', 
                                color: const Color(0xFF9CA3AF),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${totalTTC.toStringAsFixed(2)} €",
                          style: TextStyle(fontFamily: 'Outfit', 
                            color: const Color(0xFF4B4B4B), // Dark grey
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
               const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _isEditing ? 
          // Edit Mode Footer
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _saveChanges, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkNavy,
                  foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   minimumSize: const Size(double.infinity, 50),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  "Enregistrer les modifications",
                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _cancelChanges,
                child: Text(
                  "Annuler",
                  style: TextStyle(fontFamily: 'Outfit', 
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          )
          : 
          // Default Footer
          Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleEditMode,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(
                  "Modifier",
                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkNavy,
                  side: const BorderSide(color: AppTheme.darkNavy),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2, // Bigger button
              child: ElevatedButton(
                onPressed: _generateQuote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.data.containsKey('id') ? 'Mettre à jour' : 'Générer le Devis',
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Outfit', 
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
        Text(
          "${value.toStringAsFixed(2)} €",
          style: TextStyle(fontFamily: 'Outfit', 
            color: const Color(0xFF4B4B4B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomAccordion(String roomName, List<ExpenseItem> items, double roomTotal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
       decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6), // Light beige background like screenshot
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DCC5)), // Slight border
      ),
      child: ExpansionTile(
        initiallyExpanded: true, // As per screenshot
        shape: const Border(), // Remove default border
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _isEditing 
                ? TextFormField(
                    initialValue: _getRoomLabel(roomName),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkNavy),
                    // If we wanted to edit room names, we'd need more complex key management.
                    // For now, let's keep room names static or simple.
                    readOnly: true, // Making readonly for now to simplify key tracking
                  )
                : Text(
                    _getRoomLabel(roomName),
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.darkNavy,
                    ),
                  ),
            ),
             if (_isEditing)
               IconButton(
                 icon: const Icon(Icons.delete_outline, color: Colors.red),
                 onPressed: () => _deleteRoom(roomName),
               )
             else
               Text(
                "${roomTotal.toStringAsFixed(2)} €",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.darkNavy,
                ),
              ),
          ],
        ),
        subtitle: Text(
          "${items.length} prestations",
          style: TextStyle(fontFamily: 'Outfit', color: AppTheme.textLight, fontSize: 12),
        ),
        children: [
          // Tasks Inclus Header with Add button if editing
          if (_isEditing)
             Padding(
               padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
               child: Row(
                 children: [
                   const Spacer(),
                   InkWell(
                     onTap: () => _addTask(roomName),
                     child: Padding(
                       padding: const EdgeInsets.all(4.0),
                       child: Row(
                         children: [
                            const Icon(Icons.add, color: Color(0xFF3B82F6), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "Ajouter",
                              style: TextStyle(fontFamily: 'Outfit', 
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 12
                              ),
                            )
                         ],
                       ),
                     ),
                   )
                 ],
               ),
             ),
             
          ...items.map((item) => _buildDetailItem(roomName, item)).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String room, ExpenseItem item) {
    // Replicating the detailed card inside the accordion
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Total
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isEditing 
                  ? TextFormField(
                      initialValue: item.title,
                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none, hintText: "Titre"),
                      onChanged: (val) => _updateItem(room, item, title: val),
                    )
                  : Text(
                      item.title, // "Démolition carrelage"
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.darkNavy,
                      ),
                    ),
              ),
              if (_isEditing)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  onPressed: () => _deleteTask(room, item),
                )
              else
                Text(
                  "${item.total.toStringAsFixed(2)} €",
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkNavy,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (!_isEditing)
            // Tag (e.g. Sol)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getLocationTag(item.id), // "Sol", "Murs", etc.
                style: TextStyle(fontFamily: 'Outfit', 
                  color: AppTheme.textLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Tasks Included (Static for now as it's not in the main model cleanly yet)
          if (!_isEditing) ...[
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: const Color(0xFFF9FAFB),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: const Color(0xFFF3F4F6)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text("Taches inclus", style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: const Color(0xFF6B7280), fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   if (_roomTasks[room] != null && _roomTasks[room]['tasks'] != null)
                     ...(_roomTasks[room]['tasks'] as List).map((t) => Column(
                       children: [
                         _buildTaskRow(t.toString()),
                         const SizedBox(height: 4),
                       ],
                     ))
                   else
                     const Text("Aucune tâche spécifique", style: TextStyle(fontSize: 10, color: Colors.grey)),
                 ],
               ),
            ),
             const SizedBox(height: 16),
          ],

          
          // Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 3, child: Text("ÉLÉMENT", style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF)))),
              Expanded(flex: 2, child: Center(child: Text("QTÉ", style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF))))),
              Expanded(flex: 2, child: Center(child: Text( _isEditing ? "PRIX U." : "PRIX U.", style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF))))),
              if (!_isEditing)
                 Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text("TOTAL", style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF))))),
            ],
          ),
          const SizedBox(height: 8),
          // Main d'oeuvre Row
          _buildEditPriceRow(
             "Main d...", 
             item.quantity, 
             item.laborCost, 
             (val) => _updateItem(room, item, qty: val),
             (val) => _updateItem(room, item, labor: val),
          ),
          const SizedBox(height: 8),
          // Matériel Row
           _buildEditPriceRow(
             "Matériel", 
             item.quantity, 
             item.materialCost, 
             (val) => _updateItem(room, item, qty: val),
             (val) => _updateItem(room, item, material: val),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPriceRow(String label, double qty, double unitPrice, Function(double) onQtyChanged, Function(double) onPriceChanged) {
     return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3, 
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: label.startsWith("Main") ? const Color(0xFFD97706) : const Color(0xFFFCD34D), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
                  ],
                )
              ),
              Expanded(
                flex: 2, 
                child: Center(
                  child: _isEditing 
                  ? SizedBox(
                      width: 50,
                      child: TextFormField(
                        initialValue: qty.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.darkNavy),
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 2), border: OutlineInputBorder()),
                        onChanged: (val) => onQtyChanged(double.tryParse(val) ?? 0),
                      ),
                    )
                  : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(4)),
                    child: Text("${qty.toInt()} m²", style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.textLight)),
                  )
                )
              ),
              Expanded(
                flex: 2, 
                child: Center(
                  child: _isEditing 
                  ? SizedBox(
                       width: 50,
                       child: TextFormField(
                        initialValue: unitPrice.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.darkNavy),
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 2), border: OutlineInputBorder()),
                        onChanged: (val) => onPriceChanged(double.tryParse(val) ?? 0),
                      ),
                    )
                  : Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                     decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(4)),
                     child: Text("${unitPrice.toInt()} €", style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.textLight)),
                  )
                )
              ),
              if (!_isEditing)
                Expanded(
                  flex: 2, 
                  child: Align(
                    alignment: Alignment.centerRight, 
                    child: Text("${(qty * unitPrice).toStringAsFixed(2)} €", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkNavy))
                  )
                ),
            ],
          );
  }

  Widget _buildTaskRow(String task) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         const Padding(
           padding: EdgeInsets.only(top: 3),
           child: Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 10), // Green check
         ),
         const SizedBox(width: 6),
         Expanded(child: Text(task, style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: AppTheme.darkNavy, fontWeight: FontWeight.w500))),
      ],
    );
  }


  
  String _getRoomLabel(String id) {
    switch (id) {
      case 'salon': return 'Salon';
      case 'cuisine': return 'Cuisine';
      case 'chambre': return 'Chambre';
      case 'salle_de_bain': return 'Salle de bain';
      case 'bureau': return 'Bureau';
      case 'exterieur': return 'Extérieur';
      default: return id.capitalize();
    }
  }

  String _getLocationTag(String id) {
     if (id.toLowerCase().contains('mur')) return "Murs";
     if (id.toLowerCase().contains('plafond')) return "Plafond";
     if (id.toLowerCase().contains('sol')) return "Sol";
     if (id.toLowerCase().contains('bois')) return "Boiseries";
     if (id.toLowerCase().contains('elec')) return "Élec";
     if (id.toLowerCase().contains('plomb')) return "Plomberie";
     return "Général";
  }
}

extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return "";
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}
