import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/seat.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class SeatSelectionPage extends StatefulWidget {
  final Trip trip;

  const SeatSelectionPage({super.key, required this.trip});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> with TickerProviderStateMixin {
  List<Seat> _seats = [];
  Seat? _selectedSeat;
  bool _isLoading = true;
  bool _isReserving = false;
  String? _errorMessage;
  StreamSubscription<List<Seat>>? _seatsSubscription; // ✅ Gérer l'abonnement

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSeats();
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
    _seatsSubscription?.cancel(); // ✅ Annuler l'abonnement
    super.dispose();
  }

  void _loadSeats() async {
    final logger = Logger();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      logger.i('🔍 DEBUG: Chargement des sièges pour le voyage: ${widget.trip.id}');
      
      // ✅ Vérifier d'abord si les sièges existent avec un timeout
      final seatsSnapshot = await FirebaseFirestore.instance
          .collection('seats')
          .where('tripId', isEqualTo: widget.trip.id)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Timeout lors de la vérification des sièges');
            },
          );
      
      logger.i('🔍 DEBUG: ${seatsSnapshot.docs.length} sièges trouvés dans la base');
      
      if (seatsSnapshot.docs.isEmpty) {
        logger.i('⚠️ Aucun siège trouvé, initialisation...');
        setState(() {
          _errorMessage = 'Initialisation des sièges...';
        });
        
        // Initialiser les sièges si ils n'existent pas
        await FirestoreService.initializeSeatsForTrip(widget.trip.id, 50);
        logger.i('✅ Sièges initialisés');
        
        // Attendre un peu pour que les données se propagent
        await Future.delayed(const Duration(seconds: 1));
      }

      // ✅ Maintenant écouter les sièges SANS timeout (stream en temps réel)
      _seatsSubscription?.cancel(); // Annuler l'ancien abonnement s'il existe
      
      _seatsSubscription = FirestoreService.getTripSeats(widget.trip.id).listen(
        (seats) {
          logger.i('✅ ${seats.length} sièges chargés avec succès');
          if (mounted) {
            setState(() {
              _seats = seats;
              _isLoading = false;
              _errorMessage = null;
            });
          }
        },
        onError: (error) {
          logger.e('❌ Erreur chargement sièges: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erreur lors du chargement des sièges: $error';
            });
          }
        },
      );

    } catch (e) {
      logger.e('❌ Exception chargement sièges: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement des sièges: $e';
        });
      }
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

  void _onSeatSelected(Seat seat) {
    if (seat.isReserved) return;
    
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSeat = _selectedSeat?.id == seat.id ? null : seat;
    });
  }

  void _onReservePressed() async {
    if (_selectedSeat == null) {
      _showSnackBar('Veuillez sélectionner un siège');
      return;
    }

    // ✅ Vérifier si l'utilisateur est connecté
    if (!AuthService.isLoggedIn) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
            'Vous devez vous connecter pour effectuer une réservation.\n\nSouhaitez-vous vous connecter maintenant ?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf32733),
              ),
              child: const Text(
                'Se connecter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (shouldLogin == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      return;
    }

    // ✅ Utilisateur connecté, procéder à la réservation
    setState(() => _isReserving = true);
    HapticFeedback.lightImpact();

    try {
      await FirestoreService.reserveSeat(
        tripId: widget.trip.id,
        seatId: _selectedSeat!.id,
        userId: AuthService.currentUser!.uid,
      );

      if (mounted) {
        _showSnackBar('Siège réservé avec succès !', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors de la réservation: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isReserving = false);
      }
    }
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
        title: const Text(
          'Choisir un siège',
          style: TextStyle(
            color: Color(0xFF2d3748),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // ✅ Bouton de debug
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _showDebugInfo,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : Column(
                    children: [
                      _buildTripInfo(),
                      _buildSeatLegend(),
                      Expanded(child: _buildSeatMap()),
                      _buildBottomBar(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFf32733)),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Chargement des sièges...',
            style: const TextStyle(
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
            'Erreur de chargement',
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
          ElevatedButton.icon(
            onPressed: _loadSeats,
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
        ],
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug - Sélection de siège'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voyage ID: ${widget.trip.id}'),
              Text('De: ${widget.trip.departureCity}'),
              Text('Vers: ${widget.trip.arrivalCity}'),
              Text('Prix: ${widget.trip.price} FCFA'),
              const SizedBox(height: 16),
              const Text('État:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Chargement: $_isLoading'),
              Text('• Erreur: ${_errorMessage ?? "Aucune"}'),
              Text('• Nombre de sièges: ${_seats.length}'),
              Text('• Siège sélectionné: ${_selectedSeat?.seatNumber ?? "Aucun"}'),
              Text('• Stream actif: ${_seatsSubscription != null ? "Oui" : "Non"}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadSeats();
            },
            child: const Text('Recharger'),
          ),
        ],
      ),
    );
  }

  // ✅ Reste des méthodes identiques...
  Widget _buildTripInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFf32733).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
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
                  '${widget.trip.departureCity} → ${widget.trip.arrivalCity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF2d3748),
                  ),
                ),
                Text(
                  'Départ: ${_formatTime(widget.trip.departureTime)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${widget.trip.price.toStringAsFixed(0)} F CFA',
            style: const TextStyle(
              color: Color(0xFFf32733),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            color: Colors.grey.shade300,
            label: 'Disponible',
            icon: Icons.event_seat_rounded,
          ),
          _buildLegendItem(
            color: const Color(0xFFf32733),
            label: 'Sélectionné',
            icon: Icons.event_seat_rounded,
          ),
          _buildLegendItem(
            color: Colors.grey.shade600,
            label: 'Occupé',
            icon: Icons.event_seat_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatMap() {
    if (_seats.isEmpty) {
      return const Center(
        child: Text(
          'Aucun siège disponible',
          style: TextStyle(
            color: Color(0xFF718096),
            fontSize: 16,
          ),
        ),
      );
    }

    // Organiser les sièges par rangée (4 sièges par rangée: 2-2)
    final rows = <List<Seat>>[];
    for (int i = 0; i < _seats.length; i += 4) {
      rows.add(_seats.sublist(i, (i + 4).clamp(0, _seats.length)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avant du bus
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bus, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AVANT DU BUS',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Rangées de sièges
          ...rows.map((row) => _buildSeatRow(row)),
        ],
      ),
    );
  }

  Widget _buildSeatRow(List<Seat> rowSeats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sièges gauche (2 sièges)
          if (rowSeats.isNotEmpty) _buildSeat(rowSeats[0]),
          if (rowSeats.length > 1) const SizedBox(width: 8),
          if (rowSeats.length > 1) _buildSeat(rowSeats[1]),
          
          // Allée centrale
          const SizedBox(width: 40),
          
          // Sièges droite (2 sièges)
          if (rowSeats.length > 2) _buildSeat(rowSeats[2]),
          if (rowSeats.length > 3) const SizedBox(width: 8),
          if (rowSeats.length > 3) _buildSeat(rowSeats[3]),
        ],
      ),
    );
  }

  Widget _buildSeat(Seat seat) {
    final isSelected = _selectedSeat?.id == seat.id;
    final isOccupied = seat.isReserved;
    
    Color seatColor;
    if (isOccupied) {
      seatColor = Colors.grey.shade600;
    } else if (isSelected) {
      seatColor = const Color(0xFFf32733);
    } else {
      seatColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: () => _onSeatSelected(seat),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFf32733)
                : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat_rounded,
              color: isOccupied || isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            Text(
              seat.seatNumber.toString(),
              style: TextStyle(
                color: isOccupied || isSelected ? Colors.white : Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedSeat != null 
                        ? 'Siège ${_selectedSeat!.seatNumber} sélectionné'
                        : 'Aucun siège sélectionné',
                    style: TextStyle(
                      color: _selectedSeat != null 
                          ? const Color(0xFF2d3748)
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (_selectedSeat != null)
                    Text(
                      'Prix: ${widget.trip.price.toStringAsFixed(0)} F CFA',
                      style: const TextStyle(
                        color: Color(0xFFf32733),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedSeat != null && !_isReserving 
                    ? _onReservePressed 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf32733),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isReserving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Réserver',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
