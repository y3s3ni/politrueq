import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:trueque/screens/items_list_screen.dart';
import 'package:trueque/screens/register_screen.dart';
import 'package:trueque/screens/login_screen.dart'; // Añade esta importación
import 'package:trueque/theme/app_theme.dart'; 
import 'package:trueque/widgets/circle_background.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user?.userMetadata?['name'] != null) {
      setState(() {
        _userName = user!.userMetadata!['name'];
      });
    } else {
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', user!.id)
            .single();
        setState(() {
          _userName = response['name'] ?? 'Usuario';
        });
      } catch (e) {
        setState(() {
          _userName = 'Usuario';
        });
      }
    }
  }

  Future<void> _signOut() async {
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color.fromARGB(137, 255, 25, 9)),
              child: const Text('Cerrar Sesión'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      await Supabase.instance.client.auth.signOut();
      // Navegar a la pantalla de login y eliminar todas las rutas anteriores
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poli-Trueque'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        actions: [
          // Botón para crear cuenta
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Crear Cuenta',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
          ),
          // Botón de cerrar sesión 
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _signOut,
          ),
        ],
      ),
      body: CircleBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $_userName!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDarkColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Qué quieres intercambiar hoy?',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCard(category: category);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const List<Category> categories = [
    Category(id: 'school', name: 'Útiles Escolares', icon: Icons.backpack, color: AppTheme.primaryColor),
    Category(id: 'food', name: 'Comida', icon: Icons.fastfood, color: Colors.orange),
    Category(id: 'home', name: 'Hogar', icon: Icons.chair, color: Colors.brown),
    Category(id: 'clothing', name: 'Ropa', icon: Icons.checkroom, color: Colors.purple),
    Category(id: 'other', name: 'Otros', icon: Icons.category, color: AppTheme.primaryDarkColor),
  ];
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
          color: category.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: category.color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, size: 50, color: category.color),
            const SizedBox(height: 12),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: category.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
