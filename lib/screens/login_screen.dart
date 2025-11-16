import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/screens/password_screen.dart';
import 'package:trueque/screens/register_screen.dart';
import 'package:trueque/theme/app_theme.dart';
import 'package:trueque/widgets/circle_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIN CON EMAIL 
  Future<void> _loginEmail() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();

      // --- NUEVA VALIDACIÓN DE CORREO INSTITUCIONAL ---
      if (!email.endsWith('@espoch.edu.ec')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, use un correo institucional (@espoch.edu.ec)',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return; 
      }

      try {
        EasyLoading.show(status: 'Iniciando sesión...');
        
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: _passwordController.text,
        );
        
        EasyLoading.dismiss();
        
        // Verificar si el usuario ha sido confirmado
        if (response.user != null) {
          if (response.user!.emailConfirmedAt != null) {
            EasyLoading.showSuccess('¡Bienvenido!');
            
            // Navegar a la pantalla principal después de un inicio de sesión exitoso
            // Reemplaza '/home' con la ruta correcta de tu pantalla principal
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', 
              (route) => false,
            );
          } else {
            // El correo no ha sido confirmado
            _mostrarError(
              'Su correo electrónico no ha sido confirmado. Por favor revise su bandeja de entrada y spam.',
            );
          }
        } else {
          _mostrarError('No se pudo iniciar sesión. Por favor intente nuevamente.');
        }
      } on AuthException catch (e) {
        EasyLoading.dismiss();
        _mostrarError(e.message);
      } catch (e) {
        EasyLoading.dismiss();
        _mostrarError('Ocurrió un error inesperado: ${e.toString()}');
      }
    }
  }

  // --- MOSTRAR ERRORES ---
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo y título
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'POLI-TRUEQUE',
                        style: TextStyle(
                          color: AppTheme.primaryDarkColor,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Formulario de login
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo de correo electrónico
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'ejemplo@espoch.edu.ec',
                          prefixIcon: const Icon(Icons.email, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su correo electrónico';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Campo de contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: 'Ingrese su contraseña',
                          prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su contraseña';
                          }
                          if (value.length < 6) {
                            return 'Debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) =>  PasswordScreen()));
                          },
                          child: const Text(
                            '¿Olvidó su contraseña?',
                            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón de inicio de sesión
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _loginEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),

                     
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Enlace para registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tiene una cuenta? ', style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}