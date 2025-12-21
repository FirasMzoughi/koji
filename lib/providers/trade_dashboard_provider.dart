import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/models/trade_data.dart';
import 'package:uuid/uuid.dart';

// Modèle pour une pièce sélectionnée
class SelectedRoom {
  final String id;
  final String name;
  final List<JobPost> posts;
  final List<Task> tasks;

  SelectedRoom({
    required this.id,
    required this.name,
    this.posts = const [],
    this.tasks = const [],
  });

  SelectedRoom copyWith({
    String? id,
    String? name,
    List<JobPost>? posts,
    List<Task>? tasks,
  }) {
    return SelectedRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      posts: posts ?? this.posts,
      tasks: tasks ?? this.tasks,
    );
  }
}

// État du dashboard métier
class TradeDashboardState {
  final Trade trade;
  final List<SelectedRoom> rooms;
  final List<Task> globalTasks;

  TradeDashboardState({
    required this.trade,
    this.rooms = const [],
    this.globalTasks = const [],
  });

  TradeDashboardState copyWith({
    Trade? trade,
    List<SelectedRoom>? rooms,
    List<Task>? globalTasks,
  }) {
    return TradeDashboardState(
      trade: trade ?? this.trade,
      rooms: rooms ?? this.rooms,
      globalTasks: globalTasks ?? this.globalTasks,
    );
  }

  double get totalHT {
    double total = 0;
    for (var room in rooms) {
      for (var post in room.posts) {
        total += post.totalHT;
      }
    }
    return total;
  }
}

// Notifier pour gérer l'état du dashboard
class TradeDashboardNotifier extends StateNotifier<TradeDashboardState> {
  TradeDashboardNotifier(Trade trade)
      : super(TradeDashboardState(
          trade: trade,
          globalTasks: DefaultTasks.getTasksForTrade(trade)
              .map((name) => Task(
                    id: const Uuid().v4(),
                    name: name,
                  ))
              .toList(),
        ));

  // Ajouter une pièce
  void addRoom(String roomName) {
    final newRoom = SelectedRoom(
      id: const Uuid().v4(),
      name: roomName,
      posts: DefaultJobPosts.getPostsForTrade(state.trade)
          .map((postName) => JobPost(
                id: const Uuid().v4(),
                name: postName,
                unit: JobUnit.squareMeter,
              ))
          .toList(),
    );

    state = state.copyWith(
      rooms: [...state.rooms, newRoom],
    );
  }

  // Supprimer une pièce
  void removeRoom(String roomId) {
    state = state.copyWith(
      rooms: state.rooms.where((r) => r.id != roomId).toList(),
    );
  }

  // Mettre à jour un poste
  void updatePost(String roomId, JobPost updatedPost) {
    final rooms = state.rooms.map((room) {
      if (room.id == roomId) {
        final posts = room.posts.map((post) {
          return post.id == updatedPost.id ? updatedPost : post;
        }).toList();
        return room.copyWith(posts: posts);
      }
      return room;
    }).toList();

    state = state.copyWith(rooms: rooms);
  }

  // Ajouter un poste personnalisé
  void addCustomPost(String roomId, String postName) {
    final rooms = state.rooms.map((room) {
      if (room.id == roomId) {
        final newPost = JobPost(
          id: const Uuid().v4(),
          name: postName,
          unit: JobUnit.squareMeter,
        );
        return room.copyWith(posts: [...room.posts, newPost]);
      }
      return room;
    }).toList();

    state = state.copyWith(rooms: rooms);
  }

  // Supprimer un poste
  void removePost(String roomId, String postId) {
    final rooms = state.rooms.map((room) {
      if (room.id == roomId) {
        return room.copyWith(
          posts: room.posts.where((p) => p.id != postId).toList(),
        );
      }
      return room;
    }).toList();

    state = state.copyWith(rooms: rooms);
  }

  // Basculer l'état d'une tâche
  void toggleTask(String taskId) {
    final tasks = state.globalTasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();

    state = state.copyWith(globalTasks: tasks);
  }

  // Ajouter une tâche personnalisée
  void addCustomTask(String taskName) {
    final newTask = Task(
      id: const Uuid().v4(),
      name: taskName,
      isCustom: true,
    );

    state = state.copyWith(
      globalTasks: [...state.globalTasks, newTask],
    );
  }

  // Supprimer une tâche personnalisée
  void removeTask(String taskId) {
    state = state.copyWith(
      globalTasks: state.globalTasks.where((t) => t.id != taskId).toList(),
    );
  }
}

// Provider factory pour chaque métier
final tradeDashboardProvider = StateNotifierProvider.family<
    TradeDashboardNotifier, TradeDashboardState, Trade>((ref, trade) {
  return TradeDashboardNotifier(trade);
});
