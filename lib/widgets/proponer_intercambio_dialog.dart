import 'package:flutter/material.dart';
import '../services/puntos_service.dart';
import '../services/supabase_service.dart';

class ProponerIntercambioDialog extends StatefulWidget {
  final Map<String, dynamic> productoSolicitado;

  const ProponerIntercambioDialog({
    Key? key,
    required this.productoSolicitado,
  }) : super(key: key);

  @override
  State<ProponerIntercambioDialog> createState() =>
      _ProponerIntercambioDialogState();
}

class _ProponerIntercambioDialogState extends State<ProponerIntercambioDialog> {
  List<dynamic> _misProductos = [];
  String? _productoSeleccionadoId;
  Map<String, dynamic>? _productoSeleccionado;
  bool _isLoading = true;
  bool _isValidating = false;
  Map<String, dynamic>? _validacionResult;
  int _puntosUsuario = 0;

  @override
  void initState() {
    super.initState();
    _cargarMisProductos();
  }

  Future<void> _cargarMisProductos() async {
    setState(() => _isLoading = true);

    final userId = SupabaseService.getCurrentAuthUser()?.id;
    if (userId == null) return;

    // Cargar puntos del usuario
    final puntosResult = await PuntosService.getPuntosUsuario(userId);
    if (puntosResult['success']) {
      _puntosUsuario = puntosResult['puntos'];
    }

    // Cargar productos del usuario (disponibles y aprobados)
    final response = await SupabaseService.client
        .from('productos_unificados')
        .select()
        .eq('usuario_id', userId)
        .eq('disponible', true)
        .eq('estado_aprobacion', 'aprobado')
        .order('creado_en', ascending: false);

    setState(() {
      _misProductos = response;
      _isLoading = false;
    });
  }

  Future<void> _validarIntercambio() async {
    if (_productoSeleccionadoId == null) return;

    setState(() => _isValidating = true);

    final userId = SupabaseService.getCurrentAuthUser()?.id;
    if (userId == null) return;

    final result = await PuntosService.validarIntercambio(
      usuarioOfertanteId: userId,
      usuarioReceptorId: widget.productoSolicitado['usuario_id'],
      productoOfertadoId: _productoSeleccionadoId!,
      productoSolicitadoId: widget.productoSolicitado['id'],
    );

    setState(() {
      _validacionResult = result;
      _isValidating = false;
    });
  }

  Future<void> _enviarPropuesta() async {
    if (_productoSeleccionadoId == null) return;

    final result = await PuntosService.proponerIntercambio(
      usuarioReceptorId: widget.productoSolicitado['usuario_id'],
      productoOfertadoId: _productoSeleccionadoId!,
      productoSolicitadoId: widget.productoSolicitado['id'],
    );

    if (!mounted) return;

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Proponer Intercambio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Puntos disponibles
                          _buildPuntosCard(),
                          const SizedBox(height: 16),

                          // Producto solicitado
                          const Text(
                            'Producto que solicitas:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildProductoCard(widget.productoSolicitado),
                          
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Seleccionar mi producto
                          const Text(
                            'Selecciona tu producto para ofrecer:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_misProductos.isEmpty)
                            _buildNoProductos()
                          else
                            ..._misProductos.map((producto) {
                              return _buildProductoSeleccionable(producto);
                            }).toList(),

                          // Validación
                          if (_isValidating)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            ),

                          if (_validacionResult != null)
                            _buildValidacionResult(),
                        ],
                      ),
                    ),
            ),

            // Footer con botones
            if (!_isLoading && _misProductos.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _productoSeleccionadoId != null &&
                                _validacionResult?['success'] == true
                            ? _enviarPropuesta
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Enviar Propuesta'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuntosCard() {
    final puntosNecesarios = widget.productoSolicitado['puntos_necesarios'] as int;
    final tieneSuficientes = _puntosUsuario >= puntosNecesarios;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tieneSuficientes ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tieneSuficientes ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            tieneSuficientes ? Icons.check_circle : Icons.warning,
            color: tieneSuficientes ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus puntos: $_puntosUsuario',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Necesitas: $puntosNecesarios puntos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (!tieneSuficientes)
            Text(
              'Insuficiente',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final imageUrls = producto['image_urls'] as List?;
    final imageUrl = (imageUrls != null && imageUrls.isNotEmpty)
        ? imageUrls[0]
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(Icons.image, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto['nombre'] ?? 'Producto',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  producto['categoria'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${producto['puntos_necesarios']} pts',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoSeleccionable(Map<String, dynamic> producto) {
    final isSelected = _productoSeleccionadoId == producto['id'];
    final imageUrls = producto['image_urls'] as List?;
    final imageUrl = (imageUrls != null && imageUrls.isNotEmpty)
        ? imageUrls[0]
        : null;

    return GestureDetector(
      onTap: () {
        setState(() {
          _productoSeleccionadoId = producto['id'];
          _productoSeleccionado = producto;
          _validacionResult = null;
        });
        _validarIntercambio();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(Icons.image, color: Colors.grey, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'] ?? 'Producto',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    producto['estado_fisico'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${producto['puntos_necesarios']} pts',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProductos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, 
               size: 48, 
               color: Colors.orange.shade700),
          const SizedBox(height: 8),
          Text(
            'No tienes productos disponibles',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Publica un producto para poder intercambiar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValidacionResult() {
    final isValid = _validacionResult!['success'] == true;
    final mensaje = _validacionResult!['message'] as String;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                fontSize: 13,
                color: isValid ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
