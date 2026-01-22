class Pet {
  final String id;
  final String name;
  final String species;
  final String breed;
  final int age;
  final double weight;
  final String userId;
  final String? gender;
  final String? imageUrl;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.weight,
    required this.userId,
    this.gender,
    this.imageUrl,
  });
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['nombre'] as String,
      species: json['especie'] as String,
      breed: json['raza'] as String,
      age: json['edad'] as int,
      weight: double.parse(json['peso'].toString()),
      userId: json['owner_id'] as String,
      gender: json['gender'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'especie': species,
      'raza': breed,
      'edad': age,
      'peso': weight,
      'owner_id': userId,
      'gender': gender,
      'image_url': imageUrl,
    };
  }
}
