
class TaskCategory {
  final String title;
  final List<TaskItem> tasks;

  TaskCategory({required this.title, required this.tasks});
}

class TaskItem {
  final String id;
  final String label;

  TaskItem({required this.id, required this.label});
}

// Profession-specific task data
// CLEARED per user request - dynamic tasks only
final Map<String, List<TaskCategory>> professionTasksData = {
  // Empty - no default tasks
};

// Get tasks for a specific profession
List<TaskCategory> getTasksForProfession(String? profession) {
  // Return empty or fetch? logic updates might be needed elsewhere if this returns empty.
  if (profession == null) return [];
  
  // "Tout corps d'état" gets all tasks
  if (profession == "Tout corps d'état") {
    final allTasks = <TaskCategory>[];
    professionTasksData.forEach((key, value) {
      if (key != "Tout corps d'état") {
        allTasks.addAll(value);
      }
    });
    return allTasks;
  }
  
  return professionTasksData[profession] ?? [];
}
