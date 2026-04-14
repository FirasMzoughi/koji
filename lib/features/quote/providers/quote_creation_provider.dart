import 'package:koji/features/pricing/models/pricing_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Strongly-typed client information for the quote creation flow.
/// Replaces the previous Map<String, dynamic> clientInfo.
class ClientInfo {
  final String name;
  final String email;
  final String phone;
  final String address;

  const ClientInfo({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
  });

  /// Build from a legacy Map for backwards-compatibility.
  factory ClientInfo.fromMap(Map<String, dynamic> map) {
    return ClientInfo(
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
      };

  bool get isEmpty =>
      name.isEmpty && email.isEmpty && phone.isEmpty && address.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class QuoteCreationState {
  final ClientInfo clientInfo;
  final List<String> visualEvidenceImages;
  final List<String> selectedRoomIds;
  final Map<String, dynamic> roomEstimations; // Map<roomId, List<ExpenseItem>>
  final Map<String, dynamic> roomTasks;
  final String? userProfession;
  final Map<String, RealityFactors> roomContexts;
  final String? chantierId;

  QuoteCreationState({
    ClientInfo? clientInfo,
    this.visualEvidenceImages = const [],
    this.selectedRoomIds = const [],
    this.roomEstimations = const {},
    this.roomTasks = const {},
    this.userProfession,
    this.roomContexts = const {},
    this.chantierId,
  }) : clientInfo = clientInfo ?? const ClientInfo();

  QuoteCreationState copyWith({
    ClientInfo? clientInfo,
    List<String>? visualEvidenceImages,
    List<String>? selectedRoomIds,
    Map<String, dynamic>? roomEstimations,
    Map<String, dynamic>? roomTasks,
    String? userProfession,
    Map<String, RealityFactors>? roomContexts,
    String? chantierId,
  }) {
    return QuoteCreationState(
      clientInfo: clientInfo ?? this.clientInfo,
      visualEvidenceImages: visualEvidenceImages ?? this.visualEvidenceImages,
      selectedRoomIds: selectedRoomIds ?? this.selectedRoomIds,
      roomEstimations: roomEstimations ?? this.roomEstimations,
      roomTasks: roomTasks ?? this.roomTasks,
      userProfession: userProfession ?? this.userProfession,
      roomContexts: roomContexts ?? this.roomContexts,
      chantierId: chantierId ?? this.chantierId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'client': clientInfo.toMap(),
      'images': visualEvidenceImages,
      'roomIds': selectedRoomIds,
      'expenses': roomEstimations,
      'tasks': roomTasks,
      'profession': userProfession,
      if (chantierId != null) 'chantier_id': chantierId,
    };
  }
}

class QuoteCreationNotifier extends StateNotifier<QuoteCreationState> {
  QuoteCreationNotifier() : super(QuoteCreationState());

  void updateClientInfo(ClientInfo info) {
    state = state.copyWith(clientInfo: info);
  }

  void addVisualEvidence(String path) {
    state = state
        .copyWith(visualEvidenceImages: [...state.visualEvidenceImages, path]);
  }

  void setVisualEvidence(List<String> paths) {
    state = state.copyWith(visualEvidenceImages: paths);
  }

  void setSelectedRooms(List<String> roomIds) {
    state = state.copyWith(selectedRoomIds: roomIds);
  }

  void updateRoomTasks(String roomId, Map<String, dynamic> taskDetails) {
    final newTasks = Map<String, dynamic>.from(state.roomTasks);
    newTasks[roomId] = taskDetails;
    state = state.copyWith(roomTasks: newTasks);
  }

  void updateRoomEstimation(String roomId, dynamic expenses) {
    final newEstimations = Map<String, dynamic>.from(state.roomEstimations);
    newEstimations[roomId] = expenses;
    state = state.copyWith(roomEstimations: newEstimations);
  }

  void setProfession(String profession) {
    state = state.copyWith(userProfession: profession);
  }

  void setChantierId(String chantierId) {
    state = state.copyWith(chantierId: chantierId);
  }

  void updateRoomContext(String roomId, RealityFactors context) {
    final newContexts = Map<String, RealityFactors>.from(state.roomContexts);
    newContexts[roomId] = context;
    state = state.copyWith(roomContexts: newContexts);
  }

  void reset() {
    state = QuoteCreationState();
  }
}

final quoteCreationProvider =
    StateNotifierProvider<QuoteCreationNotifier, QuoteCreationState>((ref) {
  return QuoteCreationNotifier();
});
