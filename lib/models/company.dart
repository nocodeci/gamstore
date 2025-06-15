class Company {
  final String id;
  final String name;     // ✅ Selon votre DB
  final String logoUrl;  // ✅ Selon votre DB
  final String contact;  // ✅ Selon votre DB

  Company({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.contact,
  });

  factory Company.fromFirestore(Map<String, dynamic> data, String id) {
    return Company(
      id: id,
      name: data['name'] ?? '',        // ✅ Nom exact de votre DB
      logoUrl: data['logoUrl'] ?? '',  // ✅ Nom exact de votre DB
      contact: data['contact'] ?? '',  // ✅ Nom exact de votre DB
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,        // ✅ Nom exact de votre DB
      'logoUrl': logoUrl,  // ✅ Nom exact de votre DB
      'contact': contact,  // ✅ Nom exact de votre DB
    };
  }
}