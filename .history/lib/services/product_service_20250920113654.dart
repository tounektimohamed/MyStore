import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference productsCollection =
      FirebaseFirestore.instance.collection('products');

  Future<void> addProduct(Product product) async {
    await productsCollection.add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await productsCollection.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await productsCollection.doc(productId).delete();
  }

  Stream<List<Product>> getProducts() {
    return productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<Product> getProduct(String productId) async {
    var doc = await productsCollection.doc(productId).get();
    return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}