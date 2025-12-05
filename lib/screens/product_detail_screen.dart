import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trueque/screens/items_list_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Color categoryColor;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.categoryColor,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isSubmitting = false;

  Future<void> _initiateExchange() async {
    final wantToExchange = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Intercambio'),
        content: Text('¿Estás seguro de que deseas intercambiar ${widget.product.points} puntos por este artículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: widget.categoryColor),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (wantToExchange != true) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión para realizar un intercambio.');
      }

      await Supabase.instance.client.rpc('crear_intercambio', params: {
        'producto_id': widget.product.id,
        'comprador_id': user.id,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Intercambio realizado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el intercambio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: Text(widget.product.name),
        backgroundColor: widget.categoryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            '${widget.product.points} puntos',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: widget.categoryColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Descripción',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.product.imageUrls.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: widget.product.imageUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            widget.product.imageUrls[index],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _initiateExchange,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.categoryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                : Text(
                    'Intercambiar por ${widget.product.points} puntos',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
