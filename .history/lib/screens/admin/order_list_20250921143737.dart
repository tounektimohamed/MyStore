import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import 'dart:convert';
import 'dart:html' as html;

class AdminOrderList extends StatefulWidget {
  @override
  _AdminOrderListState createState() => _AdminOrderListState();
}

class _AdminOrderListState extends State<AdminOrderList> {
  final Map<String, Color> statusColors = {
    'En attente': Colors.orange,
    'Confirmée': Colors.blue,
    'Expédiée': Colors.purple,
    'Livrée': Colors.green,
    'Annulée': Colors.red,
  };

  final Map<String, IconData> statusIcons = {
    'En attente': Icons.access_time,
    'Confirmée': Icons.check_circle_outline,
    'Expédiée': Icons.local_shipping,
    'Livrée': Icons.verified,
    'Annulée': Icons.cancel,
  };

  // Variables pour les filtres
  String _searchQuery = '';
  String _selectedStatus = 'Tous';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  final List<String> _statusOptions = [
    'Tous',
    'En attente',
    'Confirmée',
    'Expédiée',
    'Livrée',
    'Annulée',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestion des Commandes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _isExporting ? null : _exportCSV,
            tooltip: 'Exporter en CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Section de filtres
          _buildFilterSection(),
          
          // Statistiques
          _buildStatsSection(),
          
          // Liste des commandes
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: OrderService().getOrders(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final orders = _filterOrders(snapshot.data!);
                return _buildOrderList(orders);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher par client, téléphone, produit ou ID...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              // Filtre par statut
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: _statusOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // Bouton filtre date
              OutlinedButton.icon(
                icon: Icon(Icons.calendar_today, size: 18),
                label: Text('Dates'),
                onPressed: _showDateFilterDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<List<Order>>(
      stream: OrderService().getOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        
        final orders = snapshot.data!;
        final filteredOrders = _filterOrders(orders);
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', filteredOrders.length.toString(), Colors.blue),
              _buildStatCard('En attente', 
                orders.where((o) => o.status == 'En attente').length.toString(), 
                Colors.orange
              ),
              _buildStatCard('Livrées', 
                orders.where((o) => o.status == 'Livrée').length.toString(), 
                Colors.green
              ),
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
          ),
        ],
      ),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    return orders.where((order) {
      // Filtre par recherche
      final matchesSearch = _searchQuery.isEmpty ||
          order.customerName.toLowerCase().contains(_searchQuery) ||
          order.customerPhone.toLowerCase().contains(_searchQuery) || // Changé: téléphone au lieu d'email
          order.id.toLowerCase().contains(_searchQuery);
      
      // Filtre par statut
      final matchesStatus = _selectedStatus == 'Tous' || order.status == _selectedStatus;
      
      // Filtre par date
      final matchesDate = _startDate == null || 
          (order.orderDate.isAfter(_startDate!) && 
           (_endDate == null || order.orderDate.isBefore(_endDate!.add(Duration(days: 1)))));
      
      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtrer par date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Du: ${_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Sélectionner'}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
                Navigator.pop(context);
                _showDateFilterDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Au: ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Sélectionner'}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
                Navigator.pop(context);
                _showDateFilterDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: Text('Réinitialiser'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);

    try {
      final orders = await OrderService().getOrders().first;
      final filteredOrders = _filterOrders(orders);

      if (filteredOrders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aucune donnée à exporter'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // En-têtes avec BOM UTF-8
      List<List<dynamic>> csvData = [
        [utf8.decode([0xEF, 0xBB, 0xBF])], // BOM UTF-8
        ['ID_Commande', 'Nom_Client', 'Telephone', 'Produit', 'Quantite', 'Prix_Total', 'Statut', 'Date_Commande', 'Adresse_Rue', 'Region',"CodePostal"] // Modifié
      ];

      // Récupération de tous les produits
      final productIds = filteredOrders.map((o) => o.productId).toSet();
      final products = <String, Product>{};
      
      for (var productId in productIds) {
        final product = await ProductService().getProduct(productId);
        if (product != null) {
          products[productId] = product;
        }
      }

      // Format de date pour Excel
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      
      // Construction des données
      for (var order in filteredOrders) {
        final product = products[order.productId];
        final productName = product?.name ?? 'Produit inconnu';
        final totalPrice = (product?.price ?? 0) * order.quantity;
        
        // CRITIQUE : Chaque valeur dans son propre élément de liste
        csvData.add([
          _escapeForExcel(order.id),
          _escapeForExcel(order.customerName),
          _escapeForExcel(order.customerPhone), // Changé: téléphone au lieu d'email
          _escapeForExcel(productName),
          order.quantity.toString(),
          _formatExcelNumber(totalPrice),
          _escapeForExcel(order.status),
          _escapeForExcel(dateFormat.format(order.orderDate)),
          _escapeForExcel(order.customerAddress),

          _escapeForExcel(order.customerRegion), // Ajouté: Region
          _escapeForExcel(order.CodePostal), // Ajouté: Region
        ]);
      }

      // Conversion en CSV avec délimiteur point-virgule
      final csv = const ListToCsvConverter(
        fieldDelimiter: ';', // Point-virgule pour Excel FR
        textDelimiter: '"',  // Guillemets pour tous les champs texte
        eol: '\r\n',         // Retour chariot Windows
      ).convert(csvData);

      // Nom du fichier
      final fileName = 'commandes_${DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now())}.csv';

      if (kIsWeb) {
        // Export web
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes], 'text/csv; charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Export mobile/desktop
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsString(csv, encoding: utf8);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier exporté: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'export: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // Fonction CRITIQUE pour l'échappement Excel
  String _escapeForExcel(String value) {
    // Nettoyer les retours à la ligne et tabulations
    String cleaned = value
        .replaceAll('\n', ' ')      // Remplace les sauts de ligne par des espaces
        .replaceAll('\r', ' ')      // Remplace les retours chariot
        .replaceAll('\t', ' ')      // Remplace les tabulations
        .replaceAll(';', ',')       // Remplace les points-virgules par des virgules
        .trim();

    // Si le champ contient des virgules ou guillemets, l'entourer de guillemets
    if (cleaned.contains(',') || cleaned.contains('"')) {
      return '"${cleaned.replaceAll('"', '""')}"';
    }
    
    return cleaned;
  }

  // Formatage des nombres
  String _formatExcelNumber(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blue[700],
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Chargement des commandes...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
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
          SizedBox(height: 20),
          Text(
            'Aucune commande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Les commandes de vos clients\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'Aucune commande ne correspond aux filtres',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return FutureBuilder<Product>(
          future: ProductService().getProduct(order.productId),
          builder: (context, productSnapshot) {
            final productName = productSnapshot.hasData
                ? productSnapshot.data!.name
                : 'Produit inconnu';
            
            return _buildOrderCard(order, productName);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, String productName) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${order.id.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Informations produit
            Text(
              productName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 12),
            
            // Informations client
            _buildInfoRow(Icons.person, 'Client: ${order.customerName}'),
            _buildInfoRow(Icons.phone, 'Téléphone: ${order.customerPhone}'), // Changé: téléphone au lieu d'email
            _buildInfoRow(Icons.location_on, 'Adresse (Rue): ${order.customerAddress}'), // Modifié

            _buildInfoRow(Icons.flag, 'Region: ${order.customerRegion}'), // Ajouté: Region
            _buildInfoRow(Icons.flag, 'Code Postal: ${order.customerC}'), // Ajouté: Region
            _buildInfoRow(Icons.shopping_cart, 'Quantité: ${order.quantity}'),
            _buildInfoRow(
              Icons.calendar_today,
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'
            ),
            
            SizedBox(height: 16),
            
            // Sélecteur de statut
            _buildStatusSelector(order),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = statusColors[status] ?? Colors.grey;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcons[status] ?? Icons.circle, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(Order order) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, size: 18, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            'Statut: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: order.status,
              isExpanded: true,
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
              items: <String>[
                'En attente',
                'Confirmée',
                'Expédiée',
                'Livrée',
                'Annulée'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        statusIcons[value],
                        size: 18,
                        color: statusColors[value],
                      ),
                      SizedBox(width: 8),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  OrderService().updateOrderStatus(order.id, newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}