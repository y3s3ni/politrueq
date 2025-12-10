import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Servicio para gestionar el sistema de puntos e intercambios
class PuntosService {
  static SupabaseClient get _client => SupabaseService.client;

  // ==================== GESTIÓN DE PUNTOS ====================

  /// Obtener puntos actuales del usuario
  static Future<Map<String, dynamic>> getPuntosUsuario(String userId) async {
    try {
      final response = await _client
          .from('usuarios')
          .select('puntos')
          .eq('id', userId)
          .single();

      return {
        'success': true,
        'puntos': response['puntos'] ?? 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener puntos: $e',
        'puntos': 0,
      };
    }
  }

  /// Obtener historial de puntos del usuario
  static Future<Map<String, dynamic>> getHistorialPuntos(String userId) async {
    try {
      final response = await _client.rpc(
        'get_historial_puntos_usuario',
        params: {'p_usuario_id': userId},
      );

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener historial: $e',
        'data': [],
      };
    }
  }

  /// Verificar si es el primer inicio de sesión y otorgar puntos
  static Future<Map<String, dynamic>> verificarPrimerInicioSesion(
      String userId) async {
    try {
      // Verificar si es primer inicio
      final userData = await _client
          .from('usuarios')
          .select('primer_inicio_sesion, puntos')
          .eq('id', userId)
          .single();

      if (userData['primer_inicio_sesion'] == true) {
        // Marcar como ya no es primer inicio
        await _client.from('usuarios').update({
          'primer_inicio_sesion': false,
        }).eq('id', userId);

        return {
          'success': true,
          'es_primer_inicio': true,
          'puntos_otorgados': 3,
          'message': '¡Bienvenido! Has recibido 3 puntos de regalo',
        };
      }

      return {
        'success': true,
        'es_primer_inicio': false,
        'puntos_actuales': userData['puntos'] ?? 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al verificar primer inicio: $e',
      };
    }
  }

  /// Obtener estadísticas generales de puntos
  static Future<Map<String, dynamic>> getEstadisticasPuntos() async {
    try {
      final response = await _client.rpc('get_estadisticas_puntos');

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener estadísticas: $e',
      };
    }
  }

  // ==================== GESTIÓN DE INTERCAMBIOS ====================

  /// Validar si un intercambio es posible
  static Future<Map<String, dynamic>> validarIntercambio({
    required String usuarioOfertanteId,
    required String usuarioReceptorId,
    required String productoOfertadoId,
    required String productoSolicitadoId,
  }) async {
    try {
      final response = await _client.rpc(
        'validar_puntos_intercambio',
        params: {
          'p_usuario_ofertante_id': usuarioOfertanteId,
          'p_usuario_receptor_id': usuarioReceptorId,
          'p_producto_ofertado_id': productoOfertadoId,
          'p_producto_solicitado_id': productoSolicitadoId,
        },
      );

      return {
        'success': response['valido'] ?? false,
        'message': response['mensaje'] ?? '',
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al validar intercambio: $e',
      };
    }
  }

  /// Proponer un intercambio
  static Future<Map<String, dynamic>> proponerIntercambio({
    required String usuarioReceptorId,
    required String productoOfertadoId,
    required String productoSolicitadoId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Usuario no autenticado',
        };
      }

      // Primero validar el intercambio
      final validacion = await validarIntercambio(
        usuarioOfertanteId: userId,
        usuarioReceptorId: usuarioReceptorId,
        productoOfertadoId: productoOfertadoId,
        productoSolicitadoId: productoSolicitadoId,
      );

      if (!validacion['success']) {
        return validacion;
      }

      // Obtener puntos de los productos
      final productoOfertado = await _client
          .from('productos_unificados')
          .select('puntos_necesarios')
          .eq('id', productoOfertadoId)
          .single();

      final productoSolicitado = await _client
          .from('productos_unificados')
          .select('puntos_necesarios')
          .eq('id', productoSolicitadoId)
          .single();

      // Crear el intercambio
      final response = await _client.from('intercambios').insert({
        'usuario_ofertante_id': userId,
        'usuario_receptor_id': usuarioReceptorId,
        'producto_ofertado_id': productoOfertadoId,
        'producto_solicitado_id': productoSolicitadoId,
        'puntos_producto_ofertado': productoOfertado['puntos_necesarios'],
        'puntos_producto_solicitado': productoSolicitado['puntos_necesarios'],
        'estado': 'propuesto',
      }).select().single();

      return {
        'success': true,
        'message': 'Intercambio propuesto exitosamente',
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al proponer intercambio: $e',
      };
    }
  }

  /// Aceptar un intercambio propuesto
  static Future<Map<String, dynamic>> aceptarIntercambio(
      String intercambioId) async {
    try {
      await _client.from('intercambios').update({
        'estado': 'aceptado',
      }).eq('id', intercambioId);

      return {
        'success': true,
        'message':
            'Intercambio aceptado. Ahora deben coordinar el punto de encuentro',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al aceptar intercambio: $e',
      };
    }
  }

  /// Rechazar un intercambio
  static Future<Map<String, dynamic>> rechazarIntercambio(
      String intercambioId) async {
    try {
      await _client.from('intercambios').update({
        'estado': 'rechazado',
      }).eq('id', intercambioId);

      return {
        'success': true,
        'message': 'Intercambio rechazado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al rechazar intercambio: $e',
      };
    }
  }

  /// Confirmar intercambio (por parte del ofertante o receptor)
  static Future<Map<String, dynamic>> confirmarIntercambio({
    required String intercambioId,
    required bool esOfertante,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Usuario no autenticado',
        };
      }

      final campo = esOfertante
          ? 'confirmado_por_ofertante'
          : 'confirmado_por_receptor';
      final campoFecha = esOfertante
          ? 'fecha_confirmacion_ofertante'
          : 'fecha_confirmacion_receptor';

      await _client.from('intercambios').update({
        campo: true,
        campoFecha: DateTime.now().toIso8601String(),
      }).eq('id', intercambioId);

      // Verificar si ambos confirmaron
      final intercambio = await _client
          .from('intercambios')
          .select('confirmado_por_ofertante, confirmado_por_receptor')
          .eq('id', intercambioId)
          .single();

      if (intercambio['confirmado_por_ofertante'] &&
          intercambio['confirmado_por_receptor']) {
        // Completar el intercambio automáticamente
        return await completarIntercambio(intercambioId);
      }

      return {
        'success': true,
        'message': 'Confirmación registrada. Esperando confirmación del otro usuario',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al confirmar intercambio: $e',
      };
    }
  }

  /// Completar intercambio (otorgar puntos y marcar productos como no disponibles)
  static Future<Map<String, dynamic>> completarIntercambio(
      String intercambioId) async {
    try {
      final response = await _client.rpc(
        'completar_intercambio',
        params: {'p_intercambio_id': intercambioId},
      );

      return {
        'success': response['success'] ?? false,
        'message': response['mensaje'] ?? 'Intercambio completado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al completar intercambio: $e',
      };
    }
  }

  /// Cancelar un intercambio
  static Future<Map<String, dynamic>> cancelarIntercambio(
      String intercambioId) async {
    try {
      await _client.from('intercambios').update({
        'estado': 'cancelado',
      }).eq('id', intercambioId);

      return {
        'success': true,
        'message': 'Intercambio cancelado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al cancelar intercambio: $e',
      };
    }
  }

  /// Obtener intercambios del usuario (como ofertante o receptor)
  static Future<Map<String, dynamic>> getMisIntercambios() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Usuario no autenticado',
          'data': [],
        };
      }

      final response = await _client
          .from('intercambios')
          .select('''
            *,
            producto_ofertado:producto_ofertado_id(id, nombre, image_urls, puntos_necesarios),
            producto_solicitado:producto_solicitado_id(id, nombre, image_urls, puntos_necesarios),
            usuario_ofertante:usuario_ofertante_id(id, name, email),
            usuario_receptor:usuario_receptor_id(id, name, email)
          ''')
          .or('usuario_ofertante_id.eq.$userId,usuario_receptor_id.eq.$userId')
          .order('creado_en', ascending: false);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener intercambios: $e',
        'data': [],
      };
    }
  }

  /// Obtener intercambios pendientes (propuestos para el usuario)
  static Future<Map<String, dynamic>> getIntercambiosPendientes() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Usuario no autenticado',
          'data': [],
        };
      }

      final response = await _client
          .from('intercambios')
          .select('''
            *,
            producto_ofertado:producto_ofertado_id(id, nombre, image_urls, puntos_necesarios),
            producto_solicitado:producto_solicitado_id(id, nombre, image_urls, puntos_necesarios),
            usuario_ofertante:usuario_ofertante_id(id, name, email)
          ''')
          .eq('usuario_receptor_id', userId)
          .eq('estado', 'propuesto')
          .order('creado_en', ascending: false);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener intercambios pendientes: $e',
        'data': [],
      };
    }
  }

  /// Obtener detalles de un intercambio específico
  static Future<Map<String, dynamic>> getDetalleIntercambio(
      String intercambioId) async {
    try {
      final response = await _client
          .from('intercambios')
          .select('''
            *,
            producto_ofertado:producto_ofertado_id(id, nombre, descripcion, image_urls, puntos_necesarios, categoria),
            producto_solicitado:producto_solicitado_id(id, nombre, descripcion, image_urls, puntos_necesarios, categoria),
            usuario_ofertante:usuario_ofertante_id(id, name, email),
            usuario_receptor:usuario_receptor_id(id, name, email),
            punto_intercambio:punto_intercambio_id(id, nombre, latitud, longitud)
          ''')
          .eq('id', intercambioId)
          .single();

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener detalle del intercambio: $e',
      };
    }
  }

  /// Establecer punto de encuentro para el intercambio
  static Future<Map<String, dynamic>> establecerPuntoEncuentro({
    required String intercambioId,
    String? puntoIntercambioId,
    String? ubicacionAcordada,
    DateTime? fechaAcordada,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (puntoIntercambioId != null) {
        data['punto_intercambio_id'] = puntoIntercambioId;
      }
      if (ubicacionAcordada != null) {
        data['ubicacion_acordada'] = ubicacionAcordada;
      }
      if (fechaAcordada != null) {
        data['fecha_acordada'] = fechaAcordada.toIso8601String();
      }

      await _client.from('intercambios').update(data).eq('id', intercambioId);

      return {
        'success': true,
        'message': 'Punto de encuentro establecido',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al establecer punto de encuentro: $e',
      };
    }
  }

  /// Calificar un intercambio completado
  static Future<Map<String, dynamic>> calificarIntercambio({
    required String intercambioId,
    required bool esOfertante,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      if (calificacion < 1 || calificacion > 5) {
        return {
          'success': false,
          'message': 'La calificación debe estar entre 1 y 5',
        };
      }

      final campoCalificacion =
          esOfertante ? 'calificacion_ofertante' : 'calificacion_receptor';
      final campoComentario =
          esOfertante ? 'comentario_ofertante' : 'comentario_receptor';

      final data = <String, dynamic>{
        campoCalificacion: calificacion,
      };

      if (comentario != null && comentario.isNotEmpty) {
        data[campoComentario] = comentario;
      }

      await _client.from('intercambios').update(data).eq('id', intercambioId);

      return {
        'success': true,
        'message': 'Calificación registrada exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al calificar intercambio: $e',
      };
    }
  }

  // ==================== BÚSQUEDA Y FILTROS ====================

  /// Buscar productos disponibles por rango de puntos
  static Future<Map<String, dynamic>> buscarProductosPorPuntos({
    required int puntosMinimos,
    required int puntosMaximos,
  }) async {
    try {
      final response = await _client
          .from('productos_unificados')
          .select()
          .eq('disponible', true)
          .eq('estado_aprobacion', 'aprobado')
          .gte('puntos_necesarios', puntosMinimos)
          .lte('puntos_necesarios', puntosMaximos)
          .order('creado_en', ascending: false);

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al buscar productos: $e',
        'data': [],
      };
    }
  }

  /// Buscar productos compatibles para intercambio (con puntos similares)
  static Future<Map<String, dynamic>> buscarProductosCompatibles(
      String productoId) async {
    try {
      // Obtener puntos del producto
      final producto = await _client
          .from('productos_unificados')
          .select('puntos_necesarios, usuario_id')
          .eq('id', productoId)
          .single();

      final puntos = producto['puntos_necesarios'] as int;
      final usuarioId = producto['usuario_id'] as String;

      // Buscar productos con puntos similares (±2 puntos) de otros usuarios
      final response = await _client
          .from('productos_unificados')
          .select()
          .eq('disponible', true)
          .eq('estado_aprobacion', 'aprobado')
          .neq('usuario_id', usuarioId)
          .gte('puntos_necesarios', puntos - 2)
          .lte('puntos_necesarios', puntos + 2)
          .order('puntos_necesarios', ascending: true);

      return {
        'success': true,
        'data': response,
        'puntos_referencia': puntos,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al buscar productos compatibles: $e',
        'data': [],
      };
    }
  }
}
