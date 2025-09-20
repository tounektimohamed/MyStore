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
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  bool _isLoading = false;

  // Fonction pour calculer le total (produit + livraison)
  double _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final productTotal = widget.product.price * quantity;
    return productTotal + 8.0; // 8 DT pour la livraison
  }

  // Fonction pour afficher le dialogue de confirmation
  Future<void> _showConfirmationDialog() async {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final productTotal = widget.product.price * quantity;
    final totalWithDelivery = _calculateTotal();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Produit: ${widget.product.name}'),
              Text('Quantité: $quantity'),
              Text('Prix unitaire: ${widget.product.price.toStringAsFixed(2)} Z'),
              Text('Sous-total: ${productTotal.toStringAsFixed(2)} €'),
              const SizedBox(height: 8),
              Text('Livraison: 8.00 DT', 
                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 8),
              Text('Total: ${totalWithDelivery.toStringAsFixed(2)} DT', 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                Navigator.of(context).pop(); // Fermer le dialogue
                _submitOrder(); // Soumettre la commande
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
          customerEmail: _emailController.text,
          customerAddress: _addressController.text,
          quantity: int.parse(_quantityController.text),
          orderDate: DateTime.now(),
        );

        await OrderService().addOrder(order);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande passée avec succès !')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fonction pour afficher correctement l'image (URL ou base64)
  Widget buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 60, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.red, size: 40),
      );
    } else {
      try {
        final bytes = base64Decode(imageUrl);
        return Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.red, size: 40),
        );
      } catch (e) {
        return const Icon(Icons.error, color: Colors.red, size: 40);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commander ${widget.product.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Affichage de l'image du produit
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: buildProductImage(widget.product.imageUrl),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.product.price.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Affichage des frais de livraison
                    const SizedBox(height: 8),
                    const Text(
                      'Frais de livraison: 8.00 DT',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Affichage du total estimé
                    const SizedBox(height: 8),
                    Text(
                      'Total estimé: ${_calculateTotal().toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!value.contains('@')) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre adresse';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantité',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {}); // Rafraîchir l'affichage du total
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Veuillez entrer une quantité valide';
                        }
                        if (quantity > widget.product.stock) {
                          return 'Stock insuffisant. Maximum: ${widget.product.stock}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _showConfirmationDialog();
                          }
                        },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Passer la commande',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}