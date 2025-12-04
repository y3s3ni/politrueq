import 'package:flutter/material.dart';
import 'package:trueque/screens/chat_screen.dart';
import 'package:trueque/services/chat_service.dart';
import 'package:trueque/screens/requests_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService service = ChatService();

  Map<String, dynamic>? userFound;

  void search() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;

    final user = await service.findUser(email);

    setState(() => userFound = user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar usuario")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                label: Text("Correo del usuario"),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: search,
              child: const Text("Buscar"),
            ),
            const SizedBox(height: 20),

            if (userFound != null)
              Card(
                child: ListTile(
                  title: Text(userFound!['name']),
                  subtitle: Text(userFound!['email']),
                  trailing: ElevatedButton(
                    child: const Text("Chatear"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: userFound!['id'],
                            otherUserName: userFound!['name'],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
