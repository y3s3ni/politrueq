import 'package:supabase_flutter/supabase_flutter.dart';

class NotificacionesService {
  static final _supabase = Supabase.instance.client;

  /// Crear una nueva notificación
  static Future<Map<String, dynamic>> crearNotificacion({
    required String userId,
    required String type,
    required String title,
    String? body,
    String? relatedId,
  }) async {
    try {
      final response = await _supabase.from('notificaciones').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'related_id': relatedId,
        'is_read': false,
        'is_hidden': false,
      }).select().single();

      return {'success': true, 'data': response};
    } catch (e) {
      print('❌ Error al crear notificación: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Obtener notificaciones del usuario actual
  static Future<Map<String, dynamic>> obtenerNotificaciones({
    bool soloNoLeidas = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'error': 'Usuario no autenticado'};
      }

      final response = soloNoLeidas
          ? await _supabase
              .from('notificaciones')
              .select()
              .eq('user_id', userId)
              .eq('is_hidden', false)
              .eq('is_read', false)
              .order('created_at', ascending: false)
          : await _supabase
              .from('notificaciones')
              .select()
              .eq('user_id', userId)
              .eq('is_hidden', false)
              .order('created_at', ascending: false);

      return {'success': true, 'data': response};
    } catch (e) {
      print('❌ Error al obtener notificaciones: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Contar notificaciones no leídas
  static Future<int> contarNoLeidas() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('notificaciones')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .eq('is_hidden', false);

      return response.length;
    } catch (e) {
      print('❌ Error al contar notificaciones: $e');
      return 0;
    }
  }

  /// Marcar notificación como leída
  static Future<bool> marcarComoLeida(int notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notificaciones')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('❌ Error al marcar como leída: $e');
      return false;
    }
  }

  /// Marcar todas como leídas
  static Future<bool> marcarTodasComoLeidas() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notificaciones')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_hidden', false);

      return true;
    } catch (e) {
      print('❌ Error al marcar todas como leídas: $e');
      return false;
    }
  }

  /// Ocultar notificación
  static Future<bool> ocultarNotificacion(int notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notificaciones')
          .update({'is_hidden': true})
          .eq('id', notificationId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('❌ Error al ocultar notificación: $e');
      return false;
    }
  }

  /// Ocultar todas las notificaciones
  static Future<bool> ocultarTodas() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notificaciones')
          .update({'is_hidden': true})
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('❌ Error al ocultar todas: $e');
      return false;
    }
  }

  /// Stream de notificaciones en tiempo real
  static Stream<List<Map<String, dynamic>>> streamNotificaciones() {
    final userId = _supabase.auth.currentUser?.id;
    
    if (userId == null) {
      return const Stream.empty();
    }

    return _supabase
        .from('notificaciones')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .where((item) => 
                item['user_id'] == userId && 
                item['is_hidden'] == false)
            .toList());
  }

  /// Notificación de nuevo mensaje
  static Future<void> notificarNuevoMensaje({
    required String destinatarioId,
    required String remitenteId,
    required String remitenteNombre,
    required String mensaje,
  }) async {
    await crearNotificacion(
      userId: destinatarioId,
      type: 'mensaje',
      title: 'Nuevo mensaje de $remitenteNombre',
      body: mensaje.length > 100 ? '${mensaje.substring(0, 100)}...' : mensaje,
      relatedId: remitenteId,
    );
  }

  /// Notificación de nuevo intercambio
  static Future<void> notificarNuevoIntercambio({
    required String destinatarioId,
    required String remitenteId,
    required String remitenteNombre,
    required String productoNombre,
  }) async {
    await crearNotificacion(
      userId: destinatarioId,
      type: 'intercambio',
      title: 'Nueva solicitud de intercambio',
      body: '$remitenteNombre quiere intercambiar por tu producto: $productoNombre',
      relatedId: remitenteId,
    );
  }

  /// Notificación de producto aprobado
  static Future<void> notificarProductoAprobado({
    required String userId,
    required String productoNombre,
  }) async {
    await crearNotificacion(
      userId: userId,
      type: 'sistema',
      title: '¡Producto aprobado!',
      body: 'Tu producto "$productoNombre" ha sido aprobado y ya está visible',
    );
  }

  /// Notificación de producto rechazado
  static Future<void> notificarProductoRechazado({
    required String userId,
    required String productoNombre,
    String? motivo,
  }) async {
    await crearNotificacion(
      userId: userId,
      type: 'sistema',
      title: 'Producto rechazado',
      body: 'Tu producto "$productoNombre" fue rechazado${motivo != null ? ': $motivo' : ''}',
    );
  }
}
