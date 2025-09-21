import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/order_service.dart';

class OrderForm extends StatefulWidget {
  final Product product;

  const OrderForm({Key? key, required this.product}) : super(key: key);

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController =
      TextEditingController(); // Nouveau contrôleur téléphone
  final _addressController = TextEditingController();
  final _RegionController =
      TextEditingController(); // Nouveau contrôleur Region
  final _CodePostal = TextEditingController(); // Nouveau contrôleur Region

  final _quantityController = TextEditingController(text: '1');
  bool _isLoading = false;

  double _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final productTotal = widget.product.price * quantity;
    return productTotal + 8.0; // Livraison
  }

  Future<void> _showConfirmationDialog() async {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final totalWithDelivery = _calculateTotal();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirmer la commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Produit: ${widget.product.name}'),
              Text('Quantité: $quantity'),
              Text(
                'Prix unitaire: ${widget.product.price.toStringAsFixed(2)} DT',
              ),
              const SizedBox(height: 8),
              Text(
                'Livraison: 8.00 DT',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${totalWithDelivery.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Êtes-vous sûr de vouloir confirmer cette commande?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitOrder();
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final order = Order(
          id: '',
          productId: widget.product.id,
          customerName: _nameController.text,
          customerPhone: _phoneController.text, // Ajouté
          customerAddress: _addressController.text,
          customerRegion: _RegionController.text, // Ajouté
          customerCodePostal: _CodePostal.text, // Ajouté

          quantity: int.parse(_quantityController.text),
          orderDate: DateTime.now(),
        );

        await OrderService().addOrder(order);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande passée avec succès !')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image, size: 60, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 40, color: Colors.red),
        ),
      );
    } else {
      try {
        final bytes = base64Decode(imageUrl);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 40, color: Colors.red),
          ),
        );
      } catch (e) {
        return const Icon(Icons.error, size: 40, color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commander ${widget.product.name}'),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte produit
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Colors.grey.shade300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildProductImage(widget.product.imageUrl),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.product.price.toStringAsFixed(2)} DT',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Frais de livraison: 8.00 DT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total estimé: ${_calculateTotal().toStringAsFixed(2)} DT',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(_nameController, 'Nom complet'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _phoneController,
                          'Téléphone', // Ajouté
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Veuillez entrer votre numéro de téléphone';
                            }
                            // Validation basique du numéro de téléphone
                            final phoneRegex = RegExp(r'^[0-9+\-\s]{8,15}$');
                            if (!phoneRegex.hasMatch(val)) {
                              return 'Veuillez entrer un numéro de téléphone valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _addressController,
                          'Adresse (Rue)', // Modifié
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _RegionController,
                          'Region', // Ajouté
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          _CodePostal,
                          'Code Postal', // Ajouté
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _quantityController,
                          'Quantité',
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() {}),
                          validator: (val) {
                            final quantity = int.tryParse(val ?? '');
                            if (quantity == null || quantity <= 0) {
                              return 'Veuillez entrer une quantité valide';
                            }
                            if (quantity > widget.product.stock) {
                              return 'Stock insuffisant. Max: ${widget.product.stock}';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _showConfirmationDialog();
                        }
                      },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Passer la commande',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator:
          validator ??
          (val) {
            if (val == null || val.isEmpty) {
              return 'Veuillez entrer $label';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
