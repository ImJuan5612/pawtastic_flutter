class PetHotel {
  final String id;
  final String name;
  final String description;
  final String address;
  final String imageUrl;
  final double rating;
  final double pricePerNight;
  final int availableRooms;
  final List<String> amenities;
  final List<String> rules;

  PetHotel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.imageUrl,
    required this.rating,
    required this.pricePerNight,
    required this.availableRooms,
    required this.amenities,
    required this.rules,
  });

  factory PetHotel.fromJson(Map<String, dynamic> json) {
    return PetHotel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      imageUrl: json['image_url'] as String,
      rating: (json['rating'] as num).toDouble(),
      pricePerNight: (json['price_per_night'] as num).toDouble(),
      availableRooms: json['available_rooms'] as int,
      amenities: List<String>.from(json['amenities'] as List),
      rules: List<String>.from(json['rules'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'image_url': imageUrl,
      'rating': rating,
      'price_per_night': pricePerNight,
      'available_rooms': availableRooms,
      'amenities': amenities,
      'rules': rules,
    };
  }
}
