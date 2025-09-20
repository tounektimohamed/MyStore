import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store/models/product.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';

class AdminOrderList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commandes'),
      ),
      body: StreamBuilder<List<Order>>(
        stream: OrderService().getOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Order order = snapshot.data![index];
              return FutureBuilder<Product>(
                future: ProductService().getProduct(order.productId),
                builder: (context, productSnapshot) {
                  String productName = productSnapshot.hasData
                      ? productSnapshot.data!.name
                      : 'Chargement...';

                  return ListTile(
                    title: Text('Commande de $productName'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Client: ${order.customerName}'),
                        Text('Quantité: ${order.quantity}'),
                        Text('Statut: ${order.status}'),
                      ],
                    ),
                    trailing: DropdownButton<String>(
                      value: order.status,
                      items: <String>[
                        'En attente',
                        'Confirmée',
                        'Expédiée',
                        'Livrée',
                        'Annulée'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(), onChanged: (String? value) {  },
                     
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}