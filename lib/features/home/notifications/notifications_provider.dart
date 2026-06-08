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
  // Ids the user explicitly dismissed (cleared / deleted). The home screen
  // re-derives signature/message notifications from a live stream on every
  // emission, so without this set a cleared "Devis signé" would be re-added on
  // the very next stream tick. Persisting the dismissed ids makes deletion
  // stick across stream replays and app restarts.
  static const _dismissedKey = 'app_notifications_dismissed_v1';
  static const _maxItems = 50;
  static const _maxDismissed = 500;

  Set<String> _dismissed = <String>{};
  bool _loaded = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissed = prefs.getStringList(_dismissedKey)?.toSet() ?? <String>{};
    final raw = prefs.getString(_storeKey);
    if (raw != null) {
      final items = AppNotification.decodeList(raw)
          .where((n) => !_dismissed.contains(n.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = items;
    }
    _loaded = true;
  }

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> _ensureLoaded() async {
    // add() can race the constructor's _load(); make sure the dismissed set is
    // hydrated before we decide whether to skip an incoming notification.
    if (_loaded) return;
    await _load();
  }

  Future<void> _persist() async {
    final prefs = await _prefs;
    await prefs.setString(_storeKey, AppNotification.encodeList(state));
  }

  Future<void> _persistDismissed() async {
    final prefs = await _prefs;
    // Cap the dismissed history so it can't grow unbounded.
    if (_dismissed.length > _maxDismissed) {
      _dismissed = _dismissed.skip(_dismissed.length - _maxDismissed).toSet();
    }
    await prefs.setStringList(_dismissedKey, _dismissed.toList());
  }

  /// Add a notification unless one with the same [id] already exists
  /// (idempotent — safe to call on every stream replay of a signed quote), or
  /// the user has previously dismissed it.
  Future<void> add(AppNotification n) async {
    await _ensureLoaded();
    if (_dismissed.contains(n.id)) return;
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

  /// Remove a single notification and remember it as dismissed so the stream
  /// doesn't resurrect it.
  Future<void> dismiss(String id) async {
    await _ensureLoaded();
    _dismissed.add(id);
    state = [for (final n in state) if (n.id != id) n];
    await _persist();
    await _persistDismissed();
  }

  Future<void> clear() async {
    await _ensureLoaded();
    _dismissed.addAll(state.map((n) => n.id));
    state = const [];
    await _persist();
    await _persistDismissed();
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
