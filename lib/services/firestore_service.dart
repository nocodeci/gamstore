import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ville.dart';
import '../models/search_history.dart';
import '../models/trip.dart';
import '../models/trip_complete.dart'; // ✅ Nouveau modèle
import '../models/seat.dart';
import '../models/reservation.dart';
import '../models/user.dart' as app_user;
import 'package:logger/logger.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final logger = Logger();

  // ✅ NOUVELLES MÉTHODES POUR LES DONNÉES COMPLÈTES

  /// Rechercher des trajets avec toutes les informations (bus + compagnie)
  static Future<List<TripComplete>> searchTripsComplete({
    required String departureCity,
    required String arrivalCity,
    required DateTime date,
  }) async {
    final logger = Logger();
    try {
      // 1. Récupérer les trajets de base
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('departureCity', isEqualTo: departureCity)
          .where('arrivalCity', isEqualTo: arrivalCity)
          .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('departureTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      logger.i('🔍 ${tripsSnapshot.docs.length} trajets trouvés');

      // 2. Enrichir chaque trajet avec les données du bus et de la compagnie
      List<TripComplete> completeTrips = [];

      for (final tripDoc in tripsSnapshot.docs) {
        final tripData = tripDoc.data();
        final busId = tripData['busId'] as String?;
        final companyId = tripData['companyId'] as String?;

        // Récupérer les données du bus
        Map<String, dynamic>? busData;
        if (busId != null && busId.isNotEmpty) {
          try {
            final busDoc = await _firestore.collection('buses').doc(busId).get();
            if (busDoc.exists) {
              busData = busDoc.data();
            }
          } catch (e) {
            logger.w('⚠️ Erreur récupération bus $busId: $e');
          }
        }

        // Récupérer les données de la compagnie
        Map<String, dynamic>? companyData;
        if (companyId != null && companyId.isNotEmpty) {
          try {
            final companyDoc = await _firestore.collection('companies').doc(companyId).get();
            if (companyDoc.exists) {
              companyData = companyDoc.data();
            }
          } catch (e) {
            logger.w('⚠️ Erreur récupération compagnie $companyId: $e');
          }
        }

        // 3. Créer l'objet TripComplete avec toutes les données
        final completeTrip = TripComplete(
          id: tripDoc.id,
          departureCity: tripData['departureCity'] ?? '',
          arrivalCity: tripData['arrivalCity'] ?? '',
          departureTime: (tripData['departureTime'] as Timestamp).toDate(),
          arrivalTime: (tripData['arrivalTime'] as Timestamp).toDate(),
          price: (tripData['price'] ?? 0).toDouble(),
          availableSeats: tripData['availableSeats'] ?? 0,
          busId: busId ?? '',
          companyId: companyId ?? '',
          // Données du bus
          busNumber: busData?['number'],
          busType: busData?['type'],
          totalSeats: busData?['totalSeats'],
          // Données de la compagnie
          companyName: companyData?['name'],
          companyLogo: companyData?['logo'],
          companyRating: companyData?['rating']?.toDouble(),
        );

        completeTrips.add(completeTrip);
      }

      logger.i('✅ ${completeTrips.length} trajets complets récupérés');
      return completeTrips;

    } catch (e) {
      logger.e('❌ Erreur recherche trajets complets: $e');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Initialiser des données de test avec bus et compagnies
  static Future<void> initializeCompleteTestData() async {
    final logger = Logger();
    try {
      final batch = _firestore.batch();

      // 1. Créer des compagnies
      final companies = [
        {
          'id': 'company1',
          'name': 'Voyage Express',
          'logo': 'https://example.com/logo1.png',
          'rating': 4.5,
          'phone': '+237 123 456 789',
          'email': 'contact@voyage-express.cm',
        },
        {
          'id': 'company2', 
          'name': 'Cameroon Transport',
          'logo': 'https://example.com/logo2.png',
          'rating': 4.2,
          'phone': '+237 987 654 321',
          'email': 'info@cameroon-transport.cm',
        },
        {
          'id': 'company3',
          'name': 'KKC Transport',
          'logo': 'https://example.com/logo3.png',
          'rating': 4.0,
          'phone': '+237 555 123 456',
          'email': 'service@kkc-transport.cm',
        },
      ];

      for (final company in companies) {
        final companyRef = _firestore.collection('companies').doc(company['id'] as String);
        batch.set(companyRef, company);
      }

      // 2. Créer des bus
      final buses = [
        {
          'id': 'bus1',
          'number': 'VE-001',
          'type': 'VIP',
          'totalSeats': 50,
          'companyId': 'company1',
          'features': ['Climatisation', 'WiFi', 'Toilettes', 'Prises USB'],
        },
        {
          'id': 'bus2',
          'number': 'CT-002', 
          'type': 'Standard',
          'totalSeats': 45,
          'companyId': 'company2',
          'features': ['Climatisation', 'Musique'],
        },
        {
          'id': 'bus3',
          'number': 'KKC-003',
          'type': 'Confort',
          'totalSeats': 48,
          'companyId': 'company3',
          'features': ['Climatisation', 'WiFi', 'Télévision'],
        },
        {
          'id': 'bus4',
          'number': 'VE-004',
          'type': 'VIP',
          'totalSeats': 50,
          'companyId': 'company1',
          'features': ['Climatisation', 'WiFi', 'Toilettes', 'Prises USB', 'Sièges inclinables'],
        },
      ];

      for (final bus in buses) {
        final busRef = _firestore.collection('buses').doc(bus['id'] as String);
        batch.set(busRef, bus);
      }

      // 3. Créer des trajets avec références aux bus et compagnies
      final now = DateTime.now();
      final trips = [
        // Trajets pour aujourd'hui
        {
          'departureCity': 'Douala',
          'arrivalCity': 'Yaoundé',
          'departureTime': Timestamp.fromDate(now.add(const Duration(hours: 2))),
          'arrivalTime': Timestamp.fromDate(now.add(const Duration(hours: 6))),
          'price': 2500.0,
          'availableSeats': 45,
          'busId': 'bus1',
          'companyId': 'company1',
        },
        {
          'departureCity': 'Yaoundé',
          'arrivalCity': 'Douala',
          'departureTime': Timestamp.fromDate(now.add(const Duration(hours: 4))),
          'arrivalTime': Timestamp.fromDate(now.add(const Duration(hours: 8))),
          'price': 2500.0,
          'availableSeats': 40,
          'busId': 'bus2',
          'companyId': 'company2',
        },
        {
          'departureCity': 'Douala',
          'arrivalCity': 'Bafoussam',
          'departureTime': Timestamp.fromDate(now.add(const Duration(hours: 1))),
          'arrivalTime': Timestamp.fromDate(now.add(const Duration(hours: 6))),
          'price': 3500.0,
          'availableSeats': 42,
          'busId': 'bus3',
          'companyId': 'company3',
        },
        // Trajets pour demain
        {
          'departureCity': 'Douala',
          'arrivalCity': 'Yaoundé',
          'departureTime': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 8))),
          'arrivalTime': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 12))),
          'price': 2800.0,
          'availableSeats': 48,
          'busId': 'bus4',
          'companyId': 'company1',
        },
        {
          'departureCity': 'Yaoundé',
          'arrivalCity': 'Bafoussam',
          'departureTime': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 10))),
          'arrivalTime': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 15))),
          'price': 3200.0,
          'availableSeats': 38,
          'busId': 'bus2',
          'companyId': 'company2',
        },
      ];

      for (final trip in trips) {
        final tripRef = _firestore.collection('trips').doc();
        batch.set(tripRef, {
          'id': tripRef.id,
          ...trip,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      logger.i('✅ Données complètes de test initialisées');

      // 4. Initialiser les sièges pour chaque voyage
      final tripsSnapshot = await _firestore.collection('trips').get();
      for (final tripDoc in tripsSnapshot.docs) {
        final tripData = tripDoc.data();
        final busId = tripData['busId'] as String?;
        
        // Récupérer le nombre de sièges du bus
        int totalSeats = 50; // Par défaut
        if (busId != null) {
          try {
            final busDoc = await _firestore.collection('buses').doc(busId).get();
            if (busDoc.exists) {
              totalSeats = busDoc.data()?['totalSeats'] ?? 50;
            }
          } catch (e) {
            logger.w('⚠️ Erreur récupération sièges bus: $e');
          }
        }
        
        await initializeSeatsForTrip(tripDoc.id, totalSeats);
      }

      logger.i('✅ Sièges initialisés pour tous les voyages');

    } catch (e) {
      logger.e('❌ Erreur initialisation données complètes: $e');
      throw Exception('Erreur lors de l\'initialisation: $e');
    }
  }

  /// Ajouter des villes de test
  static Future<void> addTestCities() async {
    try {
      final batch = _firestore.batch();
      
      final villes = [
        'Douala', 'Yaoundé', 'Bafoussam', 'Bamenda', 'Garoua',
        'Maroua', 'Ngaoundéré', 'Bertoua', 'Ebolowa', 'Kribi'
      ];
      
      for (final ville in villes) {
        final villeRef = _firestore.collection('villes').doc(); // ✅ Corrigé: "Ville" au lieu de "villes"
        batch.set(villeRef, {
          'id': villeRef.id,
          'name': ville,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      Logger().i('✅ Villes de test ajoutées');
    } catch (e) {
      Logger().e('❌ Erreur ajout villes: $e');
      throw Exception('Erreur lors de l\'ajout des villes: $e');
    }
  }

  // ✅ MÉTHODES EXISTANTES MISES À JOUR

  /// Récupérer TOUS les voyages (pour debug)
  static Future<List<Trip>> getAllTrips() async {
    final logger = Logger();
    try {
      final snapshot = await _firestore.collection('trips').get();
      return snapshot.docs.map((doc) => Trip.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      logger.e('❌ Erreur lors de la récupération de tous les voyages: $e');
      return [];
    }
  }

  /// Recherche flexible (sans contrainte de date stricte)
  static Stream<List<Trip>> searchTripsFlexible({
    required String departureCity,
    required String arrivalCity,
    required DateTime travelDate,
  }) {
    final logger = Logger();
    logger.i('🔍 Recherche flexible:');
    logger.i('   De: $departureCity');
    logger.i('   Vers: $arrivalCity');
    logger.i('   Date: $travelDate');

    final exactQuery = _firestore
        .collection('trips')
        .where('departureCity', isEqualTo: departureCity)
        .where('arrivalCity', isEqualTo: arrivalCity);

    return exactQuery.snapshots().map((snapshot) {
      final trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc.data(), doc.id)).toList();
      logger.i('✅ Voyages trouvés (recherche flexible): ${trips.length}');
      
      final filteredTrips = trips.where((trip) {
        final tripDate = DateTime(
          trip.departureTime.year,
          trip.departureTime.month,
          trip.departureTime.day,
        );
        final searchDate = DateTime(
          travelDate.year,
          travelDate.month,
          travelDate.day,
        );
        return tripDate.isAtSameMomentAs(searchDate) || 
               tripDate.isAfter(searchDate);
      }).toList();
      
      logger.i('✅ Voyages après filtrage par date: ${filteredTrips.length}');
      return filteredTrips;
    });
  }

  /// Créer un voyage de test
  static Future<void> createTestTrip({
    required String departureCity,
    required String arrivalCity,
    required DateTime travelDate,
  }) async {
    try {
      final tripRef = _firestore.collection('trips').doc();
      final logger = Logger();
      
      final departureTime = DateTime(
        travelDate.year,
        travelDate.month,
        travelDate.day,
        8 + (DateTime.now().millisecond % 12),
        (DateTime.now().millisecond % 4) * 15,
      );

      final arrivalTime = departureTime.add(Duration(hours: 3 + (DateTime.now().millisecond % 5)));

      await tripRef.set({
        'id': tripRef.id,
        'departureCity': departureCity,
        'arrivalCity': arrivalCity,
        'departureTime': Timestamp.fromDate(departureTime),
        'arrivalTime': Timestamp.fromDate(arrivalTime), // ✅ Ajouté
        'price': 2500.0 + (DateTime.now().millisecond % 2000),
        'duration': 3 + (DateTime.now().millisecond % 5),
        'availableSeats': 45 - (DateTime.now().millisecond % 10),
        'busId': 'bus1', // ✅ Ajouté
        'companyId': 'company1', // ✅ Ajouté
        'createdAt': FieldValue.serverTimestamp(),
      });

      await initializeSeatsForTrip(tripRef.id, 50);
      
      logger.i('✅ Voyage test créé: $departureCity → $arrivalCity');
    } catch (e) {
      throw Exception('Erreur lors de la création du voyage test: $e');
    }
  }

  static Future<bool> testConnection() async {
    final logger = Logger();
    try {
      await _firestore.collection('test').limit(1).get().timeout(const Duration(seconds: 2));
      return true;
    } catch (e) {
      logger.i('Erreur de connexion Firestore: $e');
      return false;
    }
  }

  static Future<void> createUser({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  static Future<app_user.User?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  static Stream<List<Seat>> getTripSeats(String tripId) {
    return _firestore
        .collection('seats')
        .where('tripId', isEqualTo: tripId)
        .orderBy('seatNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Seat.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  static Future<void> reserveSeat({
    required String tripId,
    required String seatId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final seatDoc = await transaction.get(
          _firestore.collection('seats').doc(seatId)
        );
        
        if (!seatDoc.exists) {
          throw Exception('Siège introuvable');
        }
        
        final seatData = seatDoc.data()!;
        if (seatData['isOccupied'] == true) {
          throw Exception('Ce siège est déjà réservé');
        }

        transaction.update(
          _firestore.collection('seats').doc(seatId),
          {
            'isOccupied': true,
            'reservedBy': userId,
            'reservedAt': FieldValue.serverTimestamp(),
          },
        );

        final reservationRef = _firestore.collection('reservations').doc();
        transaction.set(reservationRef, {
          'id': reservationRef.id,
          'tripId': tripId,
          'seatId': seatId,
          'userId': userId,
          'seatNumber': seatData['seatNumber'],
          'paymentStatus': 'pending',
          'reservedAt': FieldValue.serverTimestamp(),
        });

        final tripRef = _firestore.collection('trips').doc(tripId);
        transaction.update(tripRef, {
          'availableSeats': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Exception('Erreur lors de la réservation: $e');
    }
  }

  static Stream<List<Reservation>> getUserReservations(String userId) {
    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('reservedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  static Future<void> initializeSeatsForTrip(String tripId, int totalSeats) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 1; i <= totalSeats; i++) {
        final seatRef = _firestore.collection('seats').doc();
        batch.set(seatRef, {
          'id': seatRef.id,
          'tripId': tripId,
          'seatNumber': i.toString().padLeft(2, '0'),
          'isOccupied': false,
          'reservedBy': null,
          'reservedAt': null,
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation des sièges: $e');
    }
  }

  // ✅ CORRIGÉ: Collection "Ville" au lieu de "villes"
  static Stream<List<Ville>> getVilles() {
    return _firestore
        .collection('villes') // ✅ Changé de "villes" à "Ville"
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ville.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  static Stream<List<SearchHistory>> getSearchHistory({int limit = 10}) {
    return _firestore
        .collection('search_history')
        .orderBy('searchedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SearchHistory.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  static Future<void> saveSearch(SearchHistory search) async {
    try {
      final docRef = _firestore.collection('search_history').doc();
      await docRef.set({
        'id': docRef.id,
        'fromCity': search.fromCity,
        'toCity': search.toCity,
        'travelDate': Timestamp.fromDate(search.travelDate),
        'searchedAt': Timestamp.fromDate(search.searchedAt),
        'userId': search.userId,
      });
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la recherche: $e');
    }
  }

  static Stream<List<Trip>> searchTrips({
    required String departureCity,
    required String arrivalCity,
    required DateTime travelDate,
  }) {
    final startOfDay = DateTime(travelDate.year, travelDate.month, travelDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('trips')
        .where('departureCity', isEqualTo: departureCity)
        .where('arrivalCity', isEqualTo: arrivalCity)
        .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('departureTime', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Trip.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  static Future<Map<String, dynamic>> getTripDetails(String tripId) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) {
        throw Exception('Voyage introuvable');
      }

      final tripData = tripDoc.data()!;
      
      // ✅ Récupérer les vraies données de compagnie et bus
      Map<String, dynamic> companyData = {'name': 'Compagnie inconnue'};
      Map<String, dynamic> busData = {'busModel': 'Bus Standard'};
      
      final companyId = tripData['companyId'] as String?;
      final busId = tripData['busId'] as String?;
      
      if (companyId != null) {
        try {
          final companyDoc = await _firestore.collection('companies').doc(companyId).get();
          if (companyDoc.exists) {
            companyData = companyDoc.data()!;
          }
        } catch (e) {
          Logger().w('⚠️ Erreur récupération compagnie: $e');
        }
      }
      
      if (busId != null) {
        try {
          final busDoc = await _firestore.collection('buses').doc(busId).get();
          if (busDoc.exists) {
            busData = busDoc.data()!;
          }
        } catch (e) {
          Logger().w('⚠️ Erreur récupération bus: $e');
        }
      }

      return {
        'trip': Trip.fromFirestore(tripData, tripDoc.id),
        'company': companyData,
        'bus': busData,
      };

    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  static Future<void> initializeDefaultData() async {
    final logger = Logger();
    try {
      // ✅ CORRIGÉ: Vérifier la collection "Ville"
      final villesSnapshot = await _firestore.collection('villes').limit(1).get();
      if (villesSnapshot.docs.isNotEmpty) {
        logger.i('Les données existent déjà');
        return;
      }

      final batch = _firestore.batch();

      // Ajouter des villes par défaut
      final villes = [
        'Douala', 'Yaoundé', 'Bafoussam', 'Bamenda', 'Garoua',
        'Maroua', 'Ngaoundéré', 'Bertoua', 'Ebolowa', 'Kribi'
      ];

      for (final ville in villes) {
        // ✅ CORRIGÉ: Collection "Ville"
        final villeRef = _firestore.collection('villes').doc();
        batch.set(villeRef, {
          'id': villeRef.id,
          'name': ville,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Ajouter plusieurs voyages d'exemple pour différentes dates
      final now = DateTime.now();
      
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final travelDate = now.add(Duration(days: dayOffset));
        
        final tripsData = [
          {
            'departureCity': 'Douala',
            'arrivalCity': 'Yaoundé',
            'departureTime': Timestamp.fromDate(travelDate.copyWith(hour: 8, minute: 0)),
            'arrivalTime': Timestamp.fromDate(travelDate.copyWith(hour: 12, minute: 0)), // ✅ Ajouté
            'price': 2500.0,
            'duration': 4,
            'availableSeats': 45,
            'busId': 'default_bus', // ✅ Ajouté
            'companyId': 'default_company', // ✅ Ajouté
          },
          {
            'departureCity': 'Yaoundé',
            'arrivalCity': 'Douala',
            'departureTime': Timestamp.fromDate(travelDate.copyWith(hour: 14, minute: 30)),
            'arrivalTime': Timestamp.fromDate(travelDate.copyWith(hour: 18, minute: 30)), // ✅ Ajouté
            'price': 2500.0,
            'duration': 4,
            'availableSeats': 42,
            'busId': 'default_bus', // ✅ Ajouté
            'companyId': 'default_company', // ✅ Ajouté
          },
          {
            'departureCity': 'Yaoundé',
            'arrivalCity': 'Bafoussam',
            'departureTime': Timestamp.fromDate(travelDate.copyWith(hour: 10, minute: 30)),
            'arrivalTime': Timestamp.fromDate(travelDate.copyWith(hour: 15, minute: 30)), // ✅ Ajouté
            'price': 3000.0,
            'duration': 5,
            'availableSeats': 38,
            'busId': 'default_bus', // ✅ Ajouté
            'companyId': 'default_company', // ✅ Ajouté
          },
          {
            'departureCity': 'Bafoussam',
            'arrivalCity': 'Yaoundé',
            'departureTime': Timestamp.fromDate(travelDate.copyWith(hour: 16, minute: 0)),
            'arrivalTime': Timestamp.fromDate(travelDate.copyWith(hour: 21, minute: 0)), // ✅ Ajouté
            'price': 3000.0,
            'duration': 5,
            'availableSeats': 40,
            'busId': 'default_bus', // ✅ Ajouté
            'companyId': 'default_company', // ✅ Ajouté
          },
          {
            'departureCity': 'Douala',
            'arrivalCity': 'Bamenda',
            'departureTime': Timestamp.fromDate(travelDate.copyWith(hour: 9, minute: 0)),
            'arrivalTime': Timestamp.fromDate(travelDate.copyWith(hour: 15, minute: 0)), // ✅ Ajouté
            'price': 4000.0,
            'duration': 6,
            'availableSeats': 35,
            'busId': 'default_bus', // ✅ Ajouté
            'companyId': 'default_company', // ✅ Ajouté
          },
        ];

        for (final tripData in tripsData) {
          final tripRef = _firestore.collection('trips').doc();
          batch.set(tripRef, {
            'id': tripRef.id,
            ...tripData,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      // Initialiser les sièges pour chaque voyage
      final tripsSnapshot = await _firestore.collection('trips').get();
      for (final tripDoc in tripsSnapshot.docs) {
        await initializeSeatsForTrip(tripDoc.id, 50);
      }

      logger.i('✅ Données par défaut initialisées avec succès');
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation des données: $e');
    }
  }
}
