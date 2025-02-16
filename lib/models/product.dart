class Product {
  final int? id;
  final String name;
  final double unitPrice;
  final double wholesalePrice;
  final String barcode;

  Product({
    this.id,
    required this.name,
    required this.unitPrice,
    required this.wholesalePrice,
    required this.barcode,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unitPrice': unitPrice,
      'wholesalePrice': wholesalePrice,
      'barcode': barcode,
    };
  }

  // Create from Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      unitPrice: map['unitPrice'],
      wholesalePrice: map['wholesalePrice'],
      barcode: map['barcode'],
    );
  }

  Product copyWith({
    int? id,
    String? name,
    double? unitPrice,
    double? wholesalePrice,
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      barcode: barcode ?? this.barcode,
    );
  }
}