import 'package:cloud_firestore/cloud_firestore.dart';

class TripComplete {
  final String id;
  final String departureCity;
  final String arrivalCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final int availableSeats;
  final String busId;
  final String companyId;
  
  // ✅ Informations du bus
  final String? busNumber;
  final String? busType;
  final int? totalSeats;
  
  // ✅ Informations de la compagnie
  final String? companyName;
  final String? companyLogo;
  final double? companyRating;

  TripComplete({
    required this.id,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.busId,
    required this.companyId,
    this.busNumber,
    this.busType,
    this.totalSeats,
    this.companyName,
    this.companyLogo,
    this.companyRating,
  });

  factory TripComplete.fromFirestore(Map<String, dynamic> data, String id) {
    return TripComplete(
      id: id,
      departureCity: data['departureCity'] ?? '',
      arrivalCity: data['arrivalCity'] ?? '',
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      arrivalTime: (data['arrivalTime'] as Timestamp).toDate(),
      price: (data['price'] ?? 0).toDouble(),
      availableSeats: data['availableSeats'] ?? 0,
      busId: data['busId'] ?? '',
      companyId: data['companyId'] ?? '',
      // Données du bus
      busNumber: data['busNumber'],
      busType: data['busType'],
      totalSeats: data['totalSeats'],
      // Données de la compagnie
      companyName: data['companyName'],
      companyLogo: data['companyLogo'],
      companyRating: data['companyRating']?.toDouble(),
    );
  }
}
