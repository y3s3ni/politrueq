import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Modelo simple para las categorías, para manejar ID y nombre.
class _Category {
  final int id;
  final String name;
  _Category(this.id, this.name);
}

// Modelo simple para las opciones de puntos, para manejar etiqueta y valor.
class _PointsOption {
  final String label;
  final int value;
  _PointsOption(this.label, this.value);
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();

  // Futuro para cargar las categorías dinámicamente
  late final Future<List<_Category>> _categoriesFuture;

  final List<_PointsOption> _pointsOptions = [
    _PointsOption('1-2', 2),
    _PointsOption('3-4', 4),
    _PointsOption('5-6', 6),
  ];

  // Estado del formulario
  int? _selectedCategoryId;
  int? _selectedPointsValue;
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
  }

  Future<List<_Category>> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client.from('categorias').select('id_categoria, nombre_categoria');
      final List<_Category> categories = (response as List).map((item) {
        return _Category(item['id_categoria'], item['nombre_categoria']);
      }).toList();
      return categories;
    } catch (e) {
      _showErrorSnackBar('No se pudieron cargar las categorías: ${e.toString()}');
      return [];
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      _showErrorSnackBar('Puedes seleccionar un máximo de 3 imágenes.');
      return;
    }
    try {
      final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1024);
      if (pickedFile != null) {
        setState(() => _selectedImages.add(pickedFile));
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar la imagen: $e');
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galería'), onTap: () => _pickImageWithPop(ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Cámara'), onTap: () => _pickImageWithPop(ImageSource.camera)),
          ],
        ),
      ),
    );
  }

  void _pickImageWithPop(ImageSource source) {
    Navigator.of(context).pop();
    _pickImage(source);
  }

  Future<void> _submitPublication() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) {
      if (_selectedImages.isEmpty) {
        _showErrorSnackBar('Por favor, sube al menos una imagen.');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Debes iniciar sesión para publicar.');

      final List<String> imageUrls = [];
      for (final image in _selectedImages) {
        final imageBytes = await image.readAsBytes();
        final imageExtension = image.path.split('.').last.toLowerCase();
        final imageFileName = 'public/${user.id}/${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(image)}.$imageExtension';

        await Supabase.instance.client.storage.from('articulos').uploadBinary(
              imageFileName,
              imageBytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );
        imageUrls.add(Supabase.instance.client.storage.from('articulos').getPublicUrl(imageFileName));
      }

      await Supabase.instance.client.from('articulos').insert({
        'nombre_producto': _nombreController.text,
        'descripcion': _descripcionController.text,
        'id_categoria': _selectedCategoryId,
        'puntos_necesarios': _selectedPointsValue,
        'ubicacion_aproximada': _ubicacionController.text,
        'image_urls': imageUrls,
        'id_usuario': user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Artículo publicado con éxito!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Error al publicar el artículo: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Nuevo Producto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(_nombreController, 'Título del producto', 'Ej: Calculadora Casio FX-991'),
              const SizedBox(height: 16),
              _buildTextFormField(_descripcionController, 'Descripción detallada', 'Incluye estado, detalles y características.', maxLines: 4),
              const SizedBox(height: 20),
              _buildImagePicker(),
              const SizedBox(height: 20),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildPointsDropdown(),
              const SizedBox(height: 16),
              _buildTextFormField(_ubicacionController, 'Ubicación del producto', 'Ej: Riobamba, Cerca de la ESPOCH'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPublication,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Publicar Artículo', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Este campo es obligatorio' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<_Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Categoría',
              errorText: 'No se pudieron cargar',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            hint: const Text('Error'),
            items: const [],
            onChanged: null,
          );
        }

        final categories = snapshot.data!;
        return DropdownButtonFormField<int>(
          value: _selectedCategoryId,
          decoration: InputDecoration(labelText: 'Categoría', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          hint: const Text('Seleccionar categoría'),
          items: categories.map((category) => DropdownMenuItem<int>(value: category.id, child: Text(category.name))).toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
          validator: (value) => value == null ? 'Debes seleccionar una categoría' : null,
        );
      },
    );
  }

  Widget _buildPointsDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedPointsValue,
      decoration: InputDecoration(labelText: 'Cantidad de puntos', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      hint: const Text('Seleccionar puntos'),
      items: _pointsOptions.map((option) => DropdownMenuItem<int>(value: option.value, child: Text(option.label))).toList(),
      onChanged: (value) => setState(() => _selectedPointsValue = value),
      validator: (value) => value == null ? 'Debes asignar una cantidad de puntos' : null,
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imágenes (máx. 3)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._selectedImages.asMap().entries.map((entry) {
              int index = entry.key;
              XFile imageFile = entry.value;
              return SizedBox(
                width: 100, height: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb
                          ? Image.network(imageFile.path, width: 100, height: 100, fit: BoxFit.cover)
                          : Image.file(File(imageFile.path), width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -8, right: -8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImages.removeAt(index)),
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_selectedImages.length < 3)
              GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade400, width: 1.5)),
                  child: Center(child: Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600, size: 36)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
