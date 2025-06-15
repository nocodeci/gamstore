import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String busId;           // ✅ Selon votre DB
  final String departureCity;   // ✅ Selon votre DB
  final String arrivalCity;     // ✅ Selon votre DB
  final DateTime departureTime; // ✅ Selon votre DB
  final double price;           // ✅ Selon votre DB
  final int availableSeats;     // ✅ Selon votre DB

  Trip({
    required this.id,
    required this.busId,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.price,
    required this.availableSeats,
  });

  factory Trip.fromFirestore(Map<String, dynamic> data, String id) {
    return Trip(
      id: id,
      busId: data['busId'] ?? '',                    // ✅ Nom exact de votre DB
      departureCity: data['departureCity'] ?? '',    // ✅ Nom exact de votre DB
      arrivalCity: data['arrivalCity'] ?? '',        // ✅ Nom exact de votre DB
      departureTime: (data['departureTime'] as Timestamp).toDate(), // ✅ Nom exact de votre DB
      price: (data['price'] ?? 0).toDouble(),        // ✅ Nom exact de votre DB
      availableSeats: data['availableSeats'] ?? 0,   // ✅ Nom exact de votre DB
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'busId': busId,                                // ✅ Nom exact de votre DB
      'departureCity': departureCity,                // ✅ Nom exact de votre DB
      'arrivalCity': arrivalCity,                    // ✅ Nom exact de votre DB
      'departureTime': Timestamp.fromDate(departureTime), // ✅ Nom exact de votre DB
      'price': price,                                // ✅ Nom exact de votre DB
      'availableSeats': availableSeats,              // ✅ Nom exact de votre DB
    };
  }
}