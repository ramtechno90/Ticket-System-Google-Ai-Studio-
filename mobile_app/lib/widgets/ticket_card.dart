import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import 'package:intl/intl.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({Key? key, required this.ticket, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        onTap: onTap,
        title: Text(ticket.subject, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(ticket.category.value, style: TextStyle(fontSize: 12)),
            SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ticket.updatedAt)),
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!)
          ),
          child: Text(
            ticket.status.value,
            style: TextStyle(color: Colors.blue[800], fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
