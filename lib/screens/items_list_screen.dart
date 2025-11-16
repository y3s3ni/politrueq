import 'package:flutter/material.dart';
import 'package:trueque/screens/home_screen.dart'; 

class ItemsListScreen extends StatelessWidget {
  final Category category;

  const ItemsListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, size: 80, color: category.color),
            const SizedBox(height: 20),
            Text(
              'Artículos en la categoría "${category.name}"',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const Text('Aquí aparecerán los artículos publicados por los usuarios.'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función para publicar artículo próximamente')),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}