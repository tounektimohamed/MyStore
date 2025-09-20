class Order {
  String id;
  String productId;
  String customerName;
  String customerEmail;
  String customerAddress;
  int quantity;
  DateTime orderDate;
  String status;

  Order({
    required this.id,
    required this.productId,
    required this.customerName,
    required this.customerEmail,
    this.customerAddress,
    this.quantity,
    this.orderDate,
    this.status = 'En attente',
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerAddress': customerAddress,
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
      customerEmail: map['customerEmail'],
      customerAddress: map['customerAddress'],
      quantity: map['quantity'],
      orderDate: DateTime.parse(map['orderDate']),
      status: map['status'],
    );
  }
}