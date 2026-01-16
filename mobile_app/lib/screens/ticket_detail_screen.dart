import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/enums.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/comment_item.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  TicketDetailScreen({required this.ticketId});

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;
    _firebaseService.addComment(widget.ticketId, _commentController.text.trim());
    _commentController.clear();
  }

  void _updateStatus(TicketStatus status) {
    _firebaseService.updateTicketStatus(widget.ticketId, status);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: Text('Ticket Details')),
      body: StreamBuilder<Ticket?>(
        stream: _firebaseService.getTicketById(widget.ticketId),
        builder: (context, ticketSnap) {
          if (!ticketSnap.hasData && ticketSnap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          final ticket = ticketSnap.data;
          if (ticket == null) return Center(child: Text('Ticket not found or access denied.'));

          return Column(
            children: [
              // Ticket Info Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.subject, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                         Container(
                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(4)),
                           child: Text(ticket.status.value, style: TextStyle(color: Colors.blue[800], fontSize: 12)),
                         ),
                         SizedBox(width: 8),
                         Container(
                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                           child: Text(ticket.category.value, style: TextStyle(color: Colors.grey[800], fontSize: 12)),
                         ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(ticket.description),
                    SizedBox(height: 12),
                    // Action Buttons
                    if (user?.role == UserRole.client_user) ...[
                      if (ticket.status == TicketStatus.holdForInfo)
                         ElevatedButton.icon(
                           icon: Icon(Icons.send),
                           label: Text('Provide Info'),
                           onPressed: () => _updateStatus(TicketStatus.acknowledged),
                         ),
                      if (ticket.status == TicketStatus.resolved)
                         OutlinedButton.icon(
                           icon: Icon(Icons.refresh),
                           label: Text('Reopen Ticket'),
                           onPressed: () => _updateStatus(TicketStatus.acknowledged),
                         )
                    ] else ...[
                       Wrap(
                         spacing: 8,
                         children: [
                           if (ticket.status == TicketStatus.newTicket) ...[
                             ElevatedButton(
                               onPressed: () => _updateStatus(TicketStatus.acknowledged),
                               child: Text('Acknowledge')
                             ),
                             OutlinedButton(
                               onPressed: () => _updateStatus(TicketStatus.holdForInfo),
                               child: Text('Hold for Info')
                             ),
                           ],

                           if (ticket.status == TicketStatus.acknowledged)
                             ElevatedButton(
                               onPressed: () => _updateStatus(TicketStatus.inProgress),
                               child: Text('Progress Work')
                             ),

                           if (ticket.status == TicketStatus.holdForInfo) ...[
                             ElevatedButton(
                               onPressed: () => _updateStatus(TicketStatus.inProgress),
                               child: Text('Progress Work')
                             ),
                             OutlinedButton(
                               onPressed: () => _updateStatus(TicketStatus.acknowledged),
                               child: Text('Acknowledge')
                             ),
                           ],

                           if (ticket.status == TicketStatus.inProgress)
                             ElevatedButton(
                               style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                               onPressed: () => _updateStatus(TicketStatus.resolved),
                               child: Text('Resolved')
                             ),

                           if (ticket.status == TicketStatus.resolved)
                             ElevatedButton(
                               style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                               onPressed: () => _updateStatus(TicketStatus.closed),
                               child: Text('Closed')
                             ),
                         ],
                       )
                    ]
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Comment>>(
                  stream: _firebaseService.getComments(widget.ticketId),
                  builder: (context, commentSnap) {
                     if (commentSnap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                     final comments = commentSnap.data ?? [];
                     // Auto scroll to bottom? ListView reverse: true?
                     // Usually chat is reverse list. But here comments are ASC order.
                     return ListView.builder(
                       padding: EdgeInsets.all(16),
                       itemCount: comments.length,
                       itemBuilder: (ctx, i) => CommentItem(comment: comments[i], isMe: comments[i].userId == user?.uid),
                     );
                  },
                ),
              ),
              Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                        )
                      )
                    ),
                    IconButton(icon: Icon(Icons.send, color: Colors.blue), onPressed: _postComment),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
