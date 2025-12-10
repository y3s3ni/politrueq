/// Constantes de categorías de productos
class Categorias {
  // Lista de todas las categorías disponibles
  static const List<String> todas = [
    'Comida',
    'Ropa',
    'Útiles Escolares',
    'Deportes',
    'Hogar',
    'Electrónicos',
    'Otros',
  ];

  // Iconos sugeridos para cada categoría
  static const Map<String, String> iconos = {
    'Comida': '🍔',
    'Ropa': '👕',
    'Útiles Escolares': '📚',
    'Deportes': '⚽',
    'Hogar': '🏠',
    'Electrónicos': '💻',
    'Otros': '📦',
  };

  // Descripciones de cada categoría
  static const Map<String, String> descripciones = {
    'Comida': 'Alimentos, bebidas, snacks',
    'Ropa': 'Prendas de vestir, accesorios de moda',
    'Útiles Escolares': 'Cuadernos, lápices, mochilas, material escolar',
    'Deportes': 'Equipamiento deportivo, ropa deportiva',
    'Hogar': 'Decoración, utensilios, muebles pequeños',
    'Electrónicos': 'Dispositivos, cables, accesorios tecnológicos',
    'Otros': 'Cualquier otro artículo',
  };

  // Ejemplos de productos por categoría
  static const Map<String, List<String>> ejemplos = {
    'Comida': [
      'Snacks empaquetados',
      'Bebidas enlatadas',
      'Dulces',
      'Galletas',
    ],
    'Ropa': [
      'Camisetas',
      'Pantalones',
      'Zapatos',
      'Accesorios',
    ],
    'Útiles Escolares': [
      'Cuadernos',
      'Lápices y bolígrafos',
      'Mochilas',
      'Calculadoras',
    ],
    'Deportes': [
      'Balones',
      'Raquetas',
      'Ropa deportiva',
      'Accesorios fitness',
    ],
    'Hogar': [
      'Decoración',
      'Utensilios de cocina',
      'Organizadores',
      'Plantas',
    ],
    'Electrónicos': [
      'Auriculares',
      'Cargadores',
      'Mouse y teclados',
      'Cables USB',
      'Fundas para celular',
      'Memorias USB',
    ],
    'Otros': [
      'Artículos varios',
      'Coleccionables',
      'Artesanías',
    ],
  };

  // Colores sugeridos para cada categoría (Material Design)
  static const Map<String, int> colores = {
    'Comida': 0xFFFF9800, // Orange
    'Ropa': 0xFFE91E63, // Pink
    'Útiles Escolares': 0xFF2196F3, // Blue
    'Deportes': 0xFF4CAF50, // Green
    'Hogar': 0xFF9C27B0, // Purple
    'Electrónicos': 0xFF607D8B, // Blue Grey
    'Otros': 0xFF9E9E9E, // Grey
  };

  /// Obtiene el icono de una categoría
  static String getIcono(String categoria) {
    return iconos[categoria] ?? iconos['Otros']!;
  }

  /// Obtiene la descripción de una categoría
  static String getDescripcion(String categoria) {
    return descripciones[categoria] ?? descripciones['Otros']!;
  }

  /// Obtiene ejemplos de una categoría
  static List<String> getEjemplos(String categoria) {
    return ejemplos[categoria] ?? ejemplos['Otros']!;
  }

  /// Obtiene el color de una categoría
  static int getColor(String categoria) {
    return colores[categoria] ?? colores['Otros']!;
  }

  /// Valida si una categoría es válida
  static bool esValida(String categoria) {
    return todas.contains(categoria);
  }

  /// Obtiene sugerencias de categoría basadas en el nombre del producto
  static String sugerirCategoria(String nombreProducto) {
    final nombre = nombreProducto.toLowerCase();

    // Electrónicos
    if (nombre.contains('auricular') ||
        nombre.contains('cable') ||
        nombre.contains('cargador') ||
        nombre.contains('mouse') ||
        nombre.contains('teclado') ||
        nombre.contains('usb') ||
        nombre.contains('funda') ||
        nombre.contains('celular') ||
        nombre.contains('tablet') ||
        nombre.contains('laptop')) {
      return 'Electrónicos';
    }

    // Ropa
    if (nombre.contains('camisa') ||
        nombre.contains('pantalon') ||
        nombre.contains('zapato') ||
        nombre.contains('vestido') ||
        nombre.contains('blusa')) {
      return 'Ropa';
    }

    // Deportes
    if (nombre.contains('balon') ||
        nombre.contains('pelota') ||
        nombre.contains('raqueta') ||
        nombre.contains('deport')) {
      return 'Deportes';
    }

    // Útiles Escolares
    if (nombre.contains('cuaderno') ||
        nombre.contains('lapiz') ||
        nombre.contains('boligrafo') ||
        nombre.contains('mochila') ||
        nombre.contains('calculadora')) {
      return 'Útiles Escolares';
    }

    // Hogar
    if (nombre.contains('decoracion') ||
        nombre.contains('cocina') ||
        nombre.contains('plato') ||
        nombre.contains('vaso')) {
      return 'Hogar';
    }

    // Comida
    if (nombre.contains('comida') ||
        nombre.contains('bebida') ||
        nombre.contains('snack') ||
        nombre.contains('dulce')) {
      return 'Comida';
    }

    return 'Otros';
  }
}
