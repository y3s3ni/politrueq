import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/services/chat_service.dart';



class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String myUserId;

  @override
  void initState() {
    super.initState();
    myUserId = Supabase.instance.client.auth.currentUser!.id;
  }

  /// FILTRO DE MENSAJES
  bool _isBetween(Map msg) {
    return (msg['sender_id'] == myUserId &&
            msg['receiver_id'] == widget.otherUserId) ||
        (msg['sender_id'] == widget.otherUserId &&
            msg['receiver_id'] == myUserId);
  }

  /// ENVIAR MENSAJE
  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _chatService.sendMessage(
      senderId: myUserId,
      receiverId: widget.otherUserId,
      text: text,
    );

    _controller.clear();

    // BAJAR AUTOMÁTICAMENTE AL FINAL
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });

    setState(() {}); // PARA REFRESCAR DE INMEDIATO
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.listenMessages(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages =
                    snapshot.data!.where((m) => _isBetween(m)).toList();

                //SCROLL AUTOMÁTICO
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMine = msg['sender_id'] == myUserId;

                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isMine ? Colors.green[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['message'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT DE MENSAJE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _send,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
