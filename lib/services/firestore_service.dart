import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ville.dart';
import '../models/company.dart';
import '../models/bus.dart';
import '../models/trip.dart';
import '../models/seat.dart';
import '../models/user.dart';
import '../models/reservation.dart';
import '../models/search_history.dart';
import 'package:logger/logger.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // ✅ Collections avec les VRAIS noms de votre base de données
  static final CollectionReference _villesCollection = _db.collection('villes');
  static final CollectionReference _companiesCollection = _db.collection('companies');
  static final CollectionReference _busesCollection = _db.collection('buses');
  static final CollectionReference _tripsCollection = _db.collection('trips');
  static final CollectionReference _usersCollection = _db.collection('users');
  static final CollectionReference _reservationsCollection = _db.collection('reservations');
  static final CollectionReference _searchHistoryCollection = _db.collection('search_history');
  

  // ========== VILLES ==========
  
  /// Récupérer toutes les villes
  static Stream<List<Ville>> getVilles() {
    return _villesCollection
        .orderBy('name')  // ✅ Tri par le champ 'name' de votre DB
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ville.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Ajouter une nouvelle ville
  static Future<void> addVille(String name) async {
    try {
      await _villesCollection.add({
        'name': name  // ✅ Seul champ selon votre structure
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la ville: $e');
    }
  }

  // ========== COMPAGNIES ==========
  
  /// Récupérer toutes les compagnies
  static Stream<List<Company>> getCompanies() {
    return _companiesCollection
        .orderBy('name')  // ✅ Tri par le champ 'name' de votre DB
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Company.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Récupérer une compagnie par ID
  static Future<Company?> getCompanyById(String companyId) async {
    try {
      final doc = await _companiesCollection.doc(companyId).get();
      if (doc.exists) {
        return Company.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la compagnie: $e');
    }
  }

  // ========== BUS ==========
  
  /// Récupérer un bus par ID
  static Future<Bus?> getBusById(String busId) async {
    try {
      final doc = await _busesCollection.doc(busId).get();
      if (doc.exists) {
        return Bus.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du bus: $e');
    }
  }

  /// Récupérer tous les bus d'une compagnie
  static Stream<List<Bus>> getCompaniesBuses(String companyId) {
    return _busesCollection
        .where('companyId', isEqualTo: companyId)  // ✅ Champ 'companyId' de votre DB
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bus.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ========== VOYAGES ==========
  
  /// Rechercher des voyages selon vos critères exacts
  static Stream<List<Trip>> searchTrips({
    required String departureCity,
    required String arrivalCity,
    required DateTime travelDate,
  }) {
    // Calculer le début et la fin de la journée
    final startOfDay = DateTime(travelDate.year, travelDate.month, travelDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _tripsCollection
        .where('departureCity', isEqualTo: departureCity)    // ✅ Champ exact de votre DB
        .where('arrivalCity', isEqualTo: arrivalCity)        // ✅ Champ exact de votre DB
        .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('departureTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('departureTime')                            // ✅ Champ exact de votre DB
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Trip.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Récupérer un voyage par ID
  static Future<Trip?> getTripById(String tripId) async {
    try {
      final doc = await _tripsCollection.doc(tripId).get();
      if (doc.exists) {
        return Trip.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du voyage: $e');
    }
  }

  /// Récupérer les détails complets d'un voyage (voyage + bus + compagnie)
  static Future<Map<String, dynamic>> getTripDetails(String tripId) async {
    try {
      // Récupérer le voyage
      final tripDoc = await _tripsCollection.doc(tripId).get();
      if (!tripDoc.exists) {
        throw Exception('Voyage non trouvé');
      }

      final trip = Trip.fromFirestore(tripDoc.data() as Map<String, dynamic>, tripDoc.id);
      
      // Récupérer le bus avec le champ 'busId' de votre structure
      final busDoc = await _busesCollection.doc(trip.busId).get();
      if (!busDoc.exists) {
        throw Exception('Bus non trouvé');
      }
      final bus = Bus.fromFirestore(busDoc.data() as Map<String, dynamic>, busDoc.id);
      
      // Récupérer la compagnie avec le champ 'companyId' de votre structure
      final companyDoc = await _companiesCollection.doc(bus.companyId).get();
      if (!companyDoc.exists) {
        throw Exception('Compagnie non trouvée');
      }
      final company = Company.fromFirestore(companyDoc.data() as Map<String, dynamic>, companyDoc.id);

      return {
        'trip': trip,
        'bus': bus,
        'company': company,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  // ========== SIÈGES ==========
  
  /// Récupérer les sièges d'un voyage (sous-collection selon votre structure)
  static Stream<List<Seat>> getTripSeats(String tripId) {
    return _tripsCollection
        .doc(tripId)
        .collection('seats')  // ✅ Sous-collection exacte de votre DB
        .orderBy('seatNumber') // ✅ Champ 'seatNumber' de votre DB
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Seat.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Récupérer un siège spécifique
  static Future<Seat?> getSeat(String tripId, String seatId) async {
    try {
      final doc = await _tripsCollection
          .doc(tripId)
          .collection('seats')
          .doc(seatId)
          .get();
      
      if (doc.exists) {
        return Seat.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du siège: $e');
    }
  }

  /// Réserver un siège
  static Future<String> reserveSeat({
    required String tripId,
    required String seatId,
    required String userId,
  }) async {
    final batch = _db.batch();

    try {
      // Vérifier que le siège existe et n'est pas déjà réservé
      final seatDoc = await _tripsCollection
          .doc(tripId)
          .collection('seats')
          .doc(seatId)
          .get();

      if (!seatDoc.exists) {
        throw Exception('Siège non trouvé');
      }

      final seatData = seatDoc.data() as Map<String, dynamic>;
      if (seatData['isReserved'] == true) {
        throw Exception('Siège déjà réservé');
      }

      // Mettre à jour le siège dans la sous-collection
      final seatRef = _tripsCollection.doc(tripId).collection('seats').doc(seatId);
      batch.update(seatRef, {
        'isReserved': true,           // ✅ Champ exact de votre DB
        'reservedBy': userId,         // ✅ Champ exact de votre DB
        'reservedAt': Timestamp.now(), // ✅ Champ exact de votre DB
      });

      // Créer une réservation selon votre structure exacte
      final reservationRef = _reservationsCollection.doc();
      final seatNumber = seatData['seatNumber'] as int;
      
      batch.set(reservationRef, {
        'tripId': tripId,             // ✅ Champ exact de votre DB
        'seatNumber': seatNumber,     // ✅ Champ exact de votre DB
        'userId': userId,             // ✅ Champ exact de votre DB
        'reservedAt': Timestamp.now(), // ✅ Champ exact de votre DB
        'paymentStatus': 'pending',   // ✅ Champ exact de votre DB
      });

      // Décrémenter les sièges disponibles
      final tripRef = _tripsCollection.doc(tripId);
      batch.update(tripRef, {
        'availableSeats': FieldValue.increment(-1), // ✅ Champ exact de votre DB
      });

      await batch.commit();
      return reservationRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la réservation: $e');
    }
  }

  // ========== UTILISATEURS ==========
  
  /// Créer un utilisateur selon votre structure exacte
  static Future<void> createUser({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required String email,
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'uid': uid,                    // ✅ Champ exact de votre DB
        'fullName': fullName,          // ✅ Champ exact de votre DB  
        'phoneNumber': phoneNumber,    // ✅ Champ exact de votre DB
        'email': email,                // ✅ Champ exact de votre DB
        'createdAt': Timestamp.now(),  // ✅ Champ exact de votre DB
      });
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  /// Récupérer un utilisateur par ID
  static Future<User?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  // ========== RÉSERVATIONS ==========
  
  /// Récupérer les réservations d'un utilisateur
  static Stream<List<Reservation>> getUserReservations(String userId) {
    return _reservationsCollection
        .where('userId', isEqualTo: userId)  // ✅ Champ exact de votre DB
        .orderBy('reservedAt', descending: true) // ✅ Champ exact de votre DB
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Récupérer une réservation par ID
  static Future<Reservation?> getReservationById(String reservationId) async {
    try {
      final doc = await _reservationsCollection.doc(reservationId).get();
      if (doc.exists) {
        return Reservation.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la réservation: $e');
    }
  }

  /// Mettre à jour le statut de paiement d'une réservation
  static Future<void> updatePaymentStatus(String reservationId, String status) async {
    try {
      await _reservationsCollection.doc(reservationId).update({
        'paymentStatus': status,  // ✅ Champ exact de votre DB
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du paiement: $e');
    }
  }

  // ========== HISTORIQUE DES RECHERCHES ==========
  
  /// Sauvegarder une recherche dans l'historique
  static Future<void> saveSearch(SearchHistory search) async {
    try {
      await _searchHistoryCollection.add(search.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la recherche: $e');
    }
  }

  /// Récupérer l'historique des recherches
  static Stream<List<SearchHistory>> getSearchHistory({String? userId, int limit = 10}) {
    Query query = _searchHistoryCollection
        .orderBy('searchedAt', descending: true)
        .limit(limit);
    
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SearchHistory.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // ========== INITIALISATION ==========
  
  /// Initialiser les données par défaut (à appeler une seule fois)
  static Future<void> initializeDefaultData() async {
    try {
      final batch = _db.batch();
      final logger = Logger();

      // Vérifier si les données existent déjà
      final villesSnapshot = await _villesCollection.limit(1).get();
      if (villesSnapshot.docs.isNotEmpty) {
        logger.i('Les données existent déjà');
        return;
      }

      // Ajouter les villes par défaut selon votre structure
      final villes = ['Abidjan', 'Bouaké', 'Yamoussoukro', 'San-Pédro', 'Korhogo'];
      for (String villeName in villes) {
        final villeRef = _villesCollection.doc();
        batch.set(villeRef, {
          'name': villeName  // ✅ Structure exacte de votre DB
        });
      }

      await batch.commit();
      logger.i('Données par défaut initialisées avec succès');
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation: $e');
    }
  }

  // ========== MÉTHODES UTILITAIRES ==========
  
  /// Vérifier la connectivité à Firestore
  static Future<bool> testConnection() async {
    final logger = Logger();
    try {
      await _villesCollection.limit(1).get();
      return true;
    } catch (e) {
      logger.e('Erreur de connexion à Firestore: $e');
      return false;
    }
  }

  /// Compter le nombre de documents dans une collection
  static Future<int> countDocuments(String collectionName) async {
    try {
      final snapshot = await _db.collection(collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage: $e');
    }
  }
}