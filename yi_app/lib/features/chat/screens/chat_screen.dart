import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../privileges/screens/privilege_detail_screen.dart';

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final bool isLoading;
  final List<Map<String, dynamic>> actions;

  ChatMessage({
    required this.role,
    required this.content,
    this.isLoading = false,
    this.actions = const [],
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

const _kSuggestions = [
  '📅 Upcoming events',
  '🎁 Privileges & offers',
  '🎂 Birthdays this month',
  '👥 Find a member',
  '🤝 Our partners',
];

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      role: 'assistant',
      content: 'Hi! I\'m the YI Assistant 👋\nAsk me anything about Young Indians — events, members, privileges, birthdays, or how the chapter works.',
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendSuggestion(String text) {
    _inputCtrl.text = text;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    _inputCtrl.clear();
    setState(() {
      _showSuggestions = false;
      _messages.add(ChatMessage(role: 'user', content: text));
      _messages.add(ChatMessage(role: 'assistant', content: '', isLoading: true));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai-chat',
        body: {
          'messages': _messages
            .where((m) => !m.isLoading)
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final reply = data['reply'] as String? ?? 'Sorry, I could not process that.';
      final rawActions = data['actions'] as List? ?? [];
      final actions = rawActions.map((a) => Map<String, dynamic>.from(a as Map)).toList();
      setState(() {
        _messages.removeLast(); // remove loading
        _messages.add(ChatMessage(role: 'assistant', content: reply, actions: actions));
      });
    } catch (e) {
      debugPrint('Chat error: $e');
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'Sorry, I\'m having trouble connecting right now. Please try again.',
        ));
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.green, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YI Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Powered by AI', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => _MessageBubble(message: _messages[i]),
            ),
          ),

          // Suggestion chips
          if (_showSuggestions)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _kSuggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _sendSuggestion(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(fontSize: 13, color: AppColors.white),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask about YI...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _sending ? AppColors.surfaceAlt : AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _sending
                      ? const Center(
                          child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  void _handleAction(BuildContext context, Map<String, dynamic> action) {
    final type = action['type'] as String?;
    final id   = action['id'] as String?;
    final data = action['data'] as Map<String, dynamic>?;

    switch (type) {
      case 'event':
        if (id != null) context.push('/events/$id');
        break;
      case 'member':
        if (id != null) context.push('/members/$id');
        break;
      case 'online_offer':
        if (data != null) {
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
            builder: (_) => OnlineOfferDetailScreen(offer: data),
          ));
        }
        break;
      case 'offline_offer':
        if (data != null) {
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
            builder: (_) => OfflineOfferDetailScreen(offer: data),
          ));
        }
        break;
    }
  }

  IconData _actionIcon(String? type) {
    switch (type) {
      case 'event':        return Icons.event_outlined;
      case 'member':       return Icons.person_outline;
      case 'online_offer': return Icons.language_outlined;
      case 'offline_offer':return Icons.storefront_outlined;
      default:             return Icons.arrow_forward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final hasActions = !isUser && message.actions.isNotEmpty && !message.isLoading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.green, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.green : AppColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.border),
                  ),
                  child: message.isLoading
                    ? const _TypingIndicator()
                    : Text(
                        message.content,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14, height: 1.5,
                        ),
                      ),
                ),
                // Action chips
                if (hasActions) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.actions.map((action) {
                      final label = action['label'] as String? ?? '';
                      final type  = action['type'] as String?;
                      return GestureDetector(
                        onTap: () => _handleAction(context, action),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 190),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.green.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_actionIcon(type), size: 12, color: AppColors.green),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> {
  static const _phrases = [
    'Thinking',
    'Looking it up',
    'Finding details',
    'Checking data',
    'Almost there',
  ];

  int _phraseIndex = 0;
  int _dotCount = 0;
  late final _dotTimer = Stream.periodic(const Duration(milliseconds: 500), (i) => i).listen((_) {
    if (!mounted) return;
    setState(() => _dotCount = (_dotCount + 1) % 4);
  });
  late final _phraseTimer = Stream.periodic(const Duration(milliseconds: 2000), (i) => i).listen((_) {
    if (!mounted) return;
    // Stop advancing once we reach the last phrase ("Almost there")
    if (_phraseIndex < _phrases.length - 1) {
      setState(() => _phraseIndex++);
    }
  });

  @override
  void initState() {
    super.initState();
    _dotTimer;
    _phraseTimer;
  }

  @override
  void dispose() {
    _dotTimer.cancel();
    _phraseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    return Text(
      '${_phrases[_phraseIndex]}$dots',
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 14,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
