class Product {
  final int? id;
  final String name;
  final String description;
  final int categoryId;

  Product({this.id, required this.name, required this.description, required this.categoryId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
    };
  }

  // Optional: Method to create a Product from a map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      categoryId: map['categoryId'],
    );
  }
}
