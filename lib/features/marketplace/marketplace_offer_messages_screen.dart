import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:koji/design/koji_icons.dart';
import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_tokens.dart';
import 'package:koji/design/koji_widgets.dart';
import 'package:koji/features/marketplace/repository/marketplace_repository.dart';

/// Messaging with entreprises on a marketplace offer.
/// Each offer has its own conversation thread (like project messages).
class MarketplaceOfferMessagesScreen extends ConsumerStatefulWidget {
  final String offerId;
  const MarketplaceOfferMessagesScreen({super.key, required this.offerId});

  @override
  ConsumerState<MarketplaceOfferMessagesScreen> createState() =>
      _MarketplaceOfferMessagesScreenState();
}

class _MarketplaceOfferMessagesScreenState
    extends ConsumerState<MarketplaceOfferMessagesScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;
  String? _error;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ref
          .read(marketplaceRepositoryProvider)
          .getOfferMessages(widget.offerId);
      if (mounted) setState(() => _messages = messages);
    } catch (err) {
      if (mounted) setState(() => _error = 'Impossible de charger les messages');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final newMessage = await ref
          .read(marketplaceRepositoryProvider)
          .sendOfferMessage(
            offerId: widget.offerId,
            text: text,
          );
      if (!mounted) return;
      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
      });
    } catch (err) {
      if (mounted) {
        setState(() =>
            _error = 'Impossible d\'envoyer le message. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.koji;

    return KojiPage(
      title: 'Messages',
      appBarOnPhone: true,
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Aucun message pour le moment',
                      style: TextStyle(color: p.muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isOwn = msg['sender'] == 'self';
                      return Align(
                        alignment: isOwn
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isOwn
                                ? const Color(0xff0052cc)
                                : const Color(0xfff5f7fa),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  color: isOwn ? Colors.white : p.ink,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg['createdAt'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOwn
                                      ? Colors.white70
                                      : const Color(0xff718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xffc62828), fontSize: 13),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: const Color(0xffe0e6ed))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_sending,
                    decoration: InputDecoration(
                      hintText: 'Votre message…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(KojiIcons.send),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
