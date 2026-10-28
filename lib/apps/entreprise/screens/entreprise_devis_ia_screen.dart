import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:koji/app/koji_web_api_client.dart';
import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_widgets.dart';

enum _Phase { hero, chat, recap, result }

class _Turn {
  _Turn({required this.role, required this.text});
  final String role; // 'user' | 'assistant'
  final String text;
}

/// IA-assisted quote generation for entreprises (similar to client marketplace publishing).
/// Uses SSE streaming from /api/radar-chat in mode: "entreprise-devis"
class EntrepriseDevisIaScreen extends ConsumerStatefulWidget {
  const EntrepriseDevisIaScreen({super.key});

  @override
  ConsumerState<EntrepriseDevisIaScreen> createState() =>
      _EntrepriseDevisIaScreenState();
}

class _EntrepriseDevisIaScreenState
    extends ConsumerState<EntrepriseDevisIaScreen> {
  _Phase _phase = _Phase.hero;
  late String _conversationId;
  final List<_Turn> _turns = [];
  String _streamingText = '';
  bool _sending = false;
  String? _error;
  StreamSubscription<SseEvent>? _sub;

  final _draftController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _conversationId =
        'devis-ia-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _sub?.cancel();
    _draftController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendToEngine(List<_Turn> turns) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _streamingText = '';
      _error = null;
    });

    try {
      final turnsList = turns
          .map((t) => {'role': t.role, 'text': t.text})
          .toList();

      _sub = ref.read(kojiWebApiClientProvider).postSse(
        '/api/radar-chat',
        {
          'turns': turnsList,
          'conversationId': _conversationId,
          'mode': 'entreprise-devis',
        },
      ).listen(
        (event) {
          setState(() {
            if (event.data == '[DONE]') {
              _turns.add(_Turn(role: 'assistant', text: _streamingText));
              _streamingText = '';
              _phase = _Phase.recap;
            } else {
              _streamingText += event.data ?? '';
            }
          });
          _scrollToBottom();
        },
        onError: (err) {
          setState(() {
            _error = err is KojiWebApiException
                ? err.message
                : "L'assistant n'a pas pu répondre.";
            _sending = false;
          });
        },
        onDone: () {
          if (mounted) setState(() => _sending = false);
        },
      );
    } catch (err) {
      setState(() {
        _error =
            err is KojiWebApiException ? err.message : 'Erreur réseau';
        _sending = false;
      });
    }
  }

  void _answerText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final userTurn = _Turn(role: 'user', text: trimmed);
    final nextTurns = [..._turns, userTurn];
    setState(() {
      _turns.add(userTurn);
      _draftController.clear();
      _phase = _Phase.chat;
    });
    _scrollToBottom();
    _sendToEngine(nextTurns);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.hero => _buildHero(),
      _Phase.chat => _buildChat(),
      _Phase.recap => _buildRecap(),
      _Phase.result => _buildResult(),
    };
  }

  Widget _buildHero() {
    return KojiPage(
      title: 'Créer un devis avec IA',
      appBarOnPhone: true,
      main: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assistant IA pour devis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Décrivez le travail à faire et notre IA créera un devis détaillé.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: KojiButton(
                  label: 'Commencer',
                  onPressed: () {
                    setState(() => _phase = _Phase.chat);
                    _answerText('Bonjour');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChat() {
    return KojiPage(
      title: 'Conversation IA',
      appBarOnPhone: true,
      main: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _turns.length + (_streamingText.isNotEmpty ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _turns.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_streamingText),
                  ),
                );
              }
              final turn = _turns[i];
              final isUser = turn.role == 'user';
              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        isUser ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    turn.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
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
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _draftController,
                  enabled: !_sending,
                  decoration: InputDecoration(
                    hintText: 'Votre réponse…',
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
                      : const Icon(Icons.send),
                  onPressed: _sending
                      ? null
                      : () => _answerText(_draftController.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecap() {
    return KojiPage(
      title: 'Récapitulatif',
      appBarOnPhone: true,
      main: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Conversation complétée'),
              SizedBox(height: 24),
              KojiButton(
                label: 'Voir le devis',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return KojiPage(
      title: 'Devis créé',
      appBarOnPhone: true,
      main: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Votre devis a été créé avec succès!'),
            ],
          ),
        ),
      ],
    );
  }
}
