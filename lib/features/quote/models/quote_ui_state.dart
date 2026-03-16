// UI state models for the quote feature.
// These contain view-specific state (expansion, photos, user inputs)
// that should NOT be persisted as-is and should NOT be mixed with
// pure domain entities.

/// Holds the UI state of a specific selected task in a room.
class RoomTaskState {
  final String taskId;
  final String roomId;
  final String label;

  /// Whether this task section is expanded in the UI.
  bool isExpanded;

  /// Dynamic user inputs keyed by input field ID.
  final Map<String, dynamic> inputs;

  /// Optional note left by the user for this task.
  String? note;

  /// Photos attached to this task during the quote flow.
  final List<String> photoPaths;

  /// Selected products for this task, keyed by product ID with quantity.
  final Map<String, double> selectedProducts;

  RoomTaskState({
    required this.taskId,
    required this.roomId,
    required this.label,
    this.isExpanded = false,
    Map<String, dynamic>? inputs,
    this.note,
    List<String>? photoPaths,
    Map<String, double>? selectedProducts,
  })  : inputs = inputs ?? {},
        photoPaths = photoPaths ?? [],
        selectedProducts = selectedProducts ?? {};

  RoomTaskState copyWith({
    bool? isExpanded,
    Map<String, dynamic>? inputs,
    String? note,
    List<String>? photoPaths,
    Map<String, double>? selectedProducts,
  }) {
    return RoomTaskState(
      taskId: taskId,
      roomId: roomId,
      label: label,
      isExpanded: isExpanded ?? this.isExpanded,
      inputs: inputs != null ? Map.from(inputs) : Map.from(this.inputs),
      note: note ?? this.note,
      photoPaths: photoPaths != null
          ? List.from(photoPaths)
          : List.from(this.photoPaths),
      selectedProducts: selectedProducts != null
          ? Map.from(selectedProducts)
          : Map.from(this.selectedProducts),
    );
  }
}
