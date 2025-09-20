import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/order_service.dart';

class OrderForm extends StatefulWidget {
  final Product product;

  const OrderForm({super.key, required this.product});

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

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        Order order = Order(
          productId: widget.product.id,
          customerName: _nameController.text,
          customerEmail: _emailController.text,
          customerAddress: _addressController.text,
          quantity: int.parse(_quantityController.text),
          orderDate: DateTime.now(),
          id: '',
        );

        await OrderService().addOrder(order);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Commande passée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Commander ${widget.product.name}"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image du produit
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.product.imageUrl,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported,
                              size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Infos produit
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${widget.product.price.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Stock disponible : ${widget.product.stock}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Champs du formulaire
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration("Nom complet", Icons.person),
                      validator: (value) =>
                          value!.isEmpty ? "Veuillez entrer votre nom" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration("Email", Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return "Veuillez entrer votre email";
                        if (!value.contains('@')) {
                          return "Veuillez entrer un email valide";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration:
                          _inputDecoration("Adresse", Icons.location_on),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty
                          ? "Veuillez entrer votre adresse"
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      decoration: _inputDecoration("Quantité", Icons.shopping_cart),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return "Veuillez entrer une quantité";
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return "Veuillez entrer une quantité valide";
                        }
                        if (quantity > widget.product.stock) {
                          return "Stock insuffisant (max ${widget.product.stock})";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bouton Commander
                    ElevatedButton.icon(
                      onPressed: _submitOrder,
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Passer la commande"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
