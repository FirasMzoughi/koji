import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuoteCreationState {
  final Map<String, dynamic> clientInfo;
  final List<String> visualEvidenceImages;
  final List<String> selectedRoomIds;
  final Map<String, dynamic> roomEstimations; // Map<roomId, List<ExpenseItem>>
  final Map<String, dynamic> roomTasks;
  final String? userProfession; // Store user's profession

  QuoteCreationState({
    this.clientInfo = const {},
    this.visualEvidenceImages = const [],
    this.selectedRoomIds = const [],
    this.roomEstimations = const {},
    this.roomTasks = const {},
    this.userProfession,
  });

  QuoteCreationState copyWith({
    Map<String, dynamic>? clientInfo,
    List<String>? visualEvidenceImages,
    List<String>? selectedRoomIds,
    Map<String, dynamic>? roomEstimations,
    Map<String, dynamic>? roomTasks,
    String? userProfession,
  }) {
    return QuoteCreationState(
      clientInfo: clientInfo ?? this.clientInfo,
      visualEvidenceImages: visualEvidenceImages ?? this.visualEvidenceImages,
      selectedRoomIds: selectedRoomIds ?? this.selectedRoomIds,
      roomEstimations: roomEstimations ?? this.roomEstimations,
      roomTasks: roomTasks ?? this.roomTasks,
      userProfession: userProfession ?? this.userProfession,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'client': clientInfo,
      'images': visualEvidenceImages,
      'roomIds': selectedRoomIds,
      'expenses': roomEstimations,
      'tasks': roomTasks,
      'profession': userProfession,
    };
  }
}

class QuoteCreationNotifier extends StateNotifier<QuoteCreationState> {
  QuoteCreationNotifier() : super(QuoteCreationState());

  void updateClientInfo(Map<String, dynamic> info) {
    state = state.copyWith(clientInfo: info);
  }

  void addVisualEvidence(String path) {
    state = state.copyWith(visualEvidenceImages: [...state.visualEvidenceImages, path]);
  }
  
  void setVisualEvidence(List<String> paths) {
    state = state.copyWith(visualEvidenceImages: paths);
  }
  
  void setSelectedRooms(List<String> roomIds) {
    state = state.copyWith(selectedRoomIds: roomIds);
  }

  void updateRoomTasks(String roomId, Set<String> tasks, Map<String, String> notes) {
    final newTasks = Map<String, dynamic>.from(state.roomTasks);
    newTasks[roomId] = {
      'tasks': tasks.toList(),
      'notes': notes,
    };
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

  void reset() {
    state = QuoteCreationState();
  }
}

final quoteCreationProvider = StateNotifierProvider<QuoteCreationNotifier, QuoteCreationState>((ref) {
  return QuoteCreationNotifier();
});
