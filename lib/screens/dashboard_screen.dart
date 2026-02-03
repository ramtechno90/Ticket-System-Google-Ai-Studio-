import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/ticket_model.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/stats_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  TicketStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final firestoreService = FirestoreService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isClient = user.role == UserRole.client_user;
    final isManufacturer = !isClient;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // gray-50
      appBar: AppBar(
        title: Text(isClient
          ? '${user.clientName ?? "Client"} Dashboard' 
          : 'Manufacturer Support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Ticket>>(
        stream: firestoreService.getTickets(user),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTickets = snapshot.data ?? [];
          
          // Client-side filtering
          final filteredTickets = allTickets.where((ticket) {
            final matchesSearch = ticket.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                ticket.id.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesStatus = _filterStatus == null || ticket.status == _filterStatus;
            return matchesSearch && matchesStatus;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Stats Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TicketStatus.values.map((status) {
                        final count = allTickets.where((t) => t.status == status).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: StatsCard(
                            title: status.value,
                            value: count.toString(),
                            color: status.color,
                            textColor: status.textColor,
                            isActive: _filterStatus == status,
                            onTap: () {
                              setState(() {
                                if (_filterStatus == status) {
                                  _filterStatus = null;
                                } else {
                                  _filterStatus = status;
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by ID or Subject...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Ticket ListHeader
              if (filteredTickets.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text("No tickets found", style: TextStyle(color: Colors.grey))),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ticket = filteredTickets[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              context.push('/ticket/${ticket.id}');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ticket.id,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ticket.subject,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ticket.clientName,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ticket.status.color,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: ticket.status.color.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      ticket.status.value,
                                      style: TextStyle(
                                        color: ticket.status.textColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredTickets.length,
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isClient) {
            context.push('/new-ticket');
          } else {
            // Navigate to create client screen for manufacturers
             context.push('/create-client');
          }
        },
        icon: Icon(isClient ? Icons.add : Icons.person_add),
        label: Text(isClient ? 'New Ticket' : 'Add Client'),
      ),
    );
  }
}
