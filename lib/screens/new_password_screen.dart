import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/widgets/circle_background.dart'; 

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
 
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  static const Color primaryRed = Color(0xFFC62828);
  static const Color secondaryRed = Color(0xFF991B1B);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        EasyLoading.show(status: 'Actualizando contraseña...');
        
      
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim()),
        );
        
        EasyLoading.dismiss();
        
        // Mostrar éxito y navegar al login
        if (mounted) { 
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: Icon(Icons.check_circle, color: primaryRed, size: 50),
              title: const Text('¡Contraseña Actualizada!'),
              content: const Text('Tu contraseña ha sido cambiada exitosamente. Ahora puedes iniciar sesión.'),
              actions: [
                TextButton(
                  onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }

      } on AuthException catch (e) {
        EasyLoading.dismiss();
        if (mounted) _mostrarError('Error: ${e.message}');
      } catch (e) {
        EasyLoading.dismiss();
        if (mounted) _mostrarError('Ocurrió un error inesperado.');
      }
    }
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CircleBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                       Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: primaryRed.withOpacity(0.2), 
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                         child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      Text(
                        'Nueva Contraseña',
                        style: TextStyle(
                          color: secondaryRed,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Introduce tu nueva contraseña a continuación.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // --- Campo de Nueva Contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: _inputDecoration(
                          'Nueva Contraseña', 
                          'Mínimo 6 caracteres',
                          Icons.lock,
                          isPassword: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      // --- Campo de Confirmar Contraseña 
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: _inputDecoration(
                          'Confirmar Contraseña', 
                          'Mínimo 6 caracteres', 
                          Icons.lock_outline,
                          isConfirmPassword: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirma la contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 50),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _updatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Actualizar Contraseña',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
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
    bool isConfirmPassword = false,
  }) {
    bool isVisible;
    VoidCallback toggleVisibility;

    if (isConfirmPassword) {
      isVisible = _isConfirmPasswordVisible;
      toggleVisibility = () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
    } else if (isPassword) {
      isVisible = _isPasswordVisible;
      toggleVisibility = () => setState(() => _isPasswordVisible = !_isPasswordVisible);
    } else {
      isVisible = true;
      toggleVisibility = () {};
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryRed),
      suffixIcon: (isPassword || isConfirmPassword)
          ? IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: primaryRed,
              ),
              onPressed: toggleVisibility,
            )
          : null,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}