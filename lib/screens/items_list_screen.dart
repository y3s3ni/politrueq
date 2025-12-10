import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/home_screen.dart';
import '../screens/objects_screen.dart';
import '../screens/approval_screen.dart';
import '../screens/mapa_unificado_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/test_productos_unificados_screen.dart';
import '../screens/login_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/mis_puntos_screen.dart';
import '../widgets/puntos_widget.dart';
import '../services/productos_unificados_service.dart';
import '../modelo/producto_unificado_model.dart';
import '../modelo/user.model.dart';

class ItemsListScreen extends StatefulWidget {
  final Category category;
  final UserModel currentUser;

  const ItemsListScreen({
    super.key,
    required this.category,
    required this.currentUser,
  });

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  List<ProductoUnificado> _productos = [];
  bool _isLoading = true;
  late UserModel _currentUser;
  late String _originalRole;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _originalRole = widget.currentUser.rol;
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoading = true);
    
    print('🔍 Cargando productos de categoría: ${widget.category.id}');
    
    final result = await ProductosUnificadosService.getProductosPorCategoria(widget.category.id);
    
    print('🔍 Resultado: ${result['success']}');
    print('🔍 Productos encontrados: ${result['data']?.length ?? 0}');
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          _productos = result['data'] as List<ProductoUnificado>;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          title: Text(
            widget.category.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: widget.category.color,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: PuntosWidget(
                  userId: _currentUser.id,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MisPuntosScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.category.color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _productos.isEmpty
                ? _buildEmptyState()
                : _buildProductList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.category.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.category.icon,
              size: 80,
              color: widget.category.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay productos en ${widget.category.name}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aún no hay productos aprobados en esta categoría',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadProductos,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.62, // Balance entre imagen visible y poco espacio blanco
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final producto = _productos[index];
                  return _buildProductCard(producto);
                },
                childCount: _productos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductoUnificado producto) {
    final primeraImagen = producto.imageUrls.isNotEmpty ? producto.imageUrls.first : null;
    
    return InkWell(
      onTap: () {
        // Aquí puedes agregar navegación a detalle del producto
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen con altura fija
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: primeraImagen != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            primeraImagen,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                ),
                // Badge de estado
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(producto.estadoFisico),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      producto.getEstadoFisicoLabel(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Información del producto
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Categoría
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF233C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      producto.categoria,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF233C),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Nombre
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Descripción
                  Text(
                    producto.descripcion,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Puntos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, size: 13, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          producto.getPuntosLabel(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'nuevo':
        return Colors.green;
      case 'como_nuevo':
        return const Color(0xFFD90429);
      case 'buen_estado':
        return const Color(0xFFEF233C);
      case 'usado':
        return const Color(0xFFDC2626);
      case 'para_reparar':
        return const Color(0xFF991B1B);
      default:
        return Colors.grey;
    }
  }

  // ==================== DRAWER ====================

  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildUserHeader(),
            const Divider(height: 1),
            Expanded(child: _buildMenuItems()),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF233C), Color(0xFFD91F38)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.currentUser.getInitials(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentUser.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(widget.currentUser.rol),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRoleDisplayName(widget.currentUser.rol),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildMenuSectionTitle('MENÚ PRINCIPAL'),
        _buildMenuItem(Icons.home, 'Inicio', () {
          Navigator.pop(context); // Cerrar drawer
          Navigator.pop(context); // Volver al home
        }),
        _buildMenuItem(Icons.search, 'Buscar', () {
          Navigator.pop(context);
          // TODO: Implementar búsqueda
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función de búsqueda próximamente')),
          );
        }),
        _buildMenuItem(Icons.swap_horiz, 'Mis Objetos', () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ObjectsScreen(currentUser: widget.currentUser),
            ),
          );
        }),
        _buildMenuItem(Icons.stars, 'Mis Puntos', () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MisPuntosScreen(),
            ),
          );
        }),
        _buildMenuItem(Icons.chat_bubble, 'Mensajes', () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          );
        }),
        _buildMenuItem(Icons.person, 'Perfil', () {
          Navigator.pop(context);
          // TODO: Implementar perfil
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función de perfil próximamente')),
          );
        }),
        _buildMenuItem(Icons.map, 'Mapa Interactivo', () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapaUnificadoScreen(currentUser: _currentUser),
            ),
          );
        }),
        if (_canAccessAdmin()) ...[
          _buildMenuSectionTitle('ADMINISTRACIÓN'),
          if (_isAdmin())
            _buildMenuItem(Icons.people, 'Gestión de Usuarios', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
            }),
          _buildMenuItem(Icons.fact_check, 'Revisar Objetos', () async {
            Navigator.pop(context);
            // Navegar y esperar el resultado
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApprovalScreen(currentUser: widget.currentUser),
              ),
            );
            // Recargar productos cuando vuelve de la pantalla de aprobación
            _loadProductos();
          }),
          _buildMenuItem(Icons.admin_panel_settings, 'Cambiar Rol', () {
            Navigator.pop(context);
            _showRoleChangeDialog();
          }),
        ],
        _buildMenuSectionTitle('PRUEBAS'),
        _buildMenuItem(Icons.science, 'Test Sistema Unificado', () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TestProductosUnificadosScreen()),
          );
        }),
      ],
    );
  }

  Widget _buildMenuSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextButton.icon(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFEF233C),
        ),
      ),
    );
  }

  bool _canAccessAdmin() {
    final roleLower = _currentUser.rol.toLowerCase();
    return roleLower == 'admin' || 
           roleLower == 'administrador' || 
           roleLower == 'moderador';
  }

  bool _isAdmin() {
    final roleLower = _currentUser.rol.toLowerCase();
    return roleLower == 'admin' || roleLower == 'administrador';
  }

  // Funciones para cambio de rol temporal
  void _showRoleChangeDialog() {
    List<String> availableRoles = [];
    final originalRoleLower = _originalRole.toLowerCase();
    if (originalRoleLower == 'admin' || originalRoleLower == 'administrador') {
      availableRoles = ['Administrador', 'Moderador', 'Usuario'];
    } else if (originalRoleLower == 'moderador') {
      availableRoles = ['Moderador', 'Usuario'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFFEF233C)),
              SizedBox(width: 12),
              Text('Cambiar Rol'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rol actual: ${_currentUser.getRoleDisplayName()}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona tu nuevo rol:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...availableRoles.map((role) {
                final isCurrentRole = role.toLowerCase() == _currentUser.rol.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isCurrentRole ? null : () {
                        Navigator.pop(context);
                        _changeRole(role);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCurrentRole ? _getRoleColor(role).withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentRole ? _getRoleColor(role) : Colors.grey[300]!,
                            width: isCurrentRole ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getRoleDisplayName(role),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isCurrentRole ? _getRoleColor(role) : Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    _getRoleDescription(role),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentRole)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(role),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Actual',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _changeRole(String newRole) {
    setState(() {
      _currentUser = UserModel(
        id: _currentUser.id,
        nombreCompleto: _currentUser.nombreCompleto,
        correoElectronico: _currentUser.correoElectronico,
        rol: newRole,
        createdAt: _currentUser.createdAt,
        updatedAt: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Vista cambiada a: ${_getRoleDisplayName(newRole)} (temporal)'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF233C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getRoleColor(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
      case 'administrador':
        return const Color(0xFFEF233C);
      case 'moderador':
        return const Color(0xFFF59E0B);
      default:
        return Colors.blue;
    }
  }

  String _getRoleDisplayName(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
      case 'administrador':
        return 'Administrador';
      case 'moderador':
        return 'Moderador';
      default:
        return 'Usuario';
    }
  }

  IconData _getRoleIcon(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
      case 'administrador':
        return Icons.admin_panel_settings;
      case 'moderador':
        return Icons.shield;
      default:
        return Icons.person;
    }
  }

  String _getRoleDescription(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
      case 'administrador':
        return 'Control total del sistema';
      case 'moderador':
        return 'Gestión de usuarios y contenido';
      default:
        return 'Acceso estándar';
    }
  }
}