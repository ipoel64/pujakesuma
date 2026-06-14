import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatRoomScreen({super.key, required this.roomId, required this.roomName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  RealtimeChannel? _chatChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await SupabaseService.getChatMessages(widget.roomId);
      
      // Load user profile details for sender names
      final profiles = await SupabaseService.client.from('profiles').select('id, full_name');
      final nameMap = {for (var p in profiles) p['id'] as String: p['full_name'] as String};

      setState(() {
        _messages.clear();
        for (var m in messages) {
          final senderId = m['sender_id'];
          final isMe = senderId == SupabaseService.currentUser?.id;
          _messages.add({
            'id': m['id'],
            'senderName': isMe ? 'Anda' : (nameMap[senderId] ?? 'Petugas Lapangan'),
            'content': m['content'],
            'isMe': isMe,
            'time': _formatTime(m['created_at']),
          });
        }
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeToMessages() {
    _chatChannel = SupabaseService.client
        .channel('public:chat_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.roomId,
          ),
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final senderId = newRecord['sender_id'];
            final isMe = senderId == SupabaseService.currentUser?.id;

            // Fetch sender name
            String senderName = 'Petugas Lapangan';
            if (isMe) {
              senderName = 'Anda';
            } else {
              final profile = await SupabaseService.getProfile(senderId);
              if (profile != null) {
                senderName = profile['full_name'] ?? 'Petugas Lapangan';
              }
            }

            if (mounted) {
              setState(() {
                _messages.add({
                  'id': newRecord['id'],
                  'senderName': senderName,
                  'content': newRecord['content'],
                  'isMe': isMe,
                  'time': _formatTime(newRecord['created_at']),
                });
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await SupabaseService.sendChatMessage(
        roomId: widget.roomId,
        content: text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      backgroundColor: const Color(0xFF131324),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada pesan. Mulai obrolan sekarang!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['isMe'] == true;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF800020) : const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                                ),
                                border: Border.all(
                                  color: isMe
                                      ? const Color(0xFFD4AF37).withOpacity(0.3)
                                      : const Color(0xFF800020).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      msg['senderName'],
                                      style: const TextStyle(
                                        color: Color(0xFFFFE07D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg['content'],
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      msg['time'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF131324),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_chatChannel != null) {
      SupabaseService.client.removeChannel(_chatChannel!);
    }
    super.dispose();
  }
}
