import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';

class AdminOrderList extends StatefulWidget {
  @override
  _AdminOrderListState createState() => _AdminOrderListState();
}

class _AdminOrderListState extends State<AdminOrderList> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestion des Commandes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: "Exporter CSV",
            onPressed: _exportCSV,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: OrderService().getOrders(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
                if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
                if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

                // Filtrer par date
                final orders = snapshot.data!.where((order) {
                  final orderDate = order.orderDate;
                  if (_startDate != null && orderDate.isBefore(_startDate!)) return false;
                  if (_endDate != null && orderDate.isAfter(_endDate!)) return false;
                  return true;
                }).toList();

                return _buildOrderList(orders);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.date_range),
              label: Text(_startDate != null
                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                  : 'Date début'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.date_range),
              label: Text(_endDate != null
                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                  : 'Date fin'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => setState(() {
              _startDate = null;
              _endDate = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text('Erreur de chargement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: Colors.blue[700]));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('Aucune commande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return FutureBuilder<Product>(
          future: ProductService().getProduct(order.productId),
          builder: (context, productSnapshot) {
            final productName = productSnapshot.hasData ? productSnapshot.data!.name : 'Produit inconnu';
            return _buildOrderCard(order, productName);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, String productName) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commande #${order.id.substring(0, 8)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Client: ${order.customerName}'),
            _buildInfoRow(Icons.email, 'Email: ${order.customerEmail}'),
            _buildInfoRow(Icons.location_on, 'Adresse: ${order.customerAddress}'),
            _buildInfoRow(Icons.shopping_cart, 'Quantité: ${order.quantity}'),
            _buildInfoRow(Icons.calendar_today,
                'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    final orders = await OrderService().getOrders().first;
    List<List<String>> csvData = [
      ['ID', 'Produit', 'Client', 'Email', 'Adresse', 'Quantité', 'Date']
    ];

    for (var order in orders) {
      final product = await ProductService().getProduct(order.productId);
      csvData.add([
        order.id,
        product?.name ?? 'Produit inconnu',
        order.customerName,
        order.customerEmail,
        order.customerAddress,
        order.quantity.toString(),
        DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/orders.csv';
    final file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exporté: $path')));
  }
}
