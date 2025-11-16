import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/theme/app_theme.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validar que el correo electrónico esté registrado en el sistema
  Future<bool> _validateEmail(String email) async {
    try {
      // Verificar si el correo electrónico tiene un formato válido
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return false;
      }

      // Obtener el usuario actual
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      // Si hay un usuario autenticado, verificar que el correo coincida
      if (currentUser != null && currentUser.email != null) {
        return currentUser.email!.toLowerCase() == email.toLowerCase();
      }
      
      // Si no hay usuario autenticado, intentamos verificar si el correo existe
      // Nota: Supabase no tiene un método directo para verificar si un email existe
      // sin autenticación, así que usamos un enfoque alternativo
      
      return true; // Asumimos que el email es válido si tiene el formato correcto
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validando email: $e');
      }
      return false;
    }
  }

  /// Cambiar la contraseña del usuario
  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('🔐 Iniciando cambio de contraseña...');
      }

      // 1. Verificar el correo electrónico
      final isEmailValid = await _validateEmail(_emailController.text);

      if (!isEmailValid) {
        _mostrarError('El correo electrónico no es válido o no está registrado.');
        setState(() => _isLoading = false);
        return;
      }

      if (kDebugMode) {
        print('✅ Correo electrónico verificado');
      }

      // 2. Actualizar a la nueva contraseña
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );

      if (response.user != null) {
        if (kDebugMode) {
          print('✅ Contraseña actualizada exitosamente');
        }
        _mostrarExito();
      } else {
        _mostrarError('No se pudo actualizar la contraseña.');
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ AuthException: ${e.message}');
      }

      String errorMessage;
      if (e.message.toLowerCase().contains('same password')) {
        errorMessage = 'La nueva contraseña debe ser diferente a la actual.';
      } else if (e.message.toLowerCase().contains('weak password')) {
        errorMessage = 'La contraseña es muy débil. Use una más segura.';
      } else if (e.statusCode == '429') {
        errorMessage = 'Demasiados intentos. Espere un momento.';
      } else {
        errorMessage = 'Error al cambiar contraseña: ${e.message}';
      }

      _mostrarError(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inesperado: $e');
      }
      _mostrarError(
        'Ocurrió un error inesperado.\nVerifique su conexión e intente nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 28),
            const SizedBox(width: 10),
            const Text('Error'),
          ],
        ),
        content: Text(mensaje, style: const TextStyle(fontSize: 15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarExito() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(
              '¡Contraseña Actualizada!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primaryDarkColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Su contraseña ha sido cambiada exitosamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver a la pantalla anterior
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese la contraseña';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Debe contener al menos un símbolo (!@#%...)';
    }
    return null;
  }

  String? _validateEmailField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su correo electrónico';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Por favor ingrese un correo electrónico válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Si hay un usuario autenticado, prellenar el campo de correo
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser?.email != null && _emailController.text.isEmpty) {
      _emailController.text = currentUser!.email!;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Actualice su contraseña',
                    style: TextStyle(
                      color: AppTheme.primaryDarkColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Ingrese su correo electrónico y la nueva contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),

                // Correo electrónico
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading && currentUser?.email == null, // Deshabilitar si ya hay un usuario autenticado
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    'Correo Electrónico',
                    'Ingrese su correo electrónico',
                    Icons.email_outlined,
                  ),
                  validator: _validateEmailField,
                ),
                const SizedBox(height: 20),

                // Nueva contraseña
                TextFormField(
                  controller: _newPasswordController,
                  enabled: !_isLoading,
                  obscureText: !_isNewPasswordVisible,
                  decoration: _inputDecoration(
                    'Nueva Contraseña',
                    'Mín. 8 caracteres con letras, números y símbolos',
                    Icons.lock,
                    isPassword: true,
                    isVisible: _isNewPasswordVisible,
                    onToggle: () => setState(
                      () => _isNewPasswordVisible = !_isNewPasswordVisible,
                    ),
                  ),
                  validator: (value) {
                    final error = _validatePassword(value);
                    if (error != null) return error;
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirmar nueva contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: _inputDecoration(
                    'Confirmar Nueva Contraseña',
                    'Repita su nueva contraseña',
                    Icons.lock_clock,
                    isPassword: true,
                    isVisible: _isConfirmPasswordVisible,
                    onToggle: () => setState(
                      () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirme su nueva contraseña';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Botón de cambiar contraseña
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Cambiar Contraseña',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.primaryColor,
              ),
              onPressed: onToggle,
            )
          : null,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
    );
  }
}