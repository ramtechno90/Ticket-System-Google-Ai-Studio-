import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../models/enums.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/ticket_card.dart';
import 'new_ticket_screen.dart';
import 'ticket_detail_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TicketStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: firebaseService.getNotifications(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => !n.read).length;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                        constraints: BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(color: Colors.white, fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              );
            },
          )
        ],
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedStatus = null;
                      });
                    },
                  ),
                ),
                ...TicketStatus.values.map((status) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.value),
                      selected: _selectedStatus == status,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedStatus = selected ? status : null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Ticket>>(
              stream: firebaseService.getTickets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var tickets = snapshot.data ?? [];

                if (_selectedStatus != null) {
                  tickets = tickets.where((t) => t.status == _selectedStatus).toList();
                }

                if (tickets.isEmpty) {
                  return Center(child: Text('No tickets found.'));
                }
                return ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    return TicketCard(
                      ticket: tickets[index],
                      onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: tickets[index].id)),
                         );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: user?.role == UserRole.client_user
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NewTicketScreen()),
                );
              },
            )
          : null,
    );
  }
}
