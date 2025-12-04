import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // Importamos HomeScreen para acceder al modelo Category

class ItemsListScreen extends StatelessWidget {
  // Recibimos el objeto Category que definimos en HomeScreen
  final Category category;

  const ItemsListScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: category.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        // Usamos el color de la categoría para un degradé sutil
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              category.color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  size: 80,
                  color: category.color,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Categoría: ${category.name}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${category.count} objetos disponibles',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Aquí aparecerán los artículos publicados por los usuarios.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función para publicar artículo próximamente')),
          );
        },
        backgroundColor: category.color,
        child: const Icon(Icons.add),
      ),
    );
  }
}