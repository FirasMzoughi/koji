import 'dart:convert';

/// A single in-app notification shown in the home notification panel.
///
/// Currently only signature events are produced, but [type] leaves room for
/// other kinds (planning, payments…) later without changing the storage shape.
class AppNotification {
  final String id; // unique key; for signatures this is "sign_<quoteId>"
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String type;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.type = 'signature',
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        type: type,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'type': type,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        createdAt:
            DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
        read: (j['read'] ?? false) as bool,
        type: (j['type'] ?? 'signature') as String,
      );

  static String encodeList(List<AppNotification> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<AppNotification> decodeList(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
