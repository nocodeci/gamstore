class Ville {
  final String id;
  final String name;  // ✅ Seul champ selon votre DB

  Ville({
    required this.id,
    required this.name,
  });

  factory Ville.fromFirestore(Map<String, dynamic> data, String id) {
    return Ville(
      id: id,
      name: data['name'] ?? '',  // ✅ Nom exact de votre DB
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,  // ✅ Nom exact de votre DB
    };
  }
}