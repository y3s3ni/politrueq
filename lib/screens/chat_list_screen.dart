import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final currentUser = supabase.auth.currentUser!.id;

    // Obtener todos los mensajes donde yo participo
    final messages = await supabase
        .from('messages')
        .select('sender_id, receiver_id')
        .or('sender_id.eq.$currentUser,receiver_id.eq.$currentUser');

    // Obtener IDs del otro usuario en cada conversación
    final ids = <String>{};
    for (final m in messages) {
      if (m['sender_id'] != currentUser) ids.add(m['sender_id']);
      if (m['receiver_id'] != currentUser) ids.add(m['receiver_id']);
    }

    if (ids.isEmpty) {
      setState(() => users = []);
      return;
    }

    // 🚀 CORRECCIÓN DEFINITIVA: usar FILTER con operador IN
    final data = await supabase
        .from('usuarios')
        .select('id, name, email')
        .filter('id', 'in', ids.toList());

    setState(() {
      users = List<Map<String, dynamic>>.from(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(u['name']),
            subtitle: Text(u['email']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: u['id'],
                    otherUserName: u['name'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
