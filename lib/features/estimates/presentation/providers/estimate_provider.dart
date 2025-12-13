import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/estimates/data/models/estimate_model.dart';
import 'package:uuid/uuid.dart';

// 1. Manages the list of all estimates (Dashboard state)
final estimateProvider = StateNotifierProvider<EstimateListNotifier, List<Estimate>>((ref) {
  return EstimateListNotifier();
});

class EstimateListNotifier extends StateNotifier<List<Estimate>> {
  EstimateListNotifier() : super([]) {
    _generateMockData();
  }
  
  // Stats Getters
  int get pendingEstimatesCount => state.where((e) => e.status == 'En cours').length;
  double get totalRevenue => state.where((e) => e.status == 'Validé').fold(0.0, (sum, e) => sum + e.totalCost);

  void _generateMockData() {
    state = [
      Estimate(
        clientId: '1',
        client: ClientInfo(name: 'Jean Dupont', address: '12 Rue de la Paix', phone: '0612345678'),
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Validé',
        description: 'Peinture salon complet',
        surfaceArea: 30,
        pricePerSqMeter: 25,
        supplies: [
          SupplyItem(name: 'Peinture Blanche 10L', price: 45, quantity: 2),
        ],
      ),
      Estimate(
        clientId: '2',
        client: ClientInfo(name: 'Sophie Martin', address: '5 Avenue Foch', phone: '0789123456'),
        date: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'En cours',
        description: 'Rénovation chambre enfant',
        surfaceArea: 15,
        pricePerSqMeter: 28,
        supplies: [
          SupplyItem(name: 'Papier peint', price: 15, quantity: 4),
          SupplyItem(name: 'Colle', price: 8, quantity: 1),
        ],
      ),
    ];
  }

  void addEstimate(Estimate estimate) {
    state = [estimate, ...state];
  }
}

// 2. Manages the "Draft" estimate being created (Wizard state)
final draftEstimateProvider = StateNotifierProvider<DraftEstimateNotifier, DraftEstimateState>((ref) {
  return DraftEstimateNotifier(ref);
});

class DraftEstimateState {
  final ClientInfo? client;
  final String description;
  final double surface;
  final double pricePerSqMeter;
  final List<SupplyItem> supplies;

  DraftEstimateState({
    this.client,
    this.description = '',
    this.surface = 0,
    this.pricePerSqMeter = 0,
    this.supplies = const [],
  });

  double get laborCost => surface * pricePerSqMeter;
  double get suppliesCost => supplies.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalCost => laborCost + suppliesCost;

  DraftEstimateState copyWith({
    ClientInfo? client,
    String? description,
    double? surface,
    double? pricePerSqMeter,
    List<SupplyItem>? supplies,
  }) {
    return DraftEstimateState(
      client: client ?? this.client,
      description: description ?? this.description,
      surface: surface ?? this.surface,
      pricePerSqMeter: pricePerSqMeter ?? this.pricePerSqMeter,
      supplies: supplies ?? this.supplies,
    );
  }
}

class DraftEstimateNotifier extends StateNotifier<DraftEstimateState> {
  final Ref ref;

  DraftEstimateNotifier(this.ref) : super(DraftEstimateState());

  void startNew() {
    state = DraftEstimateState();
  }

  void updateClient(String name, String address, String phone) {
    state = state.copyWith(client: ClientInfo(name: name, address: address, phone: phone));
  }

  void updateJobDetails(String description) {
    state = state.copyWith(description: description);
  }

  void updateLabor(double surface, double price) {
    state = state.copyWith(surface: surface, pricePerSqMeter: price);
  }

  void addSupply(String name, double price, int quantity) {
    final newItem = SupplyItem(name: name, price: price, quantity: quantity);
    state = state.copyWith(supplies: [...state.supplies, newItem]);
  }

  void removeSupply(String id) {
    final updatedSupplies = state.supplies.where((item) => item.id != id).toList();
    state = state.copyWith(supplies: updatedSupplies);
  }
  
  void finalizeAndSave() {
    if (state.client != null) {
      final newEstimate = Estimate(
        clientId: const Uuid().v4(),
        client: state.client!,
        date: DateTime.now(),
        status: 'En cours', // Default status
        description: state.description,
        surfaceArea: state.surface,
        pricePerSqMeter: state.pricePerSqMeter,
        supplies: List.from(state.supplies),
      );
      
      // Save using main provider
      ref.read(estimateProvider.notifier).addEstimate(newEstimate);
    }
  }
}
