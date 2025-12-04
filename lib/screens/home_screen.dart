import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/modelo/user.model.dart'; 
import 'package:trueque/screens/chat_list_screen.dart';
import 'package:trueque/screens/search_user_screen.dart';
import 'login_screen.dart';
import 'user_management_screen.dart';
import 'map_screen.dart';
import 'objects_screen.dart';
import 'approval_screen.dart';
import 'items_list_screen.dart'; 

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int count;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.count = 0,
  });
}

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  late UserModel _currentUser;
  late String _originalRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _originalRole = widget.user.rol;
    _refreshUserData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshUserData() async {
    try {
      final userData = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('id', _currentUser.id)
          .single();
      
      if (mounted) {
        setState(() {
          _currentUser = UserModel.fromJson(userData);
        });
        print('✅ Datos del usuario actualizados - Rol: ${_currentUser.rol}');
      }
    } catch (e) {
      print('❌ Error al refrescar datos del usuario: $e');
    }
  }

  final List<Category> _categories = const [
    Category(id: 'electronics', name: 'Comida', icon: Icons.phone_android, color: Color(0xFF2563EB), count: 234),
    Category(id: 'clothing', name: 'Ropa', icon: Icons.checkroom, color: Color(0xFF9333EA), count: 189),
    Category(id: 'books', name: 'Útiles Escolares', icon: Icons.menu_book, color: Color(0xFF16A34A), count: 156),
    Category(id: 'sports', name: 'Deportes', icon: Icons.sports_soccer, color: Color(0xFFEA580C), count: 98),
    Category(id: 'home', name: 'Hogar', icon: Icons.home, color: Color(0xFFDC2626), count: 145),
    Category(id: 'toys', name: 'Otros', icon: Icons.toys, color: Color(0xFFDB2777), count: 67),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Poli-Trueque', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFEF233C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // 🔍 AÑADIDO: Buscar usuario para chatear
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Buscar usuarios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchUserScreen()),
              );
            },
          ),
          
          // 💬 AÑADIDO: Ver lista de chats
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            tooltip: 'Mis chats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          
          // 🔔 Notificaciones (ya existía)
          IconButton(
            icon: Stack(
              children: const [
                Icon(Icons.notifications, color: Colors.white),
                Positioned(right: 0, top: 0, child: Icon(Icons.circle, color: Colors.red, size: 8)),
              ],
            ),
            tooltip: 'Notificaciones',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No tienes notificaciones nuevas'), backgroundColor: Color(0xFFEF233C)),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEF233C), 
              const Color(0xFFEF233C).withOpacity(0.8), 
              Colors.white
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡Hola, ${_currentUser.nombreCompleto}!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('¿Qué quieres intercambiar hoy?', style: TextStyle(fontSize: 18, color: Colors.white70)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Categorías', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEF233C))),
                          const SizedBox(height: 16),
                          Expanded(child: _buildCategoriesGrid()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _CategoryCard(category: category);
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24))),
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
            width: 64, height: 64,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEF233C), Color(0xFFD91F38)]), shape: BoxShape.circle),
            child: Center(child: Text(_currentUser.getInitials(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getGreeting(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(_currentUser.nombreCompleto, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: _getRoleColor(_currentUser.rol), borderRadius: BorderRadius.circular(20)),
                  child: Text(_getRoleDisplayName(_currentUser.rol), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
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
        _buildMenuItem(Icons.home, 'Inicio', () {}),
        _buildMenuItem(Icons.search, 'Buscar', () {}),
        _buildMenuItem(Icons.swap_horiz, 'Mis Objetos', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => ObjectsScreen(currentUser: _currentUser)));
        }),
        // AÑADIDO: Opción de mensajes en el menú lateral
        _buildMenuItem(Icons.chat_bubble, 'Mensajes', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
        }),
        _buildMenuItem(Icons.person, 'Perfil', () {}),
        _buildMenuItem(Icons.map, 'Mapa', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(currentUser: _currentUser)));
        }),
        if (_canChangeRole()) ...[
          _buildMenuSectionTitle('ADMINISTRACIÓN'),
          if (_originalRole.toLowerCase() == 'admin' || _originalRole.toLowerCase() == 'administrador')
            _buildMenuItem(Icons.people, 'Gestión de Usuarios', _navigateToUserManagement),
          _buildMenuItem(Icons.fact_check, 'Revisar Objetos', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => ApprovalScreen(currentUser: _currentUser)));
          }),
          _buildMenuItem(Icons.admin_panel_settings, 'Cambiar Rol', _showRoleChangeDialog),
        ],
        _buildMenuSectionTitle('CONFIGURACIÓN'),
        _buildSettingItem(Icons.dark_mode, 'Modo Oscuro', _isDarkMode, (value) => setState(() => _isDarkMode = value)),
        _buildSettingItem(Icons.notifications, 'Notificaciones', _notificationsEnabled, (value) => setState(() => _notificationsEnabled = value)),
      ],
    );
  }

  Widget _buildMenuSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 1)),
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
              Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey))),
          Switch(value: value, onChanged: onChanged, activeTrackColor: const Color(0xFFEF233C)),
        ],
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
        label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.w500)),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF233C)),
      ),
    );
  }

  bool _canChangeRole() {
    final originalRoleLower = _originalRole.toLowerCase();
    return originalRoleLower == 'admin' || originalRoleLower == 'administrador' || originalRoleLower == 'moderador';
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
          title: const Row(children: [Icon(Icons.admin_panel_settings, color: Color(0xFFEF233C)), SizedBox(width: 12), Text('Cambiar Rol')]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Rol actual: ${_currentUser.getRoleDisplayName()}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Selecciona tu nuevo rol:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...availableRoles.map((role) {
              final isCurrentRole = role.toLowerCase() == _currentUser.rol.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isCurrentRole ? null : () { Navigator.pop(context); _changeRole(role); },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrentRole ? _getRoleColor(role).withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isCurrentRole ? _getRoleColor(role) : Colors.grey[300]!, width: isCurrentRole ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getRoleDisplayName(role), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isCurrentRole ? _getRoleColor(role) : Colors.grey[800])),
                                Text(_getRoleDescription(role), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          if (isCurrentRole)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _getRoleColor(role), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Actual', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))],
        );
      },
    );
  }

  void _navigateToUserManagement() {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()));
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
            Expanded(child: Text('Vista cambiada a: ${_getRoleDisplayName(newRole)} (temporal)')),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) return '¡Buenos días!';
    if (hour >= 12 && hour < 19) return '¡Buenas tardes!';
    return '¡Buenas noches!';
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemsListScreen(category: category),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: category.color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: category.color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(category.icon, size: 30, color: category.color),
              ),
              const SizedBox(height: 16),
              Text(category.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}