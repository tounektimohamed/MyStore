import 'package:flutter/material.dart';
import 'package:store/models/order.dart';
import 'package:store/services/order_service.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Order> _confirmedOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadConfirmedOrders();
  }

  Future<void> _loadConfirmedOrders() async {
    try {
      dynamic result = await OrderService().getOrders();
      
      List<Order> allOrders = [];
      
      // Gestion de différents types de retours
      if (result is List<Order>) {
        allOrders = result;
      } else if (result is List<List<Order>>) {
        // Si c'est une liste de listes, on les combine
        allOrders = result.expand((orderList) => orderList).toList();
      } else if (result is Future<List<Order>>) {
        // Si c'est un Future, on l'attend
        allOrders = await result;
      } else {
        throw Exception('Format de données non supporté');
      }
      
      // Filtrer les commandes confirmées
      setState(() {
        _confirmedOrders = allOrders.where((order) {
          // Vérifier si la propriété status existe
          try {
            return order.status == 'confirmed';
          } catch (e) {
            // Si la propriété status n'existe pas, considérer toutes les commandes comme confirmées
            return true;
          }
        }).toList();
        
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Commandes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        elevation: 1,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
            ? Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              )
            : _confirmedOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune commande confirmée',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Vos commandes confirmées apparaîtront ici',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _confirmedOrders.length,
                    itemBuilder: (context, index) {
                      final order = _confirmedOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${order.id.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(
                    'Confirmée',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Produit: ${order.productId}',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Quantité: ${order.quantity}',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(order.orderDate)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}