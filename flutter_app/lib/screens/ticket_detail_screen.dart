import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart'; // Added
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isSending = false;

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser!;
      
      final commentId = DateTime.now().millisecondsSinceEpoch.toString();

      final comment = Comment(
        id: commentId,
        ticketId: widget.ticketId,
        userId: user.uid,
        userName: user.name,
        userRole: user.role,
        text: _commentController.text.trim(),
        timestamp: DateTime.now(),
        clientId: user.clientId,
      );

      await _firestoreService.addComment(widget.ticketId, comment);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _updateStatus(TicketStatus status) async {
    try {
      await _firestoreService.updateTicketStatus(widget.ticketId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket status updated to ${status.value}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Widget _buildActionButtons(Ticket ticket, UserModel user) {
    bool isManufacturer = [UserRole.support_agent, UserRole.supervisor, UserRole.admin].contains(user.role);
    
    List<Widget> buttons = [];

    if (isManufacturer) {
      if (ticket.status == TicketStatus.newTicket) {
        buttons.add(_buildActionButton('Acknowledge', () => _updateStatus(TicketStatus.acknowledged), Colors.white, Colors.black, outline: true));
        buttons.add(const SizedBox(height: 8));
        buttons.add(_buildActionButton('Hold for Info', () => _updateStatus(TicketStatus.holdForInfo), Colors.white, Colors.black, outline: true));
      } else if (ticket.status == TicketStatus.acknowledged) {
         buttons.add(_buildActionButton('Progress Work', () => _updateStatus(TicketStatus.inProgress), Colors.white, Colors.black, outline: true));
      } else if (ticket.status == TicketStatus.inProgress) {
        buttons.add(_buildActionButton('Resolve Ticket', () => _updateStatus(TicketStatus.resolved), Colors.green, Colors.white));
         buttons.add(const SizedBox(height: 8));
        buttons.add(_buildActionButton('Hold for Info', () => _updateStatus(TicketStatus.holdForInfo), Colors.white, Colors.black, outline: true));
      } else if (ticket.status == TicketStatus.holdForInfo) {
         buttons.add(_buildActionButton('Reactivate', () => _updateStatus(TicketStatus.acknowledged), Colors.white, Colors.black, outline: true));
      } else if (ticket.status == TicketStatus.resolved) {
         buttons.add(_buildActionButton('Close Ticket', () => _updateStatus(TicketStatus.closed), Colors.white, Colors.black, outline: true));
      }
    } else {
      // Client
       if (ticket.status == TicketStatus.resolved) {
         buttons.add(_buildActionButton('Reopen Ticket', () => _updateStatus(TicketStatus.acknowledged), Colors.green, Colors.white));
       }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('MANAGEMENT ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ...buttons,
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color bgColor, Color textColor, {bool outline = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: outline ? 0 : 2,
        side: outline ? BorderSide(color: Colors.grey.shade300) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          children: [
            Text('Ticket #${widget.ticketId}', style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<Ticket?>(
        future: _firestoreService.getTicket(widget.ticketId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Ticket not found'));
          }

          final ticket = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              // Action Buttons Helper
              Widget buildActions() => _buildActionButtons(ticket, user);

              // Status Helper
              Widget buildStatus() => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                     const Text('TICKET LIFECYCLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                     const SizedBox(height: 16),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       decoration: BoxDecoration(
                         color: ticket.status.color,
                         borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ticket.status.color.withOpacity(0.5)),
                       ),
                       child: Text(ticket.status.value, style: TextStyle(color: ticket.status.textColor, fontWeight: FontWeight.bold)),
                     ),
                  ],
                ),
              );

              // Main Content (Description + Timeline + Input)
              Widget buildMainContent({bool scrollable = false}) {
                return Column(
                  children: [
                     // Description Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(ticket.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Text('reported in', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 4),
                                  Text(ticket.category.value, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text(DateFormat('MMM d, h:mm a').format(ticket.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(ticket.subject, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(ticket.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Timeline
                    if (scrollable)
                      const Text('Communication Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (scrollable)
                        const SizedBox(height: 16),
                    
                    StreamBuilder<List<Comment>>(
                      stream: _firestoreService.getComments(widget.ticketId),
                      builder: (context, commentSnapshot) {
                         if (!commentSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                         final comments = commentSnapshot.data!;

                         if (scrollable) {
                           // For mobile: just a column of comments
                           return Column(
                             children: comments.map((comment) {
                               bool isClient = comment.userRole == UserRole.client_user;
                               return Container(
                                 margin: const EdgeInsets.only(bottom: 12),
                                 padding: const EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                  color: isClient ? Colors.white : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isClient ? Colors.grey.shade200 : Colors.blue.shade100),
                                 ),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                         Text(DateFormat('h:mm a').format(comment.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                       ],
                                     ),
                                     const SizedBox(height: 8),
                                     Text(comment.text),
                                   ],
                                 ),
                               );
                             }).toList(),
                           );
                         } else {
                           // For desktop: scrollable list inside expanded
                           return Expanded(
                             child: ListView(
                               children: [
                                 const Text('Communication Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                 const SizedBox(height: 16),
                                 ...comments.map((comment) {
                                   bool isClient = comment.userRole == UserRole.client_user;
                                   return Container(
                                     margin: const EdgeInsets.only(bottom: 12),
                                     padding: const EdgeInsets.all(16),
                                     decoration: BoxDecoration(
                                      color: isClient ? Colors.white : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isClient ? Colors.grey.shade200 : Colors.blue.shade100),
                                     ),
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Row(
                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                           children: [
                                             Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                             Text(DateFormat('h:mm a').format(comment.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                           ],
                                         ),
                                         const SizedBox(height: 8),
                                         Text(comment.text),
                                       ],
                                     ),
                                   );
                                 }),
                               ],
                             ),
                           );
                         }
                      },
                    ),

                    // Comment Input (Always visible on mobile bottom, but here part of flow)
                    if (ticket.status != TicketStatus.closed) ...[
                      const SizedBox(height: 16),
                      Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _commentController,
                             decoration: const InputDecoration(
                              hintText: 'Write your reply...',
                              border: InputBorder.none,
                            ),
                            maxLines: 3,
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isSending ? null : _submitComment,
                                icon: const Icon(Icons.send, size: 16),
                                label: const Text('Reply'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32), // Bottom padding
                    ]
                  ],
                );
              }

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: buildMainContent(scrollable: false)), // Desktop uses Expanded logic
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: Column(children: [buildStatus(), const SizedBox(height: 16), buildActions()])),
                    ],
                  ),
                );
              } else {
                // Mobile Layout: Single Scroll View
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildStatus(),
                      const SizedBox(height: 16),
                      buildActions(),
                      if ([UserRole.support_agent, UserRole.supervisor, UserRole.admin].contains(user.role)) // Check if actions were rendered
                         const SizedBox(height: 16),
                      
                      buildMainContent(scrollable: true),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
