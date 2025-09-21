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
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _regionController = TextEditingController();
  final _codePostalController = TextEditingController();
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
          customerPhone: _phoneController.text,
          customerAddress: _addressController.text,
          customerRegion: _regionController.text,
          customerCodePostal: _codePostalController.text,
          quantity: int.parse(_quantityController.text),
          orderDate: DateTime.now(),
          status: 'En attente', // Ajout du statut par défaut
        );

        await OrderService().addOrder(order);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande passée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            return const Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            );
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _codePostalController.dispose();
    _quantityController.dispose();
    super.dispose();
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            )
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
                                'Stock disponible: ${widget.product.stock}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                        _buildTextField(
                          _nameController,
                          'Nom complet',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _phoneController,
                          'Téléphone',
                          keyboardType: TextInputType.phone,
                          icon: Icons.phone,
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
                          'Adresse (Rue)',
                          maxLines: 2,
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _regionController,
                          'Région',
                          maxLines: 1,
                          icon: Icons.map,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _codePostalController,
                          'Code Postal',
                          maxLines: 1,
                          keyboardType: TextInputType.number,
                          icon: Icons.markunread_mailbox,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Veuillez entrer votre code postal';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _quantityController,
                          'Quantité',
                          keyboardType: TextInputType.number,
                          icon: Icons.shopping_cart,
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
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _showConfirmationDialog();
                        }
                      },
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Passer la commande',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
    IconData? icon,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator ??
          (val) {
            if (val == null || val.isEmpty) {
              return 'Veuillez entrer $label';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}