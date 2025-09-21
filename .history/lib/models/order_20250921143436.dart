class Order {
  String id;
  String productId;
  String customerName;
  String customerPhone; // Nouveau champ téléphone
  String customerAddress;
  String customerRegion; // Nouveau champ Region
  int quantity;
  DateTime orderDate;
  String status;

  Order({
    required this.id,
    required this.productId,
    required this.customerName,
    required this.customerPhone, // Ajouté
    required this.customerAddress,
    required this.customerRegion, // Ajouté
    required this.quantity,
    required this.orderDate,
    this.status = 'En attente',
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'customerName': customerName,
      'customerPhone': customerPhone, // Ajouté
      'customerAddress': customerAddress,
      'customerRegion': customerRegion, // Ajouté
      'CodePostal': C, // Ajouté

      'quantity': quantity,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
    };
  }

  static Order fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      productId: map['productId'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'], // Ajouté
      customerAddress: map['customerAddress'],
      customerRegion: map['customerRegion'], // Ajouté
      quantity: map['quantity'],
      orderDate: DateTime.parse(map['orderDate']),
      status: map['status'],
    );
  }
}
