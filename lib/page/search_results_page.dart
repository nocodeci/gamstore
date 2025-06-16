import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kkc/models/trip.dart';
import '../services/firestore_service.dart';
import '../models/trip_complete.dart'; // ✅ Nouveau modèle
import 'seat_selection_page.dart';
import 'package:logger/logger.dart';

class SearchResultsPage extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime travelDate;

  const SearchResultsPage({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.travelDate,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> with TickerProviderStateMixin {
  List<TripComplete> _trips = []; // ✅ Changé de Trip à TripComplete
  bool _isLoading = true;
  String _sortBy = 'price';
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchTrips();
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _searchTrips() async {
    final logger = Logger();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      logger.i('🔍 Recherche de voyages complets:');
      logger.i('   De: ${widget.fromCity}');
      logger.i('   Vers: ${widget.toCity}');
      logger.i('   Date: ${widget.travelDate}');

      // ✅ Utiliser la nouvelle méthode qui récupère tout
      final trips = await FirestoreService.searchTripsComplete(
        departureCity: widget.fromCity,
        arrivalCity: widget.toCity,
        date: widget.travelDate,
      );

      logger.i('✅ Voyages complets trouvés: ${trips.length}');
      
      if (mounted) {
        setState(() {
          _trips = trips;
          _sortTrips();
          _isLoading = false;
          _errorMessage = null;
        });
      }

      if (trips.isEmpty) {
        logger.i('⚠️ Aucun voyage trouvé pour ces critères');
      }

    } catch (e) {
      logger.e('❌ Exception lors de la recherche: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors de la recherche: $e';
        });
      }
    }
  }

  void _sortTrips() {
    switch (_sortBy) {
      case 'price':
        _trips.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'time':
        _trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
      case 'duration':
        getDuration(TripComplete trip) => 
            trip.arrivalTime.difference(trip.departureTime).inMinutes;
        _trips.sort((a, b) => getDuration(a).compareTo(getDuration(b)));
        break;
      case 'company':
        _trips.sort((a, b) => (a.companyName ?? '').compareTo(b.companyName ?? ''));
        break;
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onTripSelected(TripComplete trip) {
    HapticFeedback.lightImpact();
    
    // ✅ Convertir TripComplete en Trip pour la compatibilité
    final basicTrip = Trip(
      id: trip.id,
      busId: trip.busId,
      departureCity: trip.departureCity,
      arrivalCity: trip.arrivalCity,
      departureTime: trip.departureTime,
      arrivalTime: trip.arrivalTime,
      price: trip.price,
      availableSeats: trip.availableSeats,
      duration: trip.arrivalTime.difference(trip.departureTime),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionPage(trip: basicTrip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2d3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.fromCity} → ${widget.toCity}',
              style: const TextStyle(
                color: Color(0xFF2d3748),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              _formatDate(widget.travelDate),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          // Bouton de debug
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.grey.shade600),
            onPressed: _showDebugInfo,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort_rounded, color: Colors.grey.shade600),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortTrips();
              });
              HapticFeedback.selectionClick();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(Icons.attach_money_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Prix croissant'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'time',
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Heure de départ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duration',
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Durée du trajet'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'company',
                child: Row(
                  children: [
                    Icon(Icons.business_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Compagnie'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _trips.isEmpty
                    ? _buildEmptyState()
                    : _buildTripsList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFf32733)),
          SizedBox(height: 16),
          Text(
            'Recherche en cours...',
            style: TextStyle(
              color: Color(0xFF718096),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Erreur de recherche',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _searchTrips,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf32733),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _initializeTestData,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter des données test'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun voyage trouvé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun voyage disponible pour\n${widget.fromCity} → ${widget.toCity}\nle ${_formatDate(widget.travelDate)}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                label: const Text(
                  'Nouvelle recherche',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf32733),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _initializeTestData,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Créer voyage test'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return Column(
      children: [
        // En-tête avec nombre de résultats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_trips.length} voyage(s) trouvé(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2d3748),
                ),
              ),
              Text(
                'Trié par ${_getSortLabel()}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // Liste des voyages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _trips.length,
            itemBuilder: (context, index) {
              return _buildEnhancedTripCard(_trips[index], index);
            },
          ),
        ),
      ],
    );
  }

  // ✅ Nouvelle carte de voyage avec informations complètes
  Widget _buildEnhancedTripCard(TripComplete trip, int index) {
    final duration = trip.arrivalTime.difference(trip.departureTime);
    final durationText = '${duration.inHours}h${(duration.inMinutes % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onTripSelected(trip),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ En-tête avec vraies informations de compagnie
                Row(
                  children: [
                    // Logo de la compagnie
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFf32733).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: trip.companyLogo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                trip.companyLogo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.business,
                                  color: Color(0xFFf32733),
                                  size: 20,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.business,
                              color: Color(0xFFf32733),
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.companyName ?? 'Compagnie inconnue',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          if (trip.busNumber != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Bus ${trip.busNumber} • ${trip.busType ?? 'Standard'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Note de la compagnie et prix
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (trip.companyRating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  trip.companyRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${trip.price.toStringAsFixed(0)} F',
                          style: const TextStyle(
                            color: Color(0xFFf32733),
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
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
                
                // ✅ Informations du voyage améliorées
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Horaires avec trajet visuel
                      Row(
                        children: [
                          // Départ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatTime(trip.departureTime),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2d3748),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trip.departureCity,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Durée du voyage
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFf32733).withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  durationText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Arrivée
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(trip.arrivalTime),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2d3748),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trip.arrivalCity,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Places disponibles et bouton
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_seat_rounded,
                                color: trip.availableSeats > 10 
                                    ? Colors.green.shade600
                                    : trip.availableSeats > 0
                                        ? Colors.orange.shade600
                                        : Colors.red.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${trip.availableSeats} places disponibles',
                                style: TextStyle(
                                  color: trip.availableSeats > 10 
                                      ? Colors.green.shade600
                                      : trip.availableSeats > 0
                                          ? Colors.orange.shade600
                                          : Colors.red.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (trip.totalSeats != null) ...[
                                Text(
                                  ' / ${trip.totalSeats}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          ElevatedButton(
                            onPressed: trip.availableSeats > 0 
                                ? () => _onTripSelected(trip)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFf32733),
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              trip.availableSeats > 0 ? 'Choisir' : 'Complet',
                              style: TextStyle(
                                color: trip.availableSeats > 0 
                                    ? Colors.white 
                                    : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Méthodes de debug et test mises à jour
  void _showDebugInfo() async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de debug'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Recherche:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• De: ${widget.fromCity}'),
              Text('• Vers: ${widget.toCity}'),
              Text('• Date: ${_formatDate(widget.travelDate)}'),
              const SizedBox(height: 16),
              const Text('Résultats:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Voyages trouvés: ${_trips.length}'),
              const SizedBox(height: 16),
              if (_trips.isNotEmpty) ...[
                const Text('Détails des voyages:', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._trips.take(3).map((trip) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${trip.departureCity} → ${trip.arrivalCity}'),
                      Text('  Compagnie: ${trip.companyName ?? "Non définie"}'),
                      Text('  Bus: ${trip.busNumber ?? "Non défini"} (${trip.busType ?? "Standard"})'),
                      Text('  Prix: ${trip.price.toStringAsFixed(0)} FCFA'),
                      const SizedBox(height: 8),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _initializeTestData() async {
    try {
      // ✅ Utiliser la nouvelle méthode pour créer des données complètes
      await FirestoreService.initializeCompleteTestData();
      
      _showSnackBar('Données de test complètes créées !', isError: false);
      _searchTrips(); // Relancer la recherche
    } catch (e) {
      _showSnackBar('Erreur lors de la création des données test: $e');
    }
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price':
        return 'prix';
      case 'time':
        return 'heure';
      case 'duration':
        return 'durée';
      case 'company':
        return 'compagnie';
      default:
        return 'prix';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
