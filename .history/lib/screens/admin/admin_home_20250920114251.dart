import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store/screens/user/user_home.dart';
import '../../services/auth_service.dart';
import 'product_list.dart';
import 'order_list.dart';

class AdminHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => UserHome()));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AdminProductList()));
              },
              child: Text('Gérer les produits'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AdminOrderList()));
              },
              child: Text('Voir les commandes'),
            ),
          ],
        ),
      ),
    );
  }
}