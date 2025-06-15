import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Réservation confirmée',
      'message': 'Votre réservation KKC001 pour Abidjan → Yamoussoukro a été confirmée.',
      'time': '2h',
      'type': 'success',
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'Rappel de voyage',
      'message': 'Votre voyage vers San-Pédro est prévu demain à 14h00.',
      'time': '5h',
      'type': 'reminder',
      'isRead': false,
    },
    {
      'id': '3',
      'title': 'Offre spéciale',
      'message': 'Profitez de 30% de réduction sur tous vos trajets ce week-end !',
      'time': '1j',
      'type': 'promotion',
      'isRead': true,
    },
    {
      'id': '4',
      'title': 'Changement d\'horaire',
      'message': 'L\'horaire de départ pour KKC002 a été modifié à 14h30.',
      'time': '2j',
      'type': 'warning',
      'isRead': true,
    },
    {
      'id': '5',
      'title': 'Nouveau service',
      'message': 'Découvrez notre nouveau service VIP avec sièges inclinables.',
      'time': '3j',
      'type': 'info',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFf32733).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFFf32733),
                  size: 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2d3748),
                  ),
                ),
                Text(
                  unreadCount > 0 
                    ? '$unreadCount nouvelle${unreadCount > 1 ? 's' : ''}'
                    : 'Toutes lues',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification['isRead'] = true;
                  }
                });
              },
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  color: Color(0xFFf32733),
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos notifications apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(_notifications[index]);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'];
    final type = notification['type'];
    
    Color getTypeColor() {
      switch (type) {
        case 'success':
          return Colors.green;
        case 'warning':
          return Colors.orange;
        case 'promotion':
          return Colors.purple;
        case 'reminder':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }
    
    IconData getTypeIcon() {
      switch (type) {
        case 'success':
          return Icons.check_circle_rounded;
        case 'warning':
          return Icons.warning_rounded;
        case 'promotion':
          return Icons.local_offer_rounded;
        case 'reminder':
          return Icons.schedule_rounded;
        default:
          return Icons.info_rounded;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFf32733).withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : const Color(0xFFf32733).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: getTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            getTypeIcon(),
            color: getTypeColor(),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                  color: const Color(0xFF2d3748),
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFf32733),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Il y a ${notification['time']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            setState(() {
              notification['isRead'] = true;
            });
          }
        },
      ),
    );
  }
}
