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
  List<ProductoUnificado> _misObjetos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final misObjetosResult = await ProductosUnificadosService.getMisProductos();
    
    if (mounted) {
      setState(() {
        if (misObjetosResult['success']) {
          _misObjetos = misObjetosResult['data'] as List<ProductoUnificado>;
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
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: const Color(0xFFEF233C), borderRadius: BorderRadius.circular(12)),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFEF233C),
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Aprobados'),
                  Tab(text: 'En Revisión'),
                  Tab(text: 'Rechazados'),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFFEF233C)),
                            const SizedBox(height: 16),
                            Text('Cargando tus objetos...', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMisObjetosPorEstado('aprobado'),
                        _buildMisObjetosPorEstado('pendiente'),
                        _buildMisObjetosPorEstado('rechazado'),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddObjectDialog(),
        backgroundColor: const Color(0xFFEF233C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Agregar Objeto', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B0000), Color(0xFFEF233C)],
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
          Expanded(
            child: Text(
              'Mis Objetos de Intercambio',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisObjetosPorEstado(String estado) {
    final filteredList = _misObjetos.where((obj) => obj.estadoAprobacion == estado).toList();

    if (filteredList.isEmpty) {
      String message = 'No tienes objetos en esta categoría.';
      IconData icon = Icons.inbox;

      switch (estado) {
        case 'aprobado':
          message = 'No tienes objetos aprobados.';
          icon = Icons.check_circle_outline;
          break;
        case 'pendiente':
          message = 'No tienes objetos en revisión.';
          icon = Icons.hourglass_empty;
          break;
        case 'rechazado':
          message = 'No tienes objetos rechazados.';
          icon = Icons.cancel_outlined;
          break;
      }

      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final objeto = filteredList[index];
          return _buildObjetoCard(objeto);
        },
      ),
    );
  }

  Widget _buildObjetoCard(ProductoUnificado objeto) {
    final disponible = objeto.disponible;
    final estadoAprobacion = objeto.estadoAprobacion;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (objeto.imageUrls.isNotEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage(objeto.imageUrls.first),
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              child: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(objeto.nombre, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(objeto.estadoFisico).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getEstadoLabel(objeto.estadoFisico),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _getEstadoColor(objeto.estadoFisico)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(objeto.descripcion, style: GoogleFonts.poppins(color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getCategoriaIcon(objeto.categoria), size: 16, color: const Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(objeto.categoria, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                    _buildApprovalBadge(estadoAprobacion),
                    if (!disponible)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text('Intercambiado', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),

                if (estadoAprobacion == 'rechazado' && objeto.motivoRechazo != null && objeto.motivoRechazo!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(objeto.motivoRechazo!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[900])),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                _buildActionButtons(objeto, estadoAprobacion, disponible),
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
        color = Colors.grey;
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
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ProductoUnificado objeto, String estadoAprobacion, bool disponible) {
    if (estadoAprobacion == 'borrador') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(objeto),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  label: Text('Editar', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarEnviarRevision(objeto),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  label: Text('Enviar', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(objeto),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF233C)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.delete, color: Color(0xFFEF233C), size: 18),
              label: Text('Eliminar', style: GoogleFonts.poppins(color: const Color(0xFFEF233C))),
            ),
          ),
        ],
      );
    } else if (estadoAprobacion == 'pendiente') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmDelete(objeto),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF233C)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.cancel, color: Color(0xFFEF233C), size: 18),
          label: Text('Cancelar Revisión', style: GoogleFonts.poppins(color: const Color(0xFFEF233C))),
        ),
      );
    } else if (estadoAprobacion == 'aprobado') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: disponible ? () => _marcarNoDisponible(objeto) : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
          label: Text(disponible ? 'Marcar como Intercambiado' : 'Ya Intercambiado', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      );
    } else if (estadoAprobacion == 'rechazado') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEditDialog(objeto),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: Text('Editar y Reenviar', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(objeto),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF233C)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.delete, color: Color(0xFFEF233C), size: 18),
              label: Text('Eliminar', style: GoogleFonts.poppins(color: const Color(0xFFEF233C))),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showAddObjectDialog() {
    // ... (El código de este diálogo se mantiene igual)
  }

  void _showEditDialog(ProductoUnificado objeto) {
    // ... (El código de este diálogo se mantiene igual)
  }

  void _confirmarEnviarRevision(ProductoUnificado objeto) {
    // ... (El código de este diálogo se mantiene igual)
  }

  void _confirmDelete(ProductoUnificado objeto) {
    // ... (El código de este diálogo se mantiene igual)
  }

  void _marcarNoDisponible(ProductoUnificado objeto) async {
    // ... (El código de esta función se mantiene igual)
  }
}
