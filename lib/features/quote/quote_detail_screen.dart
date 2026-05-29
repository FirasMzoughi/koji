import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:koji/features/quote/repository/quote_repository.dart';
import 'package:koji/features/quote/providers/quote_task_provider.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';
import 'package:intl/intl.dart';

// ─── Data model for one editable line ─────────────────────────────────────────
class _DevisLine {
  String taskId;
  String label;
  String code;
  String famille;
  String unite;

  double qty;          // editable
  double tempsHU;      // editable – temps h/u
  double tauxHoraire;  // from profile
  double conditionCoeff;

  double fournituresUnitPrice; // editable – fournitures €/u

  // Forfait (flat price) — when enabled the line is billed at a single fixed
  // price and the qty/temps/fournitures breakdown is ignored.
  bool forfaitEnabled;
  double forfaitPrice;

  // derived
  double get moUnitPrice   => tempsHU * tauxHoraire * conditionCoeff;
  // A forfait line carries its whole price in MO so it flows into the totals;
  // fournitures are folded into the flat price, so they're zero here.
  double get totalMO       => forfaitEnabled ? forfaitPrice : moUnitPrice * qty;
  double get totalFournitures => forfaitEnabled ? 0.0 : fournituresUnitPrice * qty;
  double get totalLigne    => totalMO + totalFournitures;

  _DevisLine({
    required this.taskId,
    required this.label,
    this.code = '',
    this.famille = '',
    this.unite = 'u',
    this.qty = 1.0,
    this.tempsHU = 0.0,
    this.tauxHoraire = 0.0,
    this.conditionCoeff = 1.0,
    this.fournituresUnitPrice = 0.0,
    this.forfaitEnabled = false,
    this.forfaitPrice = 0.0,
  });
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class QuoteDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const QuoteDetailScreen({super.key, required this.data});

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  bool _isSaving = false;
  bool _isLoadingDetails = false;

  // Header
  String _companyName    = 'Koji';
  String _companyAddress = '8 Av. des artisans, Paris';
  String _companyPhone   = '01 42 55 000 77';
  String _companyEmail   = 'Contact@Koji.fr';
  String _clientName     = 'Client';
  String _clientAddress  = '';
  String _clientEmail    = '';
  String _quoteNumber    = '';
  String _quoteDate      = '';
  String _quoteValidity  = '30 Jours';
  String _siteAddress    = '';
  String? _logoPath;
  double _hourlyRate     = 0.0;

  // Legal identification (shown in the devis footer / pied de page)
  String _companySiret   = '';
  String _companyRcs     = '';
  String _companyTva     = '';
  String _companyLegalForm = '';

  // Mandatory work info (lieu = siteAddress; dates editable here)
  String _travauxStart   = ''; // date de début des travaux
  String _travauxDuration = ''; // durée des travaux
  final _startCtrl    = TextEditingController();
  final _durationCtrl = TextEditingController();

  @override
  void dispose() {
    _startCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  // KOJI devis lines grouped by room
  // Map<roomId, List<_DevisLine>>
  final Map<String, List<_DevisLine>> _linesByRoom = {};
  final List<String> _roomOrder = [];

  @override
  void initState() {
    super.initState();
    _quoteNumber = 'D-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _quoteDate   = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Two ways the recap can be opened with an `id`:
    //   1. Direct deep-link from the quotes list (no fresh tasks map) — must
    //      load room/task rows from the database.
    //   2. Re-entry via the edit-flow seeded from a saved quote — `tasks` is
    //      already populated with the user's edits, and pulling from the DB
    //      again would clobber those edits.
    final tasksMap = widget.data['tasks'];
    final hasFreshTasks = tasksMap is Map && tasksMap.isNotEmpty;
    if (widget.data.containsKey('id') && !hasFreshTasks) {
      _loadExistingQuote();
    } else {
      _initFromProvider();
      // Reuse the number when editing an existing quote; otherwise assign a
      // fresh sequential DEVIS-YYYY-NNNN number from the backend.
      final existingNumber = widget.data['quoteNumber'] as String?;
      if (existingNumber != null && existingNumber.isNotEmpty) {
        _quoteNumber = existingNumber;
      } else {
        _assignAutoNumber();
      }
    }
    _fetchBusinessInfo();
  }

  Future<void> _assignAutoNumber() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    try {
      final number =
          await ref.read(quoteRepositoryProvider).generateNextQuoteNumber(user.id);
      if (mounted) setState(() => _quoteNumber = number);
    } catch (_) {/* keep the timestamp fallback already set */}
  }

  // ── Initialize from new quote flow ──────────────────────────────────────────
  void _initFromProvider() {
    final tasks = widget.data['tasks'] as Map<String, dynamic>?;
    if (tasks == null) return;

    final client = widget.data['client'] as Map<String, dynamic>?;
    if (client != null) {
      _clientName    = client['name']    ?? _clientName;
      _clientAddress = client['address'] ?? _clientAddress;
      _clientEmail   = client['email']   ?? _clientEmail;
    }
    _siteAddress = widget.data['siteAddress'] ?? '';

    tasks.forEach((roomId, roomTasksRaw) {
      if (roomTasksRaw is! Map) return;
      final roomTasks = roomTasksRaw as Map<String, dynamic>;
      final lines = <_DevisLine>[];

      roomTasks.forEach((_, taskDataRaw) {
        if (taskDataRaw is! Map) return;
        final td = taskDataRaw as Map<String, dynamic>;

        // Compute fournitures unit price from selectedFournitures
        double fournituresTotalCost = 0.0;
        final sf = td['selectedFournitures'];
        if (sf is Map) {
          sf.forEach((_, pd) {
            if (pd is Map) {
              final pqty     = (pd['quantity']  as num?)?.toDouble() ?? 1.0;
              final pPrice   = (pd['unitPrice'] as num?)?.toDouble() ?? 0.0;
              fournituresTotalCost += pqty * pPrice;
            }
          });
        }
        final qty = (td['quantity'] as num?)?.toDouble() ?? 1.0;

        final forfaitEnabled = td['forfaitEnabled'] == true;
        final forfaitPrice = (td['forfaitPrice'] as num?)?.toDouble() ?? 0.0;

        lines.add(_DevisLine(
          taskId:              td['taskId']?.toString() ?? '',
          label:               td['label']?.toString()  ?? '',
          code:                td['code']?.toString()   ?? '',
          famille:             td['famille']?.toString() ?? '',
          unite:               td['unite']?.toString()  ?? 'u',
          qty:                 qty,
          tempsHU:             (td['hours']         as num?)?.toDouble() ?? 0.0,
          tauxHoraire:         (td['tauxHoraire']   as num?)?.toDouble() ?? _hourlyRate,
          conditionCoeff:      (td['conditionCoeff'] as num?)?.toDouble() ?? 1.0,
          fournituresUnitPrice: qty > 0 ? fournituresTotalCost / qty : fournituresTotalCost,
          forfaitEnabled:      forfaitEnabled,
          forfaitPrice:        forfaitPrice,
        ));
      });

      if (lines.isNotEmpty) {
        _linesByRoom[roomId] = lines;
        _roomOrder.add(roomId);
      }
    });
  }

  // ── Load existing saved quote ────────────────────────────────────────────────
  void _loadExistingQuote() {
    final d = widget.data;
    _quoteNumber  = d['quoteNumber'] ?? _quoteNumber;
    _quoteDate    = d['date']        ?? _quoteDate;
    _quoteValidity = d['validity']   ?? _quoteValidity;

    Map<String, dynamic> safe(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return {};
    }

    final client  = safe(d['client']);
    _clientName   = client['name']    ?? '';
    _clientAddress = client['address'] ?? '';
    _clientEmail  = client['email']   ?? '';

    final company   = safe(d['company']);
    _companyName    = company['name']    ?? _companyName;
    _companyAddress = company['address'] ?? _companyAddress;
    _companyPhone   = company['phone']   ?? _companyPhone;
    _companyEmail   = company['email']   ?? _companyEmail;
    _companySiret    = company['siret']  ?? _companySiret;
    _companyRcs      = company['rcs']    ?? _companyRcs;
    _companyTva      = company['tva']    ?? _companyTva;
    _companyLegalForm = company['formeJuridique'] ?? _companyLegalForm;
    _siteAddress    = d['siteAddress']   ?? '';
    _travauxStart    = d['travauxStart']    ?? '';
    _travauxDuration = d['travauxDuration'] ?? '';
    _startCtrl.text    = _travauxStart;
    _durationCtrl.text = _travauxDuration;

    setState(() => _isLoadingDetails = true);
    _fetchDetails(d['id'] as String);
  }

  Future<void> _fetchDetails(String quoteId) async {
    try {
      final repo = ref.read(quoteTaskRepositoryProvider);
      final roomsData = await repo.getQuoteRooms(quoteId);

      for (final r in roomsData) {
        final roomId = r['name'] as String;
        _roomOrder.add(roomId);
        _linesByRoom[roomId] = [];

        final tasksData = await repo.getQuoteTasks(r['id'] as String);
        for (final t in tasksData) {
          // The `inputs` JSON keeps the editable fields the user originally
          // entered (qty, tempsHU, tauxHoraire, code, famille, unite). Without
          // it the recap would silently reset every line to qty:1, hiding the
          // user's edits and making "Mettre à jour" look like a no-op.
          final inputs = (t['inputs'] is Map)
              ? Map<String, dynamic>.from(t['inputs'] as Map)
              : <String, dynamic>{};

          final qty = (inputs['quantity'] as num?)?.toDouble() ?? 1.0;
          final moUnit = (t['unit_price_ht'] as num?)?.toDouble() ?? 0.0;
          final fournUnit = (t['total_price_ht'] as num?)?.toDouble() ?? 0.0;
          final tauxHoraire = (inputs['tauxHoraire'] as num?)?.toDouble()
              ?? (_hourlyRate > 0 ? _hourlyRate : 0.0);
          final forfaitEnabled = inputs['forfaitEnabled'] == true;
          // On a forfait line the flat price was saved into unit_price_ht (moUnit).
          final forfaitPrice = (inputs['forfaitPrice'] as num?)?.toDouble()
              ?? (forfaitEnabled ? moUnit : 0.0);

          double tempsHU = (inputs['tempsHU'] as num?)?.toDouble() ?? 0.0;
          if (!forfaitEnabled && tempsHU == 0 && tauxHoraire > 0) {
            tempsHU = moUnit / tauxHoraire;
          }

          _linesByRoom[roomId]!.add(_DevisLine(
            taskId:  t['task_id']?.toString() ?? '',
            label:   t['label']?.toString()   ?? '',
            code:    inputs['code']?.toString()    ?? '',
            famille: inputs['famille']?.toString() ?? '',
            unite:   inputs['unite']?.toString()   ?? 'u',
            qty:     qty,
            tempsHU: tempsHU,
            tauxHoraire: tauxHoraire,
            fournituresUnitPrice: forfaitEnabled ? 0.0 : fournUnit,
            forfaitEnabled: forfaitEnabled,
            forfaitPrice: forfaitPrice,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading quote: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _fetchBusinessInfo() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    final userData = await ref.read(userRepositoryProvider).getUser(user.id);
    if (userData == null || !mounted) return;

    final logoUrl = userData['logo_url'] as String?;
    final biz     = userData['business_info'] as Map<String, dynamic>?;

    setState(() {
      _logoPath = logoUrl;
      if (biz != null) {
        _companyName    = biz['raisonSociale'] ?? _companyName;
        _companyAddress = biz['address']       ?? _companyAddress;
        _companyPhone   = biz['phone']         ?? _companyPhone;
        _companyEmail   = biz['emailPro']      ?? _companyEmail;
        _companySiret    = biz['siret']         ?? _companySiret;
        _companyRcs      = biz['rcs']           ?? _companyRcs;
        _companyTva      = biz['tva']           ?? _companyTva;
        _companyLegalForm = biz['formeJuridique'] ?? _companyLegalForm;
        final daily  = (biz['dailyRate']   as num?)?.toDouble() ?? 0.0;
        final hpd    = (biz['hoursPerDay'] as num?)?.toDouble() ?? 8.0;
        if (daily > 0 && hpd > 0) {
          _hourlyRate = daily / hpd;
          // Backfill tauxHoraire on lines that still have 0
          for (final lines in _linesByRoom.values) {
            for (final l in lines) {
              if (l.tauxHoraire == 0) l.tauxHoraire = _hourlyRate;
            }
          }
        }
      }
    });
  }

  // ── Totals ───────────────────────────────────────────────────────────────────
  double get _grandTotalMO => _linesByRoom.values
      .expand((l) => l)
      .fold(0.0, (s, l) => s + l.totalMO);

  double get _grandTotalFournitures => _linesByRoom.values
      .expand((l) => l)
      .fold(0.0, (s, l) => s + l.totalFournitures);

  double get _grandTotalHT  => _grandTotalMO + _grandTotalFournitures;
  double get _tva20         => _grandTotalHT * 0.20;
  double get _grandTotalTTC => _grandTotalHT + _tva20;

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _generateQuote() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final user = ref.read(authProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')));
      setState(() => _isSaving = false);
      return;
    }

    // Convert lines back to ExpenseItem format for saving
    final expensesMap = <String, List<Map<String, dynamic>>>{};
    // tasksMap.<room>.<taskId>.inputs is what the repo persists into
    // quote_tasks.inputs — the recap reads it back on next open, so the
    // editable fields must round-trip through here or "Mettre à jour" loses them.
    final tasksMap = <String, Map<String, Map<String, dynamic>>>{};

    // When the user came in via the full edit-flow (room→tasks→recap),
    // the provider holds the rich per-task state (selectedFournitures,
    // selectedProducts, note, photoPaths) that the recap's _DevisLine
    // doesn't track. Merge it back so update doesn't drop fournitures.
    final providerTasks = ref.read(quoteCreationProvider).roomTasks;
    _linesByRoom.forEach((roomId, lines) {
      expensesMap[roomId] = lines.map((l) => {
        'id':           l.taskId,
        'title':        l.label,
        // Forfait: the whole flat price rides in laborCost at qty 1, with no
        // fournitures — matches how room_task_screen emits a forfait line.
        'laborCost':    l.forfaitEnabled ? l.forfaitPrice : l.moUnitPrice,
        'materialCost': l.forfaitEnabled ? 0.0 : l.fournituresUnitPrice,
        'quantity':     l.forfaitEnabled ? 1.0 : l.qty,
        'unite':        l.unite,
        'code':         l.code,
        'famille':      l.famille,
        'tempsHU':      l.forfaitEnabled ? 0.0 : l.tempsHU,
        'tauxHoraire':  l.forfaitEnabled ? 0.0 : l.tauxHoraire,
      }).toList();
      final perRoomProvider = (providerTasks[roomId] is Map)
          ? Map<String, dynamic>.from(providerTasks[roomId] as Map)
          : <String, dynamic>{};

      tasksMap[roomId] = {
        for (final l in lines)
          l.taskId: () {
            final prior = (perRoomProvider[l.taskId] is Map)
                ? Map<String, dynamic>.from(perRoomProvider[l.taskId] as Map)
                : <String, dynamic>{};
            final priorInputs = (prior['inputs'] is Map)
                ? Map<String, dynamic>.from(prior['inputs'] as Map)
                : <String, dynamic>{};
            // Recap-level edits win; preserve everything else from the
            // earlier edit-flow state so fournitures/products/notes survive.
            return <String, dynamic>{
              ...prior,
              'taskId': l.taskId,
              'label': l.label,
              'inputs': {
                ...priorInputs,
                'quantity': l.qty,
                'tempsHU': l.tempsHU,
                'tauxHoraire': l.tauxHoraire,
                'unite': l.unite,
                'code': l.code,
                'famille': l.famille,
                'forfaitEnabled': l.forfaitEnabled,
                'forfaitPrice': l.forfaitPrice,
              },
              'hours': l.tempsHU,
              'quantity': l.qty,
              'tauxHoraire': l.tauxHoraire,
              'unite': l.unite,
              'code': l.code,
              'famille': l.famille,
              'forfaitEnabled': l.forfaitEnabled,
              'forfaitPrice': l.forfaitPrice,
            };
          }(),
      };
    });

    // The chantier this devis belongs to. When the flow started from a chantier
    // (chantier_devis_screen → _createDevis → setChantierId), the id lives in the
    // creation provider. Editing an existing devis carries it in widget.data.
    // Without this, saveQuote auto-creates an *orphan* chantier and the devis
    // tasks never surface under the real chantier (planner/dashboard show none).
    final effectiveChantierId = (widget.data['chantier_id'] as String?) ??
        ref.read(quoteCreationProvider).chantierId;

    final quoteData = {
      'quoteNumber': _quoteNumber,
      'createdAt':   DateTime.now().toIso8601String(),
      'validity':    _quoteValidity,
      'date':        _quoteDate,
      'client':   {'name': _clientName, 'address': _clientAddress, 'email': _clientEmail},
      'company':  {
        'name': _companyName,
        'address': _companyAddress,
        'phone': _companyPhone,
        'email': _companyEmail,
        'siret': _companySiret,
        'rcs': _companyRcs,
        'tva': _companyTva,
        'formeJuridique': _companyLegalForm,
        // Public logo URL so the client signature website can show the
        // entreprise's real logo instead of the default Koji mark.
        'logo': _logoPath,
      },
      'siteAddress': _siteAddress,
      'travauxStart': _startCtrl.text.trim(),
      'travauxDuration': _durationCtrl.text.trim(),
      'expenses':    expensesMap,
      'tasks':       tasksMap,
      'totals': {
        'moHT':           _grandTotalMO,
        'fournituresHT':  _grandTotalFournitures,
        'ht':             _grandTotalHT,
        'tva':            _tva20,
        'ttc':            _grandTotalTTC,
      },
      if (effectiveChantierId != null) 'chantier_id': effectiveChantierId,
    };

    try {
      final existingId = widget.data['id'] as String?;
      final quoteId = await ref
          .read(quoteRepositoryProvider)
          .saveQuote(user.id, quoteData, quoteId: existingId);

      if (mounted) {
        // Clear editing state so the next "new devis" starts clean.
        ref.read(quoteCreationProvider.notifier).reset();
        if (existingId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Devis mis à jour'),
              backgroundColor: Color(0xFF15803D),
            ),
          );
        }
        // Both create and update land on the success screen so the user can
        // view / share the regenerated PDF and the Fournitures PDF.
        context.go('/quote/success', extra: {
          'quoteId':   quoteId,
          'quoteData': {...quoteData, 'id': quoteId},
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Récapitulatif de votre devis',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        actions: [
          // Discussion with the client — only meaningful once the devis exists
          // (has an id), since messages are keyed by quote id.
          if ((widget.data['id'] as String?)?.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.forum_outlined,
                    color: Color(0xFF0F172A), size: 20),
                tooltip: 'Discussion',
                onPressed: () => context.push('/quote/messages', extra: {
                  'quoteId': widget.data['id'],
                  'clientName': _clientName,
                }),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Info banner ───────────────────────────────────────
                  _buildInfoBanner(),
                  const SizedBox(height: 20),

                  // ── Header card ───────────────────────────────────────
                  _buildHeaderCard(),
                  const SizedBox(height: 16),

                  // ── Travaux (mandatory legal info) ────────────────────
                  _buildTravauxCard(),
                  const SizedBox(height: 24),

                  // ── KOJI devis table ──────────────────────────────────
                  if (_linesByRoom.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Aucune tâche ajoutée.',
                            style: TextStyle(color: Color(0xFF9CA3AF))),
                      ),
                    )
                  else
                    ..._roomOrder.where((r) => _linesByRoom.containsKey(r)).map(
                      (roomId) => _buildRoomSection(roomId),
                    ),

                  const SizedBox(height: 24),

                  // ── Grand totals ──────────────────────────────────────
                  _buildTotalsCard(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Info banner ───────────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Les champs Qté, Temps h/u et Fournitures €/u sont modifiables. Les totaux se recalculent en temps réel.',
              style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
            ),
          ),
          if (_hourlyRate > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_hourlyRate.toStringAsFixed(2)} €/h',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Header card ───────────────────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _logoPath != null ? Colors.white : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  image: _logoPath != null
                      ? DecorationImage(image: NetworkImage(_logoPath!), fit: BoxFit.cover)
                      : null,
                ),
                child: _logoPath == null
                    ? Icon(
                        Icons.business,
                        color: Theme.of(context).colorScheme.surface,
                        size: 22,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_companyName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(_companyAddress, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    Text(_companyPhone,   style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              // Quote number box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5D8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('DEVIS N°', style: TextStyle(fontSize: 8, color: Color(0xFFA18B73))),
                    Text(_quoteNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CLIENT',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFA18B73))),
                  const SizedBox(height: 4),
                  Text(_clientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                  if (_clientAddress.isNotEmpty)
                    Text(_clientAddress, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('DATE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFA18B73))),
                  Text(_quoteDate,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  const Text('VALIDITÉ',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFA18B73))),
                  Text(_quoteValidity,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                ],
              ),
            ],
          ),
          if (_siteAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3E5D8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFA18B73)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_siteAddress,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Travaux card: lieu (read-only) + dates (editable, mandatory mentions) ─────
  Widget _buildTravauxCard() {
    final lieu = _siteAddress.isNotEmpty ? _siteAddress : _clientAddress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRAVAUX',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFA18B73))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lieu.isNotEmpty ? 'Lieu d\'exécution : $lieu' : 'Lieu d\'exécution : —',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startCtrl,
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Date de début',
                    hintText: 'jj/mm/aaaa',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _durationCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Durée des travaux',
                    hintText: 'ex : 3 semaines',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Room section ──────────────────────────────────────────────────────────────
  Widget _buildRoomSection(String roomId) {
    final lines = _linesByRoom[roomId] ?? [];
    final roomTotal  = lines.fold(0.0, (s, l) => s + l.totalLigne);

    // Group lines by famille
    final byFamille = <String, List<_DevisLine>>{};
    for (final l in lines) {
      final fam = l.famille.isEmpty ? 'Général' : l.famille;
      byFamille.putIfAbsent(fam, () => []).add(l);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  _getRoomLabel(roomId),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${roomTotal.toStringAsFixed(2)} €',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEAD8B1)),
                ),
              ],
            ),
          ),

          // Lines by famille
          ...byFamille.entries.map((entry) {
            final famColor = _familleColor(entry.key);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOT label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: famColor.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      Container(width: 3, height: 14, color: famColor,
                          margin: const EdgeInsets.only(right: 8)),
                      Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: famColor, letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ...entry.value.asMap().entries.map((e) {
                  final lineIndex = lines.indexOf(e.value);
                  return _buildLineCard(roomId, lineIndex, e.value, famColor);
                }),
              ],
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Task line card (mobile-friendly) ─────────────────────────────────────────
  Widget _buildLineCard(String roomId, int lineIndex, _DevisLine line, Color famColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                if (line.code.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: famColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(line.code,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: famColor)),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    line.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${line.totalLigne.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // ── Editable inputs row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: line.forfaitEnabled
                // Forfait line: one flat-price field, no qty/temps breakdown.
                ? Row(
                    children: [
                      _inputField(
                        label: 'Forfait (HT)',
                        sublabel: '€',
                        value: line.forfaitPrice,
                        onChanged: (v) => setState(() =>
                            _linesByRoom[roomId]![lineIndex].forfaitPrice = v),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Qté
                      _inputField(
                        label: 'Qté',
                        sublabel: line.unite,
                        value: line.qty,
                        onChanged: (v) => setState(() => _linesByRoom[roomId]![lineIndex].qty = v),
                      ),
                      const SizedBox(width: 8),
                      // Temps h/u
                      _inputField(
                        label: 'Temps h/${line.unite}',
                        sublabel: 'h',
                        value: line.tempsHU,
                        onChanged: (v) => setState(() => _linesByRoom[roomId]![lineIndex].tempsHU = v),
                      ),
                      // Fournitures are managed in the dedicated fournitures list, so
                      // the Fnt input is hidden here. The amount still counts toward
                      // the line Total and grand total (see the read-only breakdown).
                    ],
                  ),
          ),

          // ── Computed results row ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _resultChip('Total', '${line.totalLigne.toStringAsFixed(2)}€', const Color(0xFF0F172A), bold: true),
                  ],
                ),
                const SizedBox(height: 6),
                _buildLineBreakdown(line),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Line breakdown: shows HOW the total is computed ──────────────────────────
  // Labor part:  Qté × Temps × tarif effectif (taux × coefficient) = MO
  // Fournitures: shown only when there is a material cost on the line.
  Widget _buildLineBreakdown(_DevisLine line) {
    final effectiveRate = line.tauxHoraire * line.conditionCoeff;

    String fmt(double v) {
      final s = v.toStringAsFixed(2);
      return s.replaceAll('.', ',');
    }

    final parts = <String>[];
    if (line.forfaitEnabled) {
      // Flat-price line: no MO/fournitures math, just the forfait amount.
      parts.add('Forfait : ${fmt(line.forfaitPrice)} €');
    } else {
      if (line.tempsHU > 0 && effectiveRate > 0) {
        parts.add(
          'MO : ${fmt(line.qty)} × ${fmt(line.tempsHU)} h × ${fmt(effectiveRate)} € = ${fmt(line.totalMO)} €',
        );
      }
      if (line.totalFournitures > 0) {
        parts.add(
          'Fnt : ${fmt(line.qty)} × ${fmt(line.fournituresUnitPrice)} € = ${fmt(line.totalFournitures)} €',
        );
      }
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts
          .map((p) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── Small labeled input ───────────────────────────────────────────────────────
  Widget _inputField({
    required String label,
    required String sublabel,
    required double value,
    required void Function(double) onChanged,
  }) {
    final display = value > 0 ? value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '') : '';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController.fromValue(
                      TextEditingValue(
                        text: display,
                        selection: TextSelection.collapsed(offset: display.length),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    ),
                    onChanged: (v) => onChanged(double.tryParse(v) ?? 0.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(sublabel,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Read-only result chip ─────────────────────────────────────────────────────
  Widget _resultChip(String label, String value, Color color, {bool bold = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  // ── Totals card ───────────────────────────────────────────────────────────────
  Widget _buildTotalsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 1,
            color: const Color(0xFF0F172A),
          ),
          _totalRow('TOTAL DEVIS HT', _grandTotalHT, const Color(0xFF0F172A), bold: true, bigger: true),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _totalRow('TVA 20%', _tva20, const Color(0xFF6B7280)),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL TTC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.surface,
                    )),
                Text(
                  '${_grandTotalTTC.toStringAsFixed(2)} €',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFFEAD8B1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value, Color color, {bool bold = false, bool bigger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bigger ? 14 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: color)),
          Text(
            '${value.toStringAsFixed(2)} €',
            style: TextStyle(
                fontSize: bigger ? 16 : 13,
                fontWeight: FontWeight.bold,
                color: color),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _generateQuote,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.surface,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.data.containsKey('id') ? 'Mettre à jour' : 'Générer le Devis',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  String _getRoomLabel(String id) {
    switch (id) {
      case 'salon':       return 'Salon';
      case 'cuisine':     return 'Cuisine';
      case 'chambre':     return 'Chambre';
      case 'salle_de_bain': return 'Salle de bain';
      case 'bureau':      return 'Bureau';
      case 'exterieur':   return 'Extérieur';
      default:
        if (id.isEmpty) return 'Pièce';
        return id[0].toUpperCase() + id.substring(1);
    }
  }

  Color _familleColor(String famille) {
    switch (famille.toLowerCase()) {
      case 'carrelage':   return const Color(0xFFB45309);
      case 'peinture':    return const Color(0xFF7C3AED);
      case 'plomberie':   return const Color(0xFF0369A1);
      case 'electricité':
      case 'electricite': return const Color(0xFFD97706);
      case 'menuiserie':  return const Color(0xFF166534);
      case 'démolition':
      case 'demolition':  return const Color(0xFFB91C1C);
      default:            return const Color(0xFF475569);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
