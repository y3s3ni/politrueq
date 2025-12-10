import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/modelo/user.model.dart';
import 'package:trueque/screens/chat_screen.dart';
import 'package:trueque/services/supabase_service.dart';

class MapaUnificadoScreen extends StatefulWidget {
  final UserModel? currentUser;
  
  const MapaUnificadoScreen({super.key, this.currentUser});

  @override
  State<MapaUnificadoScreen> createState() => _MapaUnificadoScreenState();
}

class _MapaUnificadoScreenState extends State<MapaUnificadoScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final _supabase = Supabase.instance.client;
  final LatLng _espochCenter = LatLng(-1.6540, -78.6789);

  // Subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _locationsSubscription;
  Timer? _userLocationTimer;

  // State
  Position? _currentUserPosition;
  List<Map<String, dynamic>> _allUserLocations = [];
  List<Map<String, dynamic>> _puntosIntercambio = [];
  Map<String, String> _userNames = {};
  bool _hasCenteredMap = false;
  bool _isCreatingPoint = false;
  bool _showUsers = true;
  bool _showPoints = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializar en segundo plano sin bloquear
    _initializeMapAsync();
  }
  
  void _initializeMapAsync() {
    // Cargar datos en segundo plano sin bloquear UI
    _loadPuntosIntercambio();
    _initializeLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startLocationUpdates();
    } else if (state == AppLifecycleState.paused) {
      _stopLocationUpdates();
    }
  }

  Future<void> _initializeLocation() async {
    // Primero cargar ubicación de BD (instantáneo)
    await _getInitialLocation();
    
    // Configurar stream de usuarios (no bloquea)
    _setupUserLocationsStream();
    
    // Pedir permisos en segundo plano
    _requestLocationPermission();
  }
  
  Future<void> _requestLocationPermission() async {
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        // Iniciar actualizaciones GPS solo si hay permisos
        _startLocationUpdates();
      } else {
        debugPrint('⚠️ Permisos de ubicación denegados');
      }
    } catch (e) {
      debugPrint('⚠️ Error solicitando permisos: $e');
    }
  }

  Future<void> _loadPuntosIntercambio() async {
    try {
      final result = await SupabaseService.getPuntosIntercambio();
      if (result['success'] && mounted) {
        setState(() {
          _puntosIntercambio = List<Map<String, dynamic>>.from(result['data']);
        });
        debugPrint('✅ ${_puntosIntercambio.length} puntos de intercambio cargados');
      }
    } catch (e) {
      debugPrint('⚠️ No se pudieron cargar puntos de intercambio: $e');
      // Si falla, continuar sin puntos (no bloquear el mapa)
      if (mounted) {
        setState(() {
          _puntosIntercambio = [];
        });
      }
    }
  }

  Future<void> _getInitialLocation() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('localizacion')
          .select('lat, lon')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['lat'] != null && response['lon'] != null && mounted) {
        setState(() {
          _currentUserPosition = Position(
            latitude: (response['lat'] as num).toDouble(),
            longitude: (response['lon'] as num).toDouble(),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });
        debugPrint('✅ Ubicación inicial cargada desde BD');
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo cargar ubicación inicial: $e');
    }
  }

  void _setupUserLocationsStream() {
    _locationsSubscription = _supabase
        .from('localizacion')
        .stream(primaryKey: ['user_id']).listen((locations) {
      if (!mounted) return;

      final userIds = locations
          .map((loc) => loc['user_id'] as String?)
          .where((id) => id != null)
          .toSet();
      
      // Cargar nombres en segundo plano sin bloquear
      _fetchUserNames(userIds);

      if (mounted) {
        setState(() {
          _allUserLocations = locations;
        });
      }
      
      debugPrint('📍 ${locations.length} ubicaciones actualizadas');
    }, onError: (error) {
      debugPrint('❌ Error en stream de ubicaciones: $error');
    });
  }

  Future<void> _fetchUserNames(Set<String?> userIds) async {
    final idsToFetch = userIds
        .where((id) => id != null && !_userNames.containsKey(id))
        .cast<String>()
        .toList();

    if (idsToFetch.isEmpty) return;

    try {
      final response = await _supabase
          .from('usuarios')
          .select('id, name')
          .inFilter('id', idsToFetch);

      if (mounted) {
        final Map<String, String> newNames = {
          for (var user in response)
            user['id'] as String: user['name'] as String
        };
        
        setState(() {
          _userNames.addAll(newNames);
        });
        
        debugPrint('✅ ${newNames.length} nombres de usuario cargados');
      }
    } catch (e) {
      debugPrint('⚠️ Error cargando nombres: $e');
    }
  }

  void _startLocationUpdates() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || (_userLocationTimer?.isActive ?? false)) return;

    Future<void> updateUserPosition() async {
      try {
        // Verificar si el servicio de ubicación está habilitado
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('⚠️ GPS deshabilitado, usando ubicación de BD');
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Cambiar a medium para más velocidad
          timeLimit: const Duration(seconds: 3), // Reducir timeout a 3 segundos
        );
        
        if (mounted) {
          setState(() => _currentUserPosition = position);
          _updateUserLocationInSupabase(position, currentUserId);
          debugPrint('📍 GPS actualizado: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
        }
      } catch (e) {
        // Silencioso en producción, solo log en debug
        debugPrint('⚠️ GPS no disponible, usando ubicación de BD');
      }
    }

    // Primera actualización en segundo plano (no bloquear)
    updateUserPosition();
    
    // Actualizaciones periódicas cada 20 segundos (menos frecuente = más eficiente)
    _userLocationTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      await updateUserPosition();
    });
  }

  Future<void> _updateUserLocationInSupabase(Position position, String userId) async {
    try {
      await _supabase.from('localizacion').upsert({
        'user_id': userId,
        'lat': position.latitude,
        'lon': position.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Error al actualizar la ubicación: $e');
    }
  }

  void _stopLocationUpdates() {
    _userLocationTimer?.cancel();
  }

  bool _canManagePoints() {
    if (widget.currentUser == null) return false;
    final role = widget.currentUser!.rol.toLowerCase();
    return role == 'admin' || role == 'administrador' || role == 'moderador';
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    final currentUserId = _supabase.auth.currentUser?.id;

    // Marcador de la ESPOCH
    markers.add(
      Marker(
        point: _espochCenter,
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showInfoDialog(
            'ESPOCH',
            'Escuela Superior Politécnica de Chimborazo',
            Icons.school,
            const Color(0xFFEF233C),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEF233C),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
        ),
      ),
    );

    // Marcadores de usuarios
    if (_showUsers) {
      for (var location in _allUserLocations) {
        final userId = location['user_id'];
        if (userId == currentUserId) continue;

        final lat = location['lat'];
        final lon = location['lon'];
        if (lat == null || lon == null) continue;

        final userName = _userNames[userId] ?? 'Usuario';

        markers.add(
          Marker(
            width: 50,
            height: 50,
            point: LatLng((lat as num).toDouble(), (lon as num).toDouble()),
            child: GestureDetector(
              onTap: () => _showUserDialog(userId, userName),
              child: const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ),
          ),
        );
      }
    }

    // Marcador de ubicación actual
    if (_currentUserPosition != null) {
      markers.add(
        Marker(
          width: 50,
          height: 50,
          point: LatLng(_currentUserPosition!.latitude, _currentUserPosition!.longitude),
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    }

    // Marcadores de puntos de intercambio
    if (_showPoints) {
      for (var punto in _puntosIntercambio) {
        markers.add(
          Marker(
            point: LatLng(punto['latitud'], punto['longitud']),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showPuntoDialog(punto),
              child: const Icon(
                Icons.place,
                color: Color(0xFFEF233C),
                size: 40,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  void _showInfoDialog(String title, String description, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showUserDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con colores del chat
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEF233C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF233C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                            SizedBox(width: 6),
                            Text(
                              'En línea',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    '¿Deseas iniciar una conversación?',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF233C)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Color(0xFFEF233C)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUserId: userId,
                                otherUserName: userName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF233C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble, color: Colors.white),
                        label: const Text(
                          'Chatear',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePointDialog(LatLng point) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF233C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_location_alt, color: Color(0xFFEF233C)),
            ),
            const SizedBox(width: 12),
            const Text('Nuevo Punto'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ubicación: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Edificio Central',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe el punto...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa una descripción' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                
                final result = await SupabaseService.createPuntoIntercambio(
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  latitud: point.latitude,
                  longitud: point.longitude,
                );
                
                if (result['success']) {
                  await _loadPuntosIntercambio();
                  setState(() => _isCreatingPoint = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Punto creado')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ ${result['message']}')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF233C),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPuntoDialog(Map<String, dynamic> punto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.place, color: Color(0xFFEF233C)),
            const SizedBox(width: 12),
            Expanded(child: Text(punto['nombre'])),
          ],
        ),
        content: Text(punto['descripcion'] ?? 'Sin descripción'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (_canManagePoints())
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final result = await SupabaseService.deletePuntoIntercambio(punto['id']);
                if (result['success']) {
                  await _loadPuntosIntercambio();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Punto eliminado')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationUpdates();
    _locationsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LatLng? userLatLng;
    if (_currentUserPosition != null) {
      userLatLng = LatLng(_currentUserPosition!.latitude, _currentUserPosition!.longitude);
    }

    // Centrar mapa solo una vez
    if (!_hasCenteredMap && userLatLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasCenteredMap) {
          _mapController.move(userLatLng!, 16.0);
          _hasCenteredMap = true;
        }
      });
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    final otherUsers = _allUserLocations
        .where((loc) => loc['user_id'] != currentUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Interactivo'),
        backgroundColor: const Color(0xFFEF233C),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'users') _showUsers = !_showUsers;
                if (value == 'points') _showPoints = !_showPoints;
              });
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'users',
                checked: _showUsers,
                child: const Text('Mostrar usuarios'),
              ),
              CheckedPopupMenuItem(
                value: 'points',
                checked: _showPoints,
                child: const Text('Mostrar puntos'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userLatLng ?? _espochCenter,
                    initialZoom: 16.0,
                    onTap: (_, point) {
                      if (_isCreatingPoint) {
                        _showCreatePointDialog(point);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),
                
                // Controles
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      _buildControlButton(Icons.add, () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        );
                      }),
                      const SizedBox(height: 8),
                      _buildControlButton(Icons.remove, () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        );
                      }),
                      const SizedBox(height: 8),
                      _buildControlButton(Icons.my_location, () async {
                        if (userLatLng != null) {
                          _mapController.move(userLatLng, 16.0);
                        } else {
                          // Intentar obtener ubicación
                          try {
                            final position = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high,
                              timeLimit: const Duration(seconds: 5),
                            );
                            setState(() => _currentUserPosition = position);
                            final newLatLng = LatLng(position.latitude, position.longitude);
                            _mapController.move(newLatLng, 16.0);
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('📍 Ubicación actualizada')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ No se pudo obtener tu ubicación. Activa el GPS.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        }
                      }),
                    ],
                  ),
                ),

                // Leyenda
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Leyenda', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildLegendItem(Icons.school, 'ESPOCH', const Color(0xFFEF233C)),
                        if (_showUsers)
                          _buildLegendItem(Icons.location_on, 'Usuarios', Colors.green),
                        if (_showPoints)
                          _buildLegendItem(Icons.place, 'Puntos', const Color(0xFFEF233C)),
                        _buildLegendItem(Icons.my_location, 'Mi ubicación', Colors.blue),
                      ],
                    ),
                  ),
                ),


              ],
            ),
          ),
          
          // Lista de usuarios
          if (_showUsers)
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[100],
                child: otherUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay otros usuarios activos',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: otherUsers.length,
                        itemBuilder: (context, index) {
                          final userLocation = otherUsers[index];
                          final userId = userLocation['user_id'];
                          final userName = _userNames[userId] ?? 'Cargando...';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(userName),
                              subtitle: const Text('Tocar para ver en el mapa'),
                              trailing: IconButton(
                                icon: const Icon(Icons.chat, color: Color(0xFFEF233C)),
                                onPressed: () {
                                  if (userName != 'Cargando...') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          otherUserId: userId,
                                          otherUserName: userName,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                final lat = userLocation['lat'];
                                final lon = userLocation['lon'];
                                if (lat != null && lon != null) {
                                  _mapController.move(
                                    LatLng((lat as num).toDouble(), (lon as num).toDouble()),
                                    16.0,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
      floatingActionButton: _canManagePoints()
          ? FloatingActionButton(
              onPressed: () {
                setState(() => _isCreatingPoint = !_isCreatingPoint);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isCreatingPoint
                          ? '📍 Toca el mapa para crear un punto'
                          : 'Modo creación desactivado',
                    ),
                  ),
                );
              },
              backgroundColor: _isCreatingPoint ? Colors.blue : const Color(0xFFEF233C),
              child: Icon(_isCreatingPoint ? Icons.close : Icons.add_location_alt),
            )
          : null,
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: const Color(0xFFEF233C)),
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
