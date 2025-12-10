import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class SearchProductsScreen extends StatefulWidget {
  const SearchProductsScreen({Key? key}) : super(key: key);

  @override
  State<SearchProductsScreen> createState() => _SearchProductsScreenState();
}

class _SearchProductsScreenState extends State<SearchProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _productos = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _selectedCategory = 'Todos';

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'Todos', 'name': 'Todos', 'icon': Icons.apps, 'color': Color(0xFFEF233C)},
    {'id': 'Electrónicos', 'name': 'Electrónicos', 'icon': Icons.phone_android, 'color': Color(0xFFEF233C)},
    {'id': 'Comida', 'name': 'Comida', 'icon': Icons.restaurant, 'color': Color(0xFFD90429)},
    {'id': 'Ropa', 'name': 'Ropa', 'icon': Icons.checkroom, 'color': Color(0xFFC1121F)},
    {'id': 'Útiles Escolares', 'name': 'Útiles Escolares', 'icon': Icons.school, 'color': Color(0xFFB91C1C)},
    {'id': 'Deportes', 'name': 'Deportes', 'icon': Icons.sports_soccer, 'color': Color(0xFF991B1B)},
    {'id': 'Hogar', 'name': 'Hogar', 'icon': Icons.home, 'color': Color(0xFF8D0801)},
    {'id': 'Otros', 'name': 'Otros', 'icon': Icons.toys, 'color': Color(0xFFDC2626)},
  ];

  Future<void> _buscarProductos() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Obtener todos los productos disponibles
      final result = await SupabaseService.getObjetosDisponibles();
      
      if (result['success']) {
        List<Map<String, dynamic>> productos = List<Map<String, dynamic>>.from(result['data']);
        
        // Filtrar por texto de búsqueda
        final searchText = _searchController.text.trim().toLowerCase();
        if (searchText.isNotEmpty) {
          productos = productos.where((p) {
            final nombre = (p['nombre'] ?? '').toString().toLowerCase();
            final descripcion = (p['descripcion'] ?? '').toString().toLowerCase();
            return nombre.contains(searchText) || descripcion.contains(searchText);
          }).toList();
        }
        
        // Filtrar por categoría si no es "Todos"
        if (_selectedCategory != 'Todos') {
          productos = productos.where((p) => p['categoria'] == _selectedCategory).toList();
        }
        
        setState(() {
          _productos = productos;
          _isLoading = false;
        });
      } else {
        setState(() {
          _productos = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al buscar productos: $e');
      setState(() {
        _productos = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Productos', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFEF233C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEF233C),
              const Color(0xFFEF233C).withOpacity(0.8),
              Colors.white
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con buscador
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué estás buscando?',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Encuentra el producto perfecto para ti',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Barra de búsqueda
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFEF233C)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _productos = [];
                                      _hasSearched = false;
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onSubmitted: (_) => _buscarProductos(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón de búsqueda
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _buscarProductos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFEF233C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Buscar',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filtro por categoría
                        Text(
                          'Filtrar por categoría',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF233C),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category['id'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category['icon'] as IconData,
                                        size: 18,
                                        color: isSelected ? Colors.white : category['color'] as Color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        category['name'] as String,
                                        style: GoogleFonts.poppins(
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category['id'] as String;
                                    });
                                    // Siempre buscar cuando se selecciona una categoría
                                    _buscarProductos();
                                  },
                                  selectedColor: const Color(0xFFEF233C),
                                  backgroundColor: Colors.grey[100],
                                  checkmarkColor: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Resultados
                        Expanded(
                          child: _buildResultados(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultados() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFEF233C),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Busca productos por nombre',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'o filtra por categoría',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otra búsqueda',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_productos.length} producto${_productos.length != 1 ? 's' : ''} encontrado${_productos.length != 1 ? 's' : ''}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _productos.length,
            itemBuilder: (context, index) {
              final producto = _productos[index];
              return _buildProductoCard(producto);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final imageUrls = producto['image_urls'] as List?;
    final imageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls[0] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle del producto
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto['nombre'] ?? 'Sin nombre',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      producto['descripcion'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF233C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            producto['categoria'] ?? 'Otros',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFFEF233C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${producto['puntos_necesarios'] ?? 0} pts',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
