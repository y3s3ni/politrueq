import 'dart:io';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:trueque/modelo/user.model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/productos_unificados_service.dart';
import '../modelo/producto_unificado_model.dart';

class ObjectsScreen extends StatefulWidget {
  final UserModel currentUser;
  const ObjectsScreen({super.key, required this.currentUser});

  @override
  State<ObjectsScreen> createState() => _ObjectsScreenState();
}

class _ObjectsScreenState extends State<ObjectsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _objetosDisponibles = [];
  List<Map<String, dynamic>> _misObjetos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final disponibles = await ProductosUnificadosService.getProductosDisponibles();
    final misObjetos = await ProductosUnificadosService.getMisProductos();
    
    if (mounted) {
      setState(() {
        if (disponibles['success']) {
          _objetosDisponibles = List<Map<String, dynamic>>.from(
            (disponibles['data'] as List).map((p) => (p as ProductoUnificado).toJson())
          );
        }
        if (misObjetos['success']) {
          _misObjetos = List<Map<String, dynamic>>.from(
            (misObjetos['data'] as List).map((p) => (p as ProductoUnificado).toJson())
          );
        }
        _isLoading = false;
      });
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'nuevo': return 'Nuevo';
      case 'como_nuevo': return 'Como nuevo';
      case 'buen_estado': return 'Buen estado';
      case 'usado': return 'Usado';
      case 'para_reparar': return 'Para reparar';
      default: return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'nuevo': return Colors.green;
      case 'como_nuevo': return Colors.lightGreen;
      case 'buen_estado': return Colors.blue;
      case 'usado': return Colors.orange;
      case 'para_reparar': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'Electrónicos': return Icons.phone_android;
      case 'Comida': return Icons.restaurant;
      case 'Ropa': return Icons.checkroom;
      case 'Libros': return Icons.menu_book;
      case 'Útiles Escolares': return Icons.school;
      case 'Deportes': return Icons.sports_soccer;
      case 'Hogar': return Icons.home;
      case 'Otros': return Icons.toys;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          // image: DecorationImage(
          //   image: AssetImage('assets/fondo.jpg'),
          //   fit: BoxFit.cover,
          // ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header Corregido
                _buildHeader(),
                
                // TabBar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFEF233C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFEF233C),
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Disponibles'),
                      Tab(text: 'Mis Objetos'),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: Color(0xFFEF233C)),
                                const SizedBox(height: 16),
                                Text(
                                  'Cargando objetos...',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildObjetosDisponibles(),
                            _buildMisObjetos(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddObjectDialog(),
        backgroundColor: const Color(0xFFEF233C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Agregar Objeto',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.arrow_back, color: Color(0xFFEF233C)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // CORRECCIÓN AQUÍ: Expanded para asegurar que el contenedor ocupe el resto del ancho
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Color(0xFFEF233C), size: 20),
                    const SizedBox(width: 8),
                    // CORRECCIÓN AQUÍ: Expanded alrededor del Text para evitar overflow
                    Expanded(
                      child: Text(
                        'Mis Objetos de Intercambio',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFFEF233C),
                        ),
                        overflow: TextOverflow.ellipsis, // Puntos suspensivos si es muy largo
                        maxLines: 1, // Fuerza una sola línea
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjetosDisponibles() {
    if (_objetosDisponibles.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No hay objetos disponibles',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _objetosDisponibles.length,
        itemBuilder: (context, index) {
          final objeto = _objetosDisponibles[index];
          final esPropio = objeto['usuario_id'] == SupabaseService.client.auth.currentUser?.id;
          
          return _buildObjetoCard(objeto, esPropio, false);
        },
      ),
    );
  }

  Widget _buildMisObjetos() {
    if (_misObjetos.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_box, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No tienes objetos registrados',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega tu primer objeto',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _misObjetos.length,
        itemBuilder: (context, index) {
          final objeto = _misObjetos[index];
          return _buildObjetoCard(objeto, true, true);
        },
      ),
    );
  }

  Widget _buildObjetoCard(Map<String, dynamic> objeto, bool esPropio, bool mostrarAcciones) {
    final disponible = objeto['disponible'] ?? true;
    final estadoAprobacion = objeto['estado_aprobacion'] ?? 'borrador';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Builder(
            builder: (context) {
              final imageUrls = objeto['image_urls'];
              final hasImage = imageUrls != null && 
                               imageUrls is List && 
                               imageUrls.isNotEmpty;
              
              if (hasImage) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrls.first,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              } else {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                );
              }
            },
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y estado físico
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        objeto['nombre'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(objeto['estado_fisico'] ?? 'buen_estado').withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getEstadoLabel(objeto['estado_fisico'] ?? 'buen_estado'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getEstadoColor(objeto['estado_fisico'] ?? 'buen_estado'),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Descripción
                Text(
                  objeto['descripcion'],
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Badge de categoría
                if (objeto['categoria'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoriaIcon(objeto['categoria']),
                          size: 16,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          objeto['categoria'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Badges de estado
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Badge de estado de aprobación (solo para objetos propios)
                    if (mostrarAcciones)
                      _buildApprovalBadge(estadoAprobacion),
                    
                    // Badge de disponibilidad
                    if (!disponible)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Intercambiado',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Motivo de rechazo (si aplica)
                if (estadoAprobacion == 'rechazado' && objeto['motivo_rechazo'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            objeto['motivo_rechazo'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Acciones (solo para objetos propios)
                if (mostrarAcciones) ...[
                  const SizedBox(height: 12),
                  _buildActionButtons(objeto, estadoAprobacion, disponible),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalBadge(String estadoAprobacion) {
    Color color;
    IconData icon;
    String label;

    switch (estadoAprobacion) {
      case 'borrador':
        color = Colors.amber;
        icon = Icons.edit_note;
        label = 'Borrador';
        break;
      case 'pendiente':
        color = Colors.blue;
        icon = Icons.schedule;
        label = 'En Revisión';
        break;
      case 'aprobado':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Aprobado';
        break;
      case 'rechazado':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Rechazado';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> objeto, String estadoAprobacion, bool disponible) {
    if (estadoAprobacion == 'borrador') {
      // Borrador: Editar, Enviar a Revisión, Eliminar
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(objeto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  label: Text(
                    'Editar',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarEnviarRevision(objeto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  label: Text(
                    'Enviar',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(objeto),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF233C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete, color: Color(0xFFEF233C), size: 18),
              label: Text(
                'Eliminar',
                style: GoogleFonts.poppins(color: const Color(0xFFEF233C)),
              ),
            ),
          ),
        ],
      );
    } else if (estadoAprobacion == 'pendiente') {
      // Pendiente: Solo Cancelar (Eliminar)
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmDelete(objeto),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFEF233C)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.cancel, color: Color(0xFFEF233C), size: 18),
          label: Text(
            'Cancelar Revisión',
            style: GoogleFonts.poppins(color: const Color(0xFFEF233C)),
          ),
        ),
      );
    } else if (estadoAprobacion == 'aprobado') {
      // Aprobado: Solo Marcar Intercambiado (sin Editar ni Eliminar)
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: disponible ? () => _marcarNoDisponible(objeto) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
          label: Text(
            disponible ? 'Marcar como Intercambiado' : 'Ya Intercambiado',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
    } else if (estadoAprobacion == 'rechazado') {
      // Rechazado: Editar y Reenviar, Eliminar
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEditDialog(objeto),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: Text(
                'Editar y Reenviar',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(objeto),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF233C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete, color: Color(0xFFEF233C), size: 18),
              label: Text(
                'Eliminar',
                style: GoogleFonts.poppins(color: const Color(0xFFEF233C)),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showAddObjectDialog() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    String categoria = 'Electrónicos';
    String estado = 'buen_estado';
    XFile? selectedImage;
    final formKey = GlobalKey<FormState>();
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF233C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_box, color: Color(0xFFEF233C)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nuevo Objeto',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de imagen
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      
                      if (image != null) {
                        setDialogState(() {
                          selectedImage = image;
                        });
                      }
                    },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FutureBuilder<Uint8List>(
                                future: selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                  }
                                  return const Center(child: CircularProgressIndicator());
                                },
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para agregar foto',
                                  style: GoogleFonts.poppins(color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre
                  Text('Nombre', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Libro de programación',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  Text('Descripción', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descripcionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe tu objeto...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa una descripción' : null,
                  ),
                  const SizedBox(height: 16),

                  // Categoría
                  Text('Categoría', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: categoria,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Electrónicos', child: Text('Electrónicos')),
                      DropdownMenuItem(value: 'Comida', child: Text('Comida')),
                      DropdownMenuItem(value: 'Ropa', child: Text('Ropa')),
                      DropdownMenuItem(value: 'Útiles Escolares', child: Text('Útiles Escolares')),
                      DropdownMenuItem(value: 'Deportes', child: Text('Deportes')),
                      DropdownMenuItem(value: 'Hogar', child: Text('Hogar')),
                      DropdownMenuItem(value: 'Otros', child: Text('Otros')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => categoria = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Estado
                  Text('Estado', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: estado,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'nuevo', child: Text('Nuevo')),
                      DropdownMenuItem(value: 'como_nuevo', child: Text('Como nuevo')),
                      DropdownMenuItem(value: 'buen_estado', child: Text('Buen estado')),
                      DropdownMenuItem(value: 'usado', child: Text('Usado')),
                      DropdownMenuItem(value: 'para_reparar', child: Text('Para reparar')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => estado = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isUploading = true);

                        String? imageUrl;

                        // Subir imagen si existe
                        if (selectedImage != null) {
                          try {
                            final imageBytes = await selectedImage!.readAsBytes();
                            final imageExtension = selectedImage!.name.split('.').last.toLowerCase();
                            final userId = SupabaseService.client.auth.currentUser?.id;
                            final imageFileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';

                            await SupabaseService.client.storage
                                .from('productos_unificados')
                                .uploadBinary(
                                  imageFileName,
                                  imageBytes,
                                  fileOptions: FileOptions(cacheControl: '3600', upsert: false),
                                );

                            imageUrl = SupabaseService.client.storage
                                .from('productos_unificados')
                                .getPublicUrl(imageFileName);
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error al subir imagen: $e', style: GoogleFonts.poppins()),
                                  backgroundColor: const Color(0xFFEF233C),
                                ),
                              );
                            }
                            setDialogState(() => isUploading = false);
                            return;
                          }
                        }

                        // Mapear estado a puntos
                        int puntos;
                        switch (estado) {
                          case 'para_reparar':
                            puntos = 2;
                            break;
                          case 'usado':
                            puntos = 4;
                            break;
                          case 'buen_estado':
                            puntos = 6;
                            break;
                          case 'como_nuevo':
                            puntos = 8;
                            break;
                          case 'nuevo':
                            puntos = 10;
                            break;
                          default:
                            puntos = 6;
                        }

                        // Crear producto
                        final result = await ProductosUnificadosService.createProducto(
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          categoria: categoria,
                          estadoFisico: estado,
                          puntosNecesarios: puntos,
                          imageUrls: imageUrl != null ? [imageUrl] : [],
                        );

                        if (dialogContext.mounted) Navigator.pop(dialogContext);

                        if (result['success']) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Objeto creado', style: GoogleFonts.poppins()),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadData();
                        } else {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('❌ ${result['message']}', style: GoogleFonts.poppins()),
                              backgroundColor: const Color(0xFFEF233C),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF233C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Guardar',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> objeto) {
    final nombreController = TextEditingController(text: objeto['nombre']);
    final descripcionController = TextEditingController(text: objeto['descripcion']);
    String categoria = objeto['categoria'] ?? 'Electrónicos';
    String estado = objeto['estado_fisico'] ?? 'buen_estado'; // Corregido: estado_fisico
    XFile? selectedImage;
    String? currentImageUrl = objeto['image_urls'] != null && (objeto['image_urls'] as List).isNotEmpty
        ? (objeto['image_urls'] as List).first
        : null; // Corregido: image_urls
    final formKey = GlobalKey<FormState>();
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Editar Objeto', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setDialogState(() {
                          selectedImage = image;
                          currentImageUrl = null;
                        });
                      }
                    },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FutureBuilder<Uint8List>(
                                future: selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                  }
                                  return const Center(child: CircularProgressIndicator());
                                },
                              ),
                            )
                          : currentImageUrl != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(currentImageUrl!, fit: BoxFit.cover))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text('Toca para cambiar foto', style: GoogleFonts.poppins(color: Colors.grey)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Nombre', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    style: GoogleFonts.poppins(),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Descripción', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descripcionController,
                    maxLines: 3,
                    decoration: InputDecoration(filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    style: GoogleFonts.poppins(),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa una descripción' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Categoría', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: categoria,
                    decoration: InputDecoration(filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    items: const [
                      DropdownMenuItem(value: 'Electrónicos', child: Text('Electrónicos')),
                      DropdownMenuItem(value: 'Comida', child: Text('Comida')),
                      DropdownMenuItem(value: 'Ropa', child: Text('Ropa')),
                      DropdownMenuItem(value: 'Útiles Escolares', child: Text('Útiles Escolares')),
                      DropdownMenuItem(value: 'Deportes', child: Text('Deportes')),
                      DropdownMenuItem(value: 'Hogar', child: Text('Hogar')),
                      DropdownMenuItem(value: 'Otros', child: Text('Otros')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => categoria = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Estado', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: estado,
                    decoration: InputDecoration(filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    items: const [
                      DropdownMenuItem(value: 'nuevo', child: Text('Nuevo')),
                      DropdownMenuItem(value: 'como_nuevo', child: Text('Como nuevo')),
                      DropdownMenuItem(value: 'buen_estado', child: Text('Buen estado')),
                      DropdownMenuItem(value: 'usado', child: Text('Usado')),
                      DropdownMenuItem(value: 'para_reparar', child: Text('Para reparar')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => estado = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isUploading ? null : () => Navigator.pop(dialogContext), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey))),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isUploading = true);
                  String? imageUrl = currentImageUrl;
                  if (selectedImage != null) {
                    try {
                      final imageBytes = await selectedImage!.readAsBytes();
                      final imageExtension = selectedImage!.name.split('.').last.toLowerCase();
                      final userId = SupabaseService.client.auth.currentUser?.id;
                      final imageFileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';

                      await SupabaseService.client.storage
                          .from('productos_unificados')
                          .uploadBinary(
                            imageFileName,
                            imageBytes,
                            fileOptions: FileOptions(cacheControl: '3600', upsert: false),
                          );

                      imageUrl = SupabaseService.client.storage
                          .from('productos_unificados')
                          .getPublicUrl(imageFileName);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error al subir imagen: $e', style: GoogleFonts.poppins()), backgroundColor: const Color(0xFFEF233C)));
                      setDialogState(() => isUploading = false);
                      return;
                    }
                  }
                  final result = await SupabaseService.updateObjeto(objetoId: objeto['id'], nombre: nombreController.text.trim(), descripcion: descripcionController.text.trim(), categoria: categoria, estado: estado, imagenUrl: imageUrl);
                  
                  // Si el objeto estaba rechazado, enviarlo automáticamente a revisión
                  if (result['success'] && objeto['estado_aprobacion'] == 'rechazado') {
                    await SupabaseService.enviarARevision(objeto['id']);
                  }
                  
                  if (mounted) Navigator.pop(context);
                  if (mounted) {
                    String mensaje = result['success'] 
                        ? (objeto['estado_aprobacion'] == 'rechazado' 
                            ? '✅ Objeto actualizado y reenviado a revisión' 
                            : '✅ Objeto actualizado')
                        : '❌ ${result['message']}';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje, style: GoogleFonts.poppins()), backgroundColor: result['success'] ? Colors.green : const Color(0xFFEF233C)));
                    if (result['success']) _loadData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Guardar Cambios', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEnviarRevision(Map<String, dynamic> objeto) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [const Icon(Icons.send, color: Colors.green), const SizedBox(width: 12), Text('¿Enviar a Revisión?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))]),
        content: Text('Tu objeto "${objeto['nombre']}" será revisado por un administrador antes de ser visible para todos.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await SupabaseService.enviarARevision(objeto['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['success'] ? '✅ Enviado a revisión' : '❌ ${result['message']}', style: GoogleFonts.poppins()), backgroundColor: result['success'] ? Colors.green : const Color(0xFFEF233C)));
                if (result['success']) _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Enviar', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> objeto) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [const Icon(Icons.warning, color: Colors.orange), const SizedBox(width: 12), Text('¿Eliminar objeto?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))]),
        content: Text('¿Estás seguro de eliminar "${objeto['nombre']}"? Esta acción no se puede deshacer.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await SupabaseService.deleteObjeto(objeto['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['success'] ? '✅ Objeto eliminado' : '❌ ${result['message']}', style: GoogleFonts.poppins()), backgroundColor: result['success'] ? Colors.green : const Color(0xFFEF233C)));
                if (result['success']) _loadData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF233C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Eliminar', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _marcarNoDisponible(Map<String, dynamic> objeto) async {
    final result = await SupabaseService.marcarObjetoNoDisponible(objeto['id']);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['success'] ? '✅ Marcado como intercambiado' : '❌ ${result['message']}', style: GoogleFonts.poppins()), backgroundColor: result['success'] ? Colors.green : const Color(0xFFEF233C)));
      if (result['success']) _loadData();
    }
  }
}