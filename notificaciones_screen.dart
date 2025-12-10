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
  late final Stream<List<Map<String, dynamic>>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = NotificacionesService.streamNotificaciones();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    if (notification['is_read'] == false) {
      await _markAsRead(notification['id']);
    }

    final type = notification['type'];
    final relatedId = notification['related_id'];

    if ((type == 'mensaje' || type == 'intercambio') && relatedId != null) {
      final userName = await _getUserName(relatedId.toString()) ?? 'Usuario';
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatScreen(
            otherUserId: relatedId.toString(),
            otherUserName: userName,
          ),
        ));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta notificación es informativa.')),
      );
    }
  }

  Future<String?> _getUserName(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select('name')
          .eq('id', userId)
          .single();
      return response['name'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    await NotificacionesService.marcarComoLeida(notificationId);
  }

  Future<void> _markAsUnread(int notificationId) async {
    await NotificacionesService.marcarComoNoLeida(notificationId);
  }

  Future<void> _deleteNotification(int notificationId) async {
    final success = await NotificacionesService.eliminarNotificacion(notificationId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al eliminar la notificación'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificacionesService.marcarTodasComoLeidas();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Todas las notificaciones marcadas como leídas'
            : 'Error al realizar la acción'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  Future<void> _deleteAllNotifications() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('¿Eliminar Todas?'),
        content: const Text('Esta acción eliminará todas tus notificaciones. No se puede deshacer.'),
        actions: <Widget>[
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final success = await NotificacionesService.eliminarTodas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Se eliminaron todas las notificaciones' : 'Error al eliminar'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color(0xFFB71C1C),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Eliminar todas las notificaciones',
            onPressed: _deleteAllNotifications,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes notificaciones.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
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
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                color: isRead ? Colors.white : const Color(0xFFFFF5F5),
                child: ListTile(
                  isThreeLine: true, // Permite más espacio vertical
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey.shade200 : const Color(0xFFFDE4E4),
                    child: Icon(
                      notification['type'] == 'mensaje' ? Icons.chat_bubble_outline : 
                      notification['type'] == 'intercambio' ? Icons.swap_horiz_outlined : 
                      Icons.notifications_outlined,
                      color: isRead ? Colors.grey : const Color(0xFFB71C1C),
                    ),
                  ),
                  title: Text(
                    notification['title'] ?? 'Sin Título',
                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification['body'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(createdAt, locale: 'es'),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      final id = notification['id'] as int;
                      if (value == 'mark_read') _markAsRead(id);
                      if (value == 'mark_unread') _markAsUnread(id);
                      if (value == 'delete') _deleteNotification(id);
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        if (isRead)
                          const PopupMenuItem<String>(
                            value: 'mark_unread',
                            child: Text('Marcar como no leída'),
                          )
                        else
                          const PopupMenuItem<String>(
                            value: 'mark_read',
                            child: Text('Marcar como leída'),
                          ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ];
                    },
                  ),
                  onTap: () => _handleNotificationTap(notification),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
