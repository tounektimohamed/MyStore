import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderService {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('orders');

  Future<void> addOrder(Order order) async {
    await ordersCollection.add(order.toMap());
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await ordersCollection.doc(orderId).update({'status': status});
  }

  Stream<List<Order>> getOrders() {
    return ordersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}