import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final String type; // 'info', 'alert', 'success'

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.type = 'info',
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    bool? isRead,
    String? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier() : super([]) {
    _loadDummyNotifications();
  }

  void _loadDummyNotifications() {
    state = [
      NotificationItem(
        id: '1',
        title: 'Nouveau message',
        message: 'Vous avez reçu une nouvelle demande de devis pour un projet de rénovation.',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'info',
      ),
      NotificationItem(
        id: '2',
        title: 'Mise à jour système',
        message: 'Une nouvelle version de l\'application est disponible avec des fonctionnalités améliorées.',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: 'alert',
      ),
      NotificationItem(
        id: '3',
        title: 'Devis accepté',
        message: 'Le client Martin a accepté votre devis #D2024-001.',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: 'success',
        isRead: true,
      ),
    ];
  }

  void markAsRead(String id) {
    state = [
      for (final notification in state)
        if (notification.id == id)
          notification.copyWith(isRead: true)
        else
          notification
    ];
  }
  
  void markAllAsRead() {
    state = [
      for (final notification in state)
        notification.copyWith(isRead: true)
    ];
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier();
});
