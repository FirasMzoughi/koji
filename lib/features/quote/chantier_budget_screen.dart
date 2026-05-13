import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koji/features/quote/repositories/chantier_repository.dart';

class ChantierBudgetScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChantierBudgetScreen({super.key, required this.data});

  @override
  State<ChantierBudgetScreen> createState() => _ChantierBudgetScreenState();
}

class _ChantierBudgetScreenState extends State<ChantierBudgetScreen> {
  static const _kDark = Color(0xFF0F172A);

  final _repository = ChantierRepository();
  bool _isLoading = true;

  double _mainOeuvreReal = 0;
  double _mainOeuvreEst = 0;
  double _fournitureReal = 0;
  double _fournitureEst = 0;
  double _diversReal = 0;
  double _diversEst = 0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final chantierId = widget.data['id'] as String?;
    if (chantierId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final budget = await _repository.getBudget(chantierId);
      if (mounted && budget != null) {
        setState(() {
          _mainOeuvreReal =
              num.tryParse(budget['main_oeuvre_real']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _mainOeuvreEst =
              num.tryParse(budget['main_oeuvre_estimated']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _fournitureReal =
              num.tryParse(budget['fourniture_real']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _fournitureEst =
              num.tryParse(budget['fourniture_estimated']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _diversReal =
              num.tryParse(budget['divers_real']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _diversEst =
              num.tryParse(budget['divers_estimated']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading budget: $e');
      if (mounted) setState(() => _isLoading = false);
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
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kDark))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: _buildBudgetCard(
                        mainOeuvreReal: _mainOeuvreReal,
                        mainOeuvreEst: _mainOeuvreEst,
                        fournitureReal: _fournitureReal,
                        fournitureEst: _fournitureEst,
                        diversReal: _diversReal,
                        diversEst: _diversEst,
                      ),
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
            'Budget',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard({
    required double mainOeuvreReal,
    required double mainOeuvreEst,
    required double fournitureReal,
    required double fournitureEst,
    required double diversReal,
    required double diversEst,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _kDark,
                ),
              ),
              Icon(Icons.touch_app_outlined,
                  size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Touchez une ligne pour modifier, ou + pour ajouter',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          _buildBudgetRow(
            label: "Main d'œuvre",
            real: mainOeuvreReal,
            estimated: mainOeuvreEst,
            showAddButton: true,
          ),
          const SizedBox(height: 20),
          _buildBudgetRow(
            label: 'Fourniture',
            real: fournitureReal,
            estimated: fournitureEst,
            showAddButton: true,
          ),
          const SizedBox(height: 20),
          _buildBudgetRow(
            label: 'Divers',
            real: diversReal,
            estimated: diversEst,
            showAddButton: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow({
    required String label,
    required double real,
    required double estimated,
    bool showAddButton = false,
  }) {
    final bool overBudget = real > estimated;
    final double progress =
        estimated > 0 ? (real / estimated).clamp(0.0, 1.0) : 0.0;
    final Color barColor = overBudget ? const Color(0xFFEF4444) : _kDark;

    final String realStr = _fmt(real);
    final String estStr = _fmt(estimated);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (label == "Main d'œuvre") {
                    _editBudget(
                        label, 'mainOeuvreReal', 'mainOeuvreEstimated', real, estimated);
                  } else if (label == 'Divers') {
                    _editBudget(
                        label, 'diversReal', 'diversEstimated', real, estimated);
                  } else {
                    _editBudget(
                        label, 'fournitureReal', 'fournitureEstimated', real, estimated);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _kDark,
                          ),
                        ),
                        Text(
                          '$realStr / $estStr €',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: overBudget ? const Color(0xFFEF4444) : _kDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showAddButton) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (label == "Main d'œuvre") {
                    _showAddMainOeuvreDialog();
                  } else if (label == 'Divers') {
                    _showAddDiversDialog();
                  } else {
                    _showAddFournitureDialog();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add,
                          color: Theme.of(context).colorScheme.surface,
                          size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Ajouter',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _editBudget(String title, String dataKeyReal, String dataKeyEst,
      double currentReal, double currentEst) {
    final realCtrl =
        TextEditingController(text: currentReal.toStringAsFixed(0));
    final estCtrl = TextEditingController(text: currentEst.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Modifier $title',
          style: const TextStyle( fontWeight: FontWeight.bold, color: _kDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: estCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget Estimé (€)',
                labelStyle: TextStyle(),
              ),
              style: const TextStyle(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: realCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Coût Réel (€)',
                labelStyle: TextStyle(),
              ),
              style: const TextStyle(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style:
                    TextStyle( color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final newReal = double.tryParse(realCtrl.text) ?? 0;
              final newEst = double.tryParse(estCtrl.text) ?? 0;
              final chantierId = widget.data['id'] as String?;

              if (chantierId != null) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final updates = <String, dynamic>{};
                  if (dataKeyReal == 'mainOeuvreReal') {
                    updates['main_oeuvre_real'] = newReal;
                    updates['main_oeuvre_estimated'] = newEst;
                  } else if (dataKeyReal == 'diversReal') {
                    updates['divers_real'] = newReal;
                    updates['divers_estimated'] = newEst;
                  } else {
                    updates['fourniture_real'] = newReal;
                    updates['fourniture_estimated'] = newEst;
                  }

                  await _repository.updateBudget(chantierId, updates);
                  await _loadBudget(); // Refresh view
                } catch (e) {
                  debugPrint('Error updating budget: $e');
                  if (mounted) setState(() => _isLoading = false);
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Enregistrer',
                style: TextStyle( color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  void _showAddMainOeuvreDialog() {
    final descCtrl = TextEditingController();
    final hoursCtrl = TextEditingController();
    final rateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Ajouter Main d'œuvre",
          style: TextStyle(fontWeight: FontWeight.bold, color: _kDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (ex: Pose carrelage)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Heures'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Taux horaire (€)'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final desc = descCtrl.text.trim();
              final hours = double.tryParse(hoursCtrl.text) ?? 0;
              final rate = double.tryParse(rateCtrl.text) ?? 0;
              final total = hours * rate;
              final chantierId = widget.data['id'] as String?;

              if (chantierId == null || total <= 0) {
                Navigator.pop(ctx);
                return;
              }

              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                final budget = await _repository.getBudget(chantierId);
                final currentReal = num.tryParse(
                            budget?['main_oeuvre_real']?.toString() ?? '0')
                        ?.toDouble() ??
                    0;
                final currentEst = num.tryParse(
                            budget?['main_oeuvre_estimated']?.toString() ?? '0')
                        ?.toDouble() ??
                    0;

                await _repository.updateBudget(chantierId, {
                  'main_oeuvre_real': currentReal + total,
                  'main_oeuvre_estimated': currentEst + total,
                });
                await _loadBudget();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${desc.isEmpty ? "Main d'œuvre" : desc} ajoutée (+${total.toStringAsFixed(2)} €)'),
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                );
              } catch (e) {
                debugPrint("Error adding main d'œuvre: $e");
                if (!mounted) return;
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Erreur lors de l'ajout"),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Ajouter',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  void _showAddFournitureDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ajouter Fourniture',
          style: TextStyle(fontWeight: FontWeight.bold, color: _kDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la fourniture',
                labelStyle: TextStyle(),
              ),
              style: const TextStyle(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      labelStyle: TextStyle(),
                    ),
                    style: const TextStyle(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire (€)',
                      labelStyle: TextStyle(),
                    ),
                    style: const TextStyle(),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final qty = double.tryParse(qtyCtrl.text) ?? 1;
              final price = double.tryParse(priceCtrl.text) ?? 0;
              final total = qty * price;
              final chantierId = widget.data['id'] as String?;

              if (chantierId != null && name.isNotEmpty && price > 0) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final budget = await _repository.getBudget(chantierId);
                  final currentReal = num.tryParse(
                          budget?['fourniture_real']?.toString() ?? '0')
                      ?.toDouble() ??
                      0;
                  final currentEst = num.tryParse(
                          budget?['fourniture_estimated']?.toString() ?? '0')
                      ?.toDouble() ??
                      0;

                  final updates = <String, dynamic>{
                    'fourniture_real': currentReal + total,
                    'fourniture_estimated': currentEst + total,
                  };

                  await _repository.updateBudget(chantierId, updates);
                  await _loadBudget();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name ajouté (+${total.toStringAsFixed(2)} €)'),
                        backgroundColor: const Color(0xFF22C55E),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error adding fourniture: $e');
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de l\'ajout'),
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Ajouter',
                style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  void _showAddDiversDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    File? pickedFile;
    String? pickedFileName;
    String? attachmentType; // 'photo' | 'document'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Ajouter Divers',
            style: TextStyle(fontWeight: FontWeight.bold, color: _kDark),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (ex: Frais de transport)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Montant (€)'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _attachmentButton(
                      icon: Icons.image_outlined,
                      label: 'Photo',
                      onTap: () async {
                        final picker = ImagePicker();
                        final x = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 80);
                        if (x != null) {
                          setLocal(() {
                            pickedFile = File(x.path);
                            pickedFileName = x.name;
                            attachmentType = 'photo';
                          });
                        }
                      },
                    ),
                    _attachmentButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Caméra',
                      onTap: () async {
                        final picker = ImagePicker();
                        final x = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 80);
                        if (x != null) {
                          setLocal(() {
                            pickedFile = File(x.path);
                            pickedFileName = x.name;
                            attachmentType = 'photo';
                          });
                        }
                      },
                    ),
                    _attachmentButton(
                      icon: Icons.attach_file_outlined,
                      label: 'Document',
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          withData: false,
                        );
                        final path = result?.files.single.path;
                        if (path != null) {
                          setLocal(() {
                            pickedFile = File(path);
                            pickedFileName = result!.files.single.name;
                            attachmentType = 'document';
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (pickedFileName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          attachmentType == 'photo'
                              ? Icons.image
                              : Icons.insert_drive_file,
                          size: 18,
                          color: _kDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pickedFileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: _kDark),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setLocal(() {
                            pickedFile = null;
                            pickedFileName = null;
                            attachmentType = null;
                          }),
                          child: const Icon(Icons.close,
                              size: 16, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                final desc = descCtrl.text.trim();
                final amount = double.tryParse(
                        amountCtrl.text.replaceAll(',', '.')) ??
                    0;
                final chantierId = widget.data['id'] as String?;

                if (chantierId == null || desc.isEmpty || amount <= 0) {
                  Navigator.pop(ctx);
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  String? attachmentUrl;
                  if (pickedFile != null && pickedFileName != null) {
                    attachmentUrl = await _repository.uploadAttachment(
                      chantierId: chantierId,
                      file: pickedFile!,
                      filename: pickedFileName!,
                    );
                  }

                  await _repository.addExpense(
                    chantierId: chantierId,
                    category: 'divers',
                    description: desc,
                    amount: amount,
                    attachmentUrl: attachmentUrl,
                    attachmentType: attachmentType,
                  );

                  final budget = await _repository.getBudget(chantierId);
                  final currentReal = num.tryParse(
                              budget?['divers_real']?.toString() ?? '0')
                          ?.toDouble() ??
                      0;
                  final currentEst = num.tryParse(
                              budget?['divers_estimated']?.toString() ?? '0')
                          ?.toDouble() ??
                      0;

                  await _repository.updateBudget(chantierId, {
                    'divers_real': currentReal + amount,
                    'divers_estimated': currentEst + amount,
                  });
                  await _loadBudget();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '$desc ajouté (+${amount.toStringAsFixed(2)} €)'),
                      backgroundColor: const Color(0xFF22C55E),
                    ),
                  );
                } catch (e) {
                  debugPrint('Error adding divers: $e');
                  if (!mounted) return;
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('Ajouter',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.surface)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _kDark, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    // e.g. 2400 → "2 400"
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );
  }
}
