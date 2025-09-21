class Order {
  String id;
  String productId;
  String customerName;
  String customerPhone;
  String customerAddress;
  String customerRegion;
  String customerCodePostal;
  int quantity;
  DateTime orderDate;
  String status;

  Order({
    required this.id,
    required this.productId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerRegion,
    required this.customerCodePostal,
    required this.quantity,
    required this.orderDate,
    this.status = 'En attente',
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerRegion': customerRegion,
      'customerCodePostal': customerCodePostal,
      'quantity': quantity,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
    };
  }

  static Order fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      productId: map['productId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      customerRegion: map['customerRegion'] ?? '',
      customerCodePostal: map['customerCodePostal'] ?? '',
      quantity: (map['quantity'] is String) 
          ? int.tryParse(map['quantity']) ?? 0 
          : (map['quantity'] ?? 0).toInt(),
      orderDate: DateTime.parse(map['orderDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'En attente',
    );
  }
}