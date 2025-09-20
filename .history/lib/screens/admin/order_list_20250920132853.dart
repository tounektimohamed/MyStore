import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  String _searchQuery = '';
  String _selectedFilter = 'Toutes';
  final List<String> _filterOptions = ['Toutes', 'Confirmées', 'En attente', 'Expédiées', 'Annulées'];
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Gestion des Commandes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download_for_offline_outlined),
            tooltip: "Exporter les données",
            onPressed: _isExporting ? null : _showExportOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres et recherche
          _buildFilterSection(),
          // Statistiques rapides
          _buildStatsSection(),
          // Liste des commandes
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: OrderService().getOrders(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
                if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
                if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

                // Filtrer et trier les commandes
                final orders = _filterAndSortOrders(snapshot.data!);

                return _buildOrderList(orders);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Section des filtres et recherche
  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une commande, un client...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              // Filtre par statut
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      isExpanded: true,
                      icon: Icon(Icons.filter_list, color: Colors.blue[700]),
                      items: _filterOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedFilter = newValue!);
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Bouton de filtre date
              OutlinedButton.icon(
                icon: Icon(Icons.date_range, size: 18),
                label: Text('Dates', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: _showDateFilterDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section des statistiques
  Widget _buildStatsSection() {
    return StreamBuilder<List<Order>>(
      stream: OrderService().getOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        
        final orders = snapshot.data!;
        final totalOrders = orders.length;
        final confirmedOrders = orders.where((o) => o.status == 'confirmed').length;
        final pendingOrders = orders.where((o) => o.status == 'En attente').length;
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', totalOrders.toString(), Colors.blue),
              _buildStatCard('Confirmées', confirmedOrders.toString(), Colors.green),
              _buildStatCard('En attente', pendingOrders.toString(), Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Filtrage et tri des commandes
  List<Order> _filterAndSortOrders(List<Order> orders) {
    // Filtrer par recherche
    var filteredOrders = orders.where((order) {
      final matchesSearch = _searchQuery.isEmpty ||
          order.customerName.toLowerCase().contains(_searchQuery) ||
          order.customerEmail.toLowerCase().contains(_searchQuery) ||
          order.id.toLowerCase().contains(_searchQuery);
      
      // Filtrer par statut
      final matchesFilter = _selectedFilter == 'Toutes' || 
          order.status == _selectedFilter;
      
      // Filtrer par date
      final orderDate = order.orderDate;
      final matchesDate = (_startDate == null || orderDate.isAfter(_startDate!)) &&
          (_endDate == null || orderDate.isBefore(_endDate!.add(Duration(days: 1))));
      
      return matchesSearch && matchesFilter && matchesDate;
    }).toList();

    // Trier par date (plus récent en premier)
    filteredOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    
    return filteredOrders;
  }

  // Dialog pour le filtre de date
  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtrer par date', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.blue[700]),
              title: Text('Du ${_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : '...'}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                  Navigator.pop(context);
                  _showDateFilterDialog();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.blue[700]),
              title: Text('Au ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : '...'}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                  Navigator.pop(context);
                  _showDateFilterDialog();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _startDate = null;
              _endDate = null;
              Navigator.pop(context);
            }),
            child: Text('Réinitialiser', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Appliquer', style: TextStyle(color: Colors.blue[700])),
          ),
        ],
      ),
    );
  }

  // Options d'exportation
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Exporter les données', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.description, color: Colors.blue[700]),
              title: Text('Export CSV'),
              subtitle: Text('Format tableur compatible Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportCSV();
              },
            ),
            ListTile(
              leading: Icon(Icons.description, color: Colors.green[700]),
              title: Text('Export Excel'),
              subtitle: Text('Format Excel natif (XLSX)'),
              onTap: () {
                Navigator.pop(context);
                _exportExcel();
              },
            ),
          ],
        ),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Réessayer'),
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue[700]),
          SizedBox(height: 16),
          Text('Chargement des commandes...', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('Aucune commande trouvée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: 8),
          if (_searchQuery.isNotEmpty || _startDate != null || _endDate != null || _selectedFilter != 'Toutes')
            Text('Essayez de modifier vos filtres de recherche', style: TextStyle(color: Colors.grey[500])),
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
            final productName = productSnapshot.hasData ? productSnapshot.data!.name : 'Chargement...';
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
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOrderDetails(order, productName),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commande #${order.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[700]),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 8),
              _buildInfoRow(Icons.person, order.customerName),
              _buildInfoRow(Icons.email, order.customerEmail),
              _buildInfoRow(Icons.shopping_cart, 'Quantité: ${order.quantity}'),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoRow(Icons.calendar_today, 
                      DateFormat('dd/MM/yyyy').format(order.orderDate)),
                  _buildInfoRow(Icons.access_time, 
                      DateFormat('HH:mm').format(order.orderDate)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmée':
        return Colors.green;
      case 'en attente':
        return Colors.orange;
      case 'expédiée':
        return Colors.blue;
      case 'annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }

  void _showOrderDetails(Order order, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de la commande', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Référence', order.id),
              _buildDetailItem('Produit', productName),
              _buildDetailItem('Client', order.customerName),
              _buildDetailItem('Email', order.customerEmail),
              _buildDetailItem('Adresse', order.customerAddress),
              _buildDetailItem('Quantité', order.quantity.toString()),
              _buildDetailItem('Date', DateFormat('dd/MM/yyyy à HH:mm').format(order.orderDate)),
              _buildDetailItem('Statut', order.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: Colors.blue[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);
    
    try {
      final orders = await OrderService().getOrders().first;
      List<List<dynamic>> csvData = [
        ['ID', 'Produit', 'Client', 'Email', 'Adresse', 'Quantité', 'Date', 'Statut']
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
          DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
          order.status
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/commandes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      // Utiliser file_saver pour proposer le téléchargement
      // await FileSaver.instance.saveFile('commandes', csv, 'csv', mimeType: MimeType.csv);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichier CSV exporté avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }
