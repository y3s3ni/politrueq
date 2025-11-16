import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/screens/login_screen.dart';

class RoleMiddleware {
  // Método estático para proteger una ruta
  static Widget protectedRoute({
    required Widget child,
    required String requiredRole,
  }) {
    return FutureBuilder<String?>(
      // Futuro que obtiene el rol del usuario actual
      future: _getUserRole(),
      builder: (context, snapshot) {
        // 1. Mientras carga el rol
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Si hay un error (no hay sesión, etc.)
        if (snapshot.hasError || !snapshot.hasData) {
          // Redirige al login si no se puede verificar el rol
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          });
          return const Scaffold(body: Center(child: Text('Verificando autenticación...')));
        }

        final userRole = snapshot.data!;

        // 3. Si el rol del usuario coincide con el requerido
        if (userRole == requiredRole) {
          return child; // Permite el acceso a la página
        }

        // 4. Si el rol no coincide (Acceso Denegado)
        return Scaffold(
          appBar: AppBar(title: const Text('Acceso Denegado')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No tienes permisos para ver esta página.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false),
                  child: const Text('Volver al Inicio de Sesión'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Función privada para obtener el rol desde la tabla 'profiles'
  static Future<String?> _getUserRole() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    // Obtenemos el rol del usuario desde su perfil
    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single(); // .single() para obtener un solo resultado

    return response['role'] as String?;
  }
}