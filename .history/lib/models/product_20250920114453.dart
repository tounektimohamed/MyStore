class Product {
  String id;
  String name;
  String description;
  double price;
  String imageUrl;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.price,
    this.imageUrl,
    this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'stock': stock,
    };
  }

  static Product fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'],
      description: map['description'],
      price: map['price'].toDouble(),
      imageUrl: map['imageUrl'],
      stock: map['stock'],
    );
  }
}