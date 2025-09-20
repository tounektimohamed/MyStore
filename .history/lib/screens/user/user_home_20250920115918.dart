import 'package:flutter/material.dart';
import 'package:store/screens/admin/product_list.dart';

class UserHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Boutique en Ligne'),
      ),
      body: UserProductList(),
    );
  }
}