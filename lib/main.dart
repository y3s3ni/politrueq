import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/screens/password_screen.dart';
import 'package:trueque/screens/register_screen.dart';
import 'package:trueque/theme/app_theme.dart';
import 'package:trueque/screens/login_screen.dart';
import 'package:trueque/screens/new_password_screen.dart'; 
import 'package:trueque/screens/home_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_KEY'];
  
  _validateRequiredEnvVars();

  
  await Supabase.initialize(
    url: supabaseUrl!,
    anonKey: supabaseAnonKey!,
    
  );

  runApp(const MyApp());
}

void _validateRequiredEnvVars() {
  final requiredVars = ['SUPABASE_URL', 'SUPABASE_KEY'];
  for (final varName in requiredVars) {
    if (dotenv.env[varName]?.isEmpty ?? true) {
      throw Exception('Variable de entorno requerida faltante: $varName');
    } 
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trueque',
      theme: AppTheme.getTheme(),
      initialRoute: '/',
      
      routes: {
        '/': (context) => const LoginScreen(), 
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/reset-password': (context) => const NewPasswordScreen(),
        '/password': (context) => const PasswordScreen(),
      }

    );
  }
}