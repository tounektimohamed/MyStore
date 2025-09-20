import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class OrderForm extends StatefulWidget {
  final Product product;

  OrderForm({this.product});

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
    if (_formKey.currentState.validate()) {
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
        );

        await OrderService().addOrder(order);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Commande passée avec succès!')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
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
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text('Produit: ${widget.product.name}'),
                    Text('Prix: ${widget.product.price} €'),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Nom complet'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!value.contains('@')) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Adresse'),
                      maxLines: 3,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Veuillez entrer votre adresse';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value.isEmpty) {
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
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitOrder,
                      child: Text('Passer la commande'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}