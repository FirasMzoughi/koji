import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/models/estimate_model.dart';

final estimateProvider = ChangeNotifierProvider<EstimateProvider>((ref) {
  return EstimateProvider();
});

class EstimateProvider with ChangeNotifier {
  List<Estimate> _estimates = [];
  
  List<Estimate> get estimates => _estimates;
  
  // Stats
  int get pendingEstimatesCount => _estimates.where((e) => e.status == 'En cours').length;
  double get totalRevenue => _estimates.where((e) => e.status == 'Validé').fold(0.0, (sum, e) => sum + e.totalCost);

  EstimateProvider() {
    _generateMockData();
  }

  void _generateMockData() {
    _estimates = [
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
    notifyListeners();
  }

  void addEstimate(Estimate estimate) {
    _estimates.insert(0, estimate); // Add to top
    notifyListeners();
  }

  // Current Estimate Creation State (Wizard)
  ClientInfo? _tempClient;
  String _tempDescription = '';
  double _tempSurface = 0;
  double _tempPricePerSqMeter = 0;
  List<SupplyItem> _tempSupplies = [];

  // Getters for wizard
  ClientInfo? get tempClient => _tempClient;
  String get tempDescription => _tempDescription;
  double get tempSurface => _tempSurface;
  double get tempPricePerSqMeter => _tempPricePerSqMeter;
  List<SupplyItem> get tempSupplies => _tempSupplies;
  
  double get tempLaborCost => _tempSurface * _tempPricePerSqMeter;
  double get tempSuppliesCost => _tempSupplies.fold(0, (sum, item) => sum + item.totalPrice);
  double get tempTotalCost => tempLaborCost + tempSuppliesCost;

  void startNewEstimate() {
    _tempClient = null;
    _tempDescription = '';
    _tempSurface = 0;
    _tempPricePerSqMeter = 0;
    _tempSupplies = [];
    notifyListeners();
  }

  void updateClientInfo(String name, String address, String phone) {
    _tempClient = ClientInfo(name: name, address: address, phone: phone);
    notifyListeners();
  }

  void updateJobDetails(String description) {
    _tempDescription = description;
    notifyListeners();
  }

  void updateLabor(double surface, double price) {
    _tempSurface = surface;
    _tempPricePerSqMeter = price;
    notifyListeners();
  }

  void addSupply(String name, double price, int quantity) {
    _tempSupplies.add(SupplyItem(name: name, price: price, quantity: quantity));
    notifyListeners();
  }
  
  void removeSupply(String id) {
    _tempSupplies.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void finalizeEstimate() {
    if (_tempClient != null) {
      final newEstimate = Estimate(
        clientId: 'temp_id', // In a real app, generated or linked
        client: _tempClient!,
        date: DateTime.now(),
        status: 'En cours',
        description: _tempDescription,
        surfaceArea: _tempSurface,
        pricePerSqMeter: _tempPricePerSqMeter,
        supplies: List.from(_tempSupplies),
      );
      addEstimate(newEstimate);
    }
  }
}
