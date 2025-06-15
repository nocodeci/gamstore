import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/firestore_service.dart';
import '/models/ville.dart';
import '/models/search_history.dart';
import '/models/trip.dart';
import 'package:logger/logger.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Home> with TickerProviderStateMixin {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final logger = Logger();

  int _selectedDateIndex = 0;
  bool _isLoading = false;
  
  // Streams pour les données Firestore avec vos vrais noms
  Stream<List<Ville>>? _villesStream;
  Stream<List<SearchHistory>>? _searchHistoryStream;
  List<Trip> _searchResults = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeStreams();
    _testFirestoreConnection();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
  }

  void _initializeStreams() {
    // ✅ Utilisation des vrais noms de collections
    _villesStream = FirestoreService.getVilles();
    _searchHistoryStream = FirestoreService.getSearchHistory(limit: 5);
  }

  /// Tester la connexion à Firestore
  void _testFirestoreConnection() async {
    final isConnected = await FirestoreService.testConnection();
    if (!isConnected) {
      _showCustomSnackBar('Erreur de connexion à la base de données');
    } else {
      logger.i('✅ Connexion à Firestore réussie');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // Générer les 7 prochains jours
  List<DateTime> get _nextSevenDays {
    return List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  }

  DateTime get _selectedDate {
    return _nextSevenDays[_selectedDateIndex];
  }

  void _swapLocations() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  /// Rechercher des bus et sauvegarder la recherche
  void _searchBuses() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      _showCustomSnackBar('Veuillez sélectionner les villes de départ et d\'arrivée');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      // Sauvegarder la recherche dans l'historique
      final search = SearchHistory(
        id: '', // Sera généré par Firestore
        fromCity: _fromController.text,
        toCity: _toController.text,
        travelDate: _selectedDate,
        searchedAt: DateTime.now(),
        // userId: currentUser?.uid, // Si vous avez l'authentification
      );

      await FirestoreService.saveSearch(search);

      // Rechercher les voyages disponibles avec vos vrais champs
      final tripsStream = FirestoreService.searchTrips(
        departureCity: _fromController.text,  // ✅ Champ 'departureCity' de votre DB
        arrivalCity: _toController.text,      // ✅ Champ 'arrivalCity' de votre DB
        travelDate: _selectedDate,
      );

      // Écouter les résultats
      tripsStream.listen((trips) {
        if (mounted) {
          setState(() {
            _searchResults = trips;
            _isLoading = false;
          });

          final dateString = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
          _showCustomSnackBar(
            'Recherche: ${_fromController.text} → ${_toController.text} le $dateString\n${trips.length} voyage(s) trouvé(s)',
            isSuccess: true,
          );
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showCustomSnackBar('Erreur lors de la recherche: $e');
      }
    }
  }

  void _showCustomSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade400 : const Color(0xFFf32733),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            color: const Color(0xFFf32733),
            onRefresh: () async {
              setState(() {
                _villesStream = FirestoreService.getVilles();
                _searchHistoryStream = FirestoreService.getSearchHistory(limit: 5);
              });
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildSoftHeader(),
                  const SizedBox(height: 24),
                  _buildModernSearchCard(),
                  const SizedBox(height: 32),
                  _buildSearchResults(),
                  const SizedBox(height: 32),
                  _buildRecentSearches(),
                  const SizedBox(height: 32),
                  _buildSoftSpecialOffers(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Afficher les résultats de recherche
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Résultats de recherche (${_searchResults.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2d3748),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _buildTripCard(_searchResults[index]);
          },
        ),
      ],
    );
  }

  /// Card pour afficher un voyage avec vos vrais champs
  Widget _buildTripCard(Trip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFf32733).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Color(0xFFf32733),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.departureCity} → ${trip.arrivalCity}', // ✅ Vos vrais champs
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF2d3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Départ: ${_formatDateTime(trip.departureTime)}', // ✅ Votre vrai champ
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${trip.price.toStringAsFixed(0)} F', // ✅ Votre vrai champ
                    style: const TextStyle(
                      color: Color(0xFFf32733),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'CFA',
                    style: TextStyle(
                      color: Color(0xFFf32733),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${trip.availableSeats} places disponibles', // ✅ Votre vrai champ
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Récupérer les détails complets du voyage
                    try {
                      final details = await FirestoreService.getTripDetails(trip.id);
                      _showCustomSnackBar(
                        'Voyage: ${details['company'].name} - ${details['bus'].busModel}',
                        isSuccess: true,
                      );
                    } catch (e) {
                      _showCustomSnackBar('Erreur: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf32733),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Réserver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Afficher les recherches récentes
  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recherches récentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2d3748),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Voir toutes les recherches
                },
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    color: Color(0xFFf32733),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<SearchHistory>>(
          stream: _searchHistoryStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFf32733)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Aucune recherche récente',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return _buildRecentSearchCard(snapshot.data![index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Card pour une recherche récente
  Widget _buildRecentSearchCard(SearchHistory search) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(search.searchedAt),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${search.fromCity} → ${search.toCity}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF2d3748),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Voyage: ${_formatDate(search.travelDate)}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Reprendre cette recherche
                _fromController.text = search.fromCity;
                _toController.text = search.toCity;
                _showCustomSnackBar('Recherche reprise', isSuccess: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf32733),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 5),
              ),
              child: const Text(
                'Reprendre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sélecteur de ville modifié pour utiliser vos vraies données
  void _showCityPicker(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf32733).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: Color(0xFFf32733),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Sélectionner une ville',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Ville>>(
                stream: _villesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFf32733),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade400,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement des villes',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _villesStream = FirestoreService.getVilles();
                              });
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  final villes = snapshot.data ?? [];

                  if (villes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.grey.shade400,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune ville disponible',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              // Initialiser les données par défaut
                              try {
                                await FirestoreService.initializeDefaultData();
                                setState(() {
                                  _villesStream = FirestoreService.getVilles();
                                });
                                _showCustomSnackBar('Villes initialisées', isSuccess: true);
                              } catch (e) {
                                _showCustomSnackBar('Erreur d\'initialisation: $e');
                              }
                            },
                            child: const Text('Initialiser les villes'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: villes.length,
                    itemBuilder: (context, index) {
                      final ville = villes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFf32733).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFf32733),
                              size: 16,
                            ),
                          ),
                          title: Text(
                            ville.name, // ✅ Votre vrai champ 'name'
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          onTap: () {
                            controller.text = ville.name; // ✅ Votre vrai champ 'name'
                            Navigator.pop(context);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes utilitaires
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Gardez vos autres méthodes de build existantes...
  Widget _buildSoftHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFf32733).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFf32733).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Color(0xFFf32733),
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KKC',
                  style: TextStyle(
                    color: Color(0xFF2d3748),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Transport & Réservation',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: [
          _buildLocationSection(),
          _buildDateSection(),
          _buildSearchButton(),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Ville de départ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.navigation_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCityPicker(_fromController),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fromController.text.isEmpty
                            ? 'Ville de départ'
                            : _fromController.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _fromController.text.isEmpty
                              ? Colors.grey.shade500
                              : const Color(0xFF2d3748),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bouton d'échange
              GestureDetector(
                onTap: _swapLocations,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          // Ligne de séparation
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 44),
            height: 1,
            color: Colors.grey.shade200,
          ),

          // Ville d'arrivée
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCityPicker(_toController),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _toController.text.isEmpty
                            ? 'Ville d\'arrivée'
                            : _toController.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _toController.text.isEmpty
                              ? Colors.grey.shade500
                              : const Color(0xFF2d3748),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    final days = _nextSevenDays;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Date de voyage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFf32733),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedDateIndex == 0
                      ? 'Aujourd\'hui'
                      : _selectedDateIndex == 1
                      ? 'Demain'
                      : 'Sélectionné',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMonthName(days[_selectedDateIndex]).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  Text(
                    days[_selectedDateIndex].year.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final date = days[index];
                      final isSelected = index == _selectedDateIndex;
                      final isToday = index == 0;
                      final isTomorrow = index == 1;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDateIndex = index;
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFf32733) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : const Color(0xFF2d3748),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isToday
                                    ? 'Auj'
                                    : isTomorrow
                                    ? 'Dem'
                                    : _getDayName(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    return months[date.month - 1];
  }

  String _getDayName(DateTime date) {
    const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    return days[date.weekday % 7];
  }

  Widget _buildSearchButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFf32733),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFf32733).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _searchBuses,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Rechercher des bus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSoftSpecialOffers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Offres spéciales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2d3748),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 3,
            itemBuilder: (context, index) {
              final offers = [
                {
                  'title': '🎉 Promotion Spéciale',
                  'subtitle': 'Jusqu\'à 40% de réduction\nsur tous vos trajets',
                  'color': const Color(0xFFf32733),
                  'bgColor': const Color(0xFFfff5f5),
                },
                {
                  'title': '✨ Offre VIP',
                  'subtitle': 'Voyagez en première classe\navec 25% de réduction',
                  'color': const Color(0xFF8B5CF6),
                  'bgColor': const Color(0xFFfaf5ff),
                },
                {
                  'title': '🚌 Nouveau Trajet',
                  'subtitle': 'Découvrez nos nouvelles\ndestinations',
                  'color': const Color(0xFF06B6D4),
                  'bgColor': const Color(0xFFf0fdff),
                },
              ];

              final offer = offers[index];

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: offer['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (offer['color'] as Color).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer['title'] as String,
                      style: TextStyle(
                        color: offer['color'] as Color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        offer['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: offer['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Découvrir',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}