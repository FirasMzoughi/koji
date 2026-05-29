import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:koji/features/home/notifications/app_notification.dart';

/// Persisted list of in-app notifications, newest first.
///
/// The home header reads this for the unread badge; the notifications panel
/// reads it for the full list. Persisting to SharedPreferences keeps alerts
/// around across app restarts so a signature isn't lost if the user wasn't
/// looking when it arrived.
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(const []) {
    _load();
  }

  static const _storeKey = 'app_notifications_v1';
  static const _maxItems = 50;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw != null) {
      final items = AppNotification.decodeList(raw)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = items;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, AppNotification.encodeList(state));
  }

  /// Add a notification unless one with the same [id] already exists
  /// (idempotent — safe to call on every stream replay of a signed quote).
  Future<void> add(AppNotification n) async {
    if (state.any((e) => e.id == n.id)) return;
    final next = [n, ...state];
    if (next.length > _maxItems) next.removeRange(_maxItems, next.length);
    state = next;
    await _persist();
  }

  int get unreadCount => state.where((n) => !n.read).length;

  Future<void> markAllRead() async {
    if (state.every((n) => n.read)) return;
    state = [for (final n in state) n.copyWith(read: true)];
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

/// Convenience selector for the unread count (drives the header badge).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider);
  return items.where((n) => !n.read).length;
});
