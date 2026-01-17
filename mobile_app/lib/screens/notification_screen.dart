import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/notification_model.dart';
import 'package:intl/intl.dart';
import 'ticket_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle_outline),
            onPressed: () {
               FirebaseService().markNotificationsRead();
            },
            tooltip: 'Mark all read',
          )
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: FirebaseService().getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) return Center(child: Text('No notifications'));

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                leading: Icon(
                  n.type == 'COMMENT' ? Icons.message : Icons.info,
                  color: n.read ? Colors.grey : Colors.blue,
                ),
                title: Text(n.text, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(DateFormat('MMM dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(n.timestamp))),
                tileColor: n.read ? null : Colors.blue.withOpacity(0.05),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: n.ticketId)));
                },
              );
            },
          );
        },
      ),
    );
  }
}
