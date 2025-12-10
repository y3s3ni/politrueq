import 'package:flutter/material.dart';
import 'package:trueque/modelo/user.model.dart';
import '../services/supabase_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // --- CORRECCIÓN 1: Define un mapa para manejar los roles de forma consistente ---
  // Esto evita errores de tipeo y estandariza los valores.
  // La 'key' es el valor que se guarda en la base de datos (ej. 'admin').
  // El 'value' es el nombre amigable que se muestra al usuario (ej. 'Administrador').
  static const Map<String, String> _roleData = {
    'admin': 'Administrador',
    'moderador': 'Moderador',
    'usuario': 'Usuario',
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    print('🔄 _loadUsers() iniciado');
    setState(() => _isLoading = true);
    
    try {
      print('📡 Llamando a SupabaseService.getAllUsers()...');
      final result = await SupabaseService.getAllUsers();
      
      print('📦 Respuesta recibida: success=${result['success']}');
      
      if (result['success'] && mounted) {
        final List<dynamic> usersData = result['data'];
        print('📊 Datos recibidos: ${usersData.length} usuarios');
        
        // Mostrar los primeros 3 usuarios para debug
        for (int i = 0; i < (usersData.length > 3 ? 3 : usersData.length); i++) {
          print('   Usuario $i: ${usersData[i]['name']} - Rol: ${usersData[i]['role']}');
        }
        
        setState(() {
          _users = usersData.map((data) => UserModel.fromJson(data)).toList();
          _isLoading = false;
        });
        
        print('✅ Estado actualizado con ${_users.length} usuarios');
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          print('❌ Error al cargar usuarios: ${result['message']}');
          _showSnackBar(
            result['message'] ?? 'Error al cargar usuarios',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('💥 Excepción en _loadUsers: $e');
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      return user.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.correoElectronico.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --- CORRECCIÓN 2: Mejora la función de eliminación con validación y logs ---
  Future<void> _deleteUser(UserModel user) async {
    // Evita que un admin se elimine a sí mismo
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser != null && currentUser.id == user.id) {
      _showSnackBar('No puedes eliminar tu propio usuario', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFEF233C)),
            SizedBox(width: 12),
            Text(
              '¿Eliminar usuario?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar a ${user.nombreCompleto}?\n\nEsta acción eliminará todos sus datos.\n\n⚠️ Esta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF233C),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog('Eliminando usuario...');

    try {
      print('🗑️ UI: Intentando eliminar usuario');
      print('   ID: ${user.id}');
      print('   Nombre: ${user.nombreCompleto}');
      print('   Email: ${user.correoElectronico}');
      
      final result = await SupabaseService.deleteUser(user.id);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga

      print('📊 UI: Resultado recibido: ${result['success']}');
      
      if (result['success']) {
        print('✅ UI: Eliminación exitosa, recargando lista...');
        _showSnackBar('Usuario eliminado exitosamente');
        await _loadUsers();
        print('✅ UI: Lista recargada, total usuarios: ${_users.length}');
      } else {
        final errorMessage = result['message'] ?? result['error'] ?? 'Error desconocido al eliminar usuario';
        print('❌ UI: Error al eliminar: $errorMessage');
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print('💥 UI: Excepción al eliminar usuario: $e');
      _showSnackBar('Error del cliente: $e', isError: true);
    }
  }

  // --- CORRECCIÓN 4: Arregla la lógica para cambiar el rol ---
  Future<void> _editUser(UserModel user) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: user.nombreCompleto);
    final emailController = TextEditingController(text: user.correoElectronico);
    
    // Usa la función de normalización para obtener el rol canónico (ej. 'admin')
    String selectedRole = _normalizeRole(user.rol);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFFEF233C)),
            SizedBox(width: 12),
            Text(
              'Editar Usuario',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                _buildLabel('Nombre Completo'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: nombreController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa el nombre';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa el email';
                    if (!value.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Rol'),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: _roleData.entries.map((entry) {
                        // entry.key es 'admin', 'moderador', etc.
                        // entry.value es 'Administrador', 'Moderador', etc.
                        return _buildRadioTile(
                          title: entry.value, // Muestra el nombre amigable
                          value: entry.key,   // Usa el valor canónico
                          groupValue: selectedRole,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedRole = value);
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF233C),
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    _showLoadingDialog('Actualizando usuario...');

    try {
      print('🔄 Iniciando actualización de usuario ${user.id}');
      print('   📝 Nombre: ${nombreController.text}');
      print('   📧 Email: ${emailController.text}');
      print('   🎭 Rol seleccionado: $selectedRole');
      
      final updateResult = await SupabaseService.updateUser(
        userId: user.id,
        name: nombreController.text,
        email: emailController.text,
        rol: selectedRole,
      );
      
      if (!mounted) return;
      Navigator.pop(context);

      print('📊 Resultado de actualización: ${updateResult['success']}');

      if (updateResult['success']) {
        _showSnackBar('Usuario actualizado exitosamente');
        
        print('⏳ Esperando 500ms antes de recargar...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        print('🔄 Recargando lista de usuarios...');
        await _loadUsers();
        
        print('✅ Lista de usuarios recargada');
        print('📋 Total de usuarios en memoria: ${_users.length}');
        
        // Verificar si el usuario actualizado está en la lista
        final updatedUser = _users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => UserModel(
            id: '',
            nombreCompleto: '',
            correoElectronico: '',
            rol: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        if (updatedUser.id.isNotEmpty) {
          print('👤 Usuario actualizado encontrado en lista:');
          print('   Nombre: ${updatedUser.nombreCompleto}');
          print('   Rol: ${updatedUser.rol}');
        } else {
          print('⚠️ Usuario actualizado NO encontrado en lista');
        }
      } else {
        final errorMessage = updateResult['message'] ?? updateResult['error'] ?? 'Error desconocido al actualizar';
        print('❌ Error al actualizar usuario: $errorMessage');
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print('💥 Excepción al actualizar usuario: $e');
      _showSnackBar('Error del cliente: $e', isError: true);
    }
  }

  // --- CORRECCIÓN 5: Función para normalizar roles a valores canónicos ---
  // Convierte 'admin' o 'administrador' a 'admin'.
  String _normalizeRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrador':
        return 'admin';
      case 'moderador':
        return 'moderador';
      case 'usuario':
      default:
        return 'usuario';
    }
  }

  // --- CORRECCIÓN 6: Usa la normalización para obtener el color y el nombre ---
  Color _getRoleColor(String rol) {
    String normalizedRole = _normalizeRole(rol);
    switch (normalizedRole) {
      case 'admin':
        return const Color(0xFFEF233C);
      case 'moderador':
        return const Color(0xFFF59E0B);
      case 'usuario':
      default:
        return Colors.blue;
    }
  }

  String _getRoleDisplayName(String rol) {
    String normalizedRole = _normalizeRole(rol);
    return _roleData[normalizedRole] ?? 'Usuario';
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFEF233C)),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D3436), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFEF233C),
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : _buildUsersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Gestión de Usuarios',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron usuarios',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: const Color(0xFFEF233C),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(user),
            const SizedBox(width: 16),
            Expanded(child: _buildUserInfo(user)),
            _buildActions(user),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor(user.rol),
            _getRoleColor(user.rol).withOpacity(0.7),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.getInitials(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.nombreCompleto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.correoElectronico,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: _getRoleColor(user.rol),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getRoleDisplayName(user.rol), // Usa la función corregida
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(UserModel user) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _editUser(user),
          icon: const Icon(Icons.edit_outlined),
          color: const Color(0xFF2563EB),
          tooltip: 'Editar usuario',
        ),
        IconButton(
          onPressed: () => _deleteUser(user),
          icon: const Icon(Icons.delete_outline),
          color: const Color(0xFFEF233C),
          tooltip: 'Eliminar usuario',
        ),
      ],
    );
  }
}