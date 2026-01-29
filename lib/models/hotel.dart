class Hotel {
  final String id;
  final String name;
  final String address;
  final double price;
  final bool isAvailable;
  final int capacity;
  final DateTime? createdAt;

  Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
    required this.isAvailable,
    required this.capacity,
    this.createdAt,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      price: (json['price'] as num).toDouble(),
      isAvailable: json['is_available'] as bool,
      capacity: json['capacity'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
