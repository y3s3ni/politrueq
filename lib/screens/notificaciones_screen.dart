import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:trueque/screens/chat_screen.dart';
import 'package:trueque/services/notificaciones_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = NotificacionesService.streamNotificaciones();
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    final type = notification['type'];
    final relatedId = notification['related_id'];

    print('🔔 Notificación clickeada:');
    print('   Tipo: $type');
    print('   Related ID: $relatedId');

    if ((type == 'mensaje' || type == 'intercambio') && relatedId != null && relatedId.toString().isNotEmpty) {
      if (mounted) {
        // Extraer el nombre del remitente del título
        final title = notification['title'] ?? '';
        String senderName = 'Usuario';
        
        if (title.contains('Nuevo mensaje de ')) {
          senderName = title.replaceAll('Nuevo mensaje de ', '').trim();
        } else if (title.contains('Nueva solicitud de intercambio')) {
          // Para intercambios, extraer el nombre del body
          final body = notification['body'] ?? '';
          if (body.isNotEmpty) {
            final match = RegExp(r'^(.+?) quiere intercambiar').firstMatch(body);
            if (match != null) {
              senderName = match.group(1) ?? 'Usuario';
            }
          }
        }

        print('   Navegando al chat con: $senderName (ID: $relatedId)');
        
        try {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUserId: relatedId.toString(),
                otherUserName: senderName,
              ),
            ),
          );
        } catch (e) {
          print('❌ Error al navegar al chat: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al abrir el chat: $e')),
            );
          }
        }
      }
    } else {
      print('   No se puede navegar: tipo=$type, relatedId=$relatedId');
      if (mounted && type != 'sistema' && type != 'puntos') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta notificación no tiene un chat asociado')),
        );
      }
    }
  }

  Future<void> _updateNotificationReadState(int notificationId, bool isRead) async {
    if (isRead) {
      await NotificacionesService.marcarComoLeida(notificationId);
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificacionesService.marcarTodasComoLeidas();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Todas las notificaciones marcadas como leídas'
            : 'Error al marcar como leídas'
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _hideNotification(int notificationId) async {
    final success = await NotificacionesService.ocultarNotificacion(notificationId);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar la notificación'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _hideAllNotifications() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Todas'),
          content: const Text('¿Estás seguro? Todas tus notificaciones se ocultarán permanentemente.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await NotificacionesService.ocultarTodas();
    }
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('es', timeago.EsMessages());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color(0xFFEF233C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Eliminar todas las notificaciones',
            onPressed: _hideAllNotifications,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No tienes notificaciones nuevas.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] as bool? ?? false;
              final createdAt = DateTime.parse(notification['created_at']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: isRead ? Colors.white : Colors.red.shade50,
                child: ListTile(
                  leading: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.notifications, color: Color(0xFFB71C1C), size: 30),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    notification['title'] ?? 'Sin Título',
                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: notification['body'] != null ? Text(notification['body']!) : null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'mark_unread') {
                        _updateNotificationReadState(notification['id'], false);
                      } else if (value == 'delete') {
                        _hideNotification(notification['id']);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'mark_unread',
                        child: Text('Marcar como no leída'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Text(
                            timeago.format(createdAt, locale: 'es'),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    if (!isRead) {
                       _updateNotificationReadState(notification['id'], true);
                    } 
                    _handleNotificationTap(notification);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
