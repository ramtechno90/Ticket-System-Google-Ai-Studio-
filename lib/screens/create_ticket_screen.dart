import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/ticket_model.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketCategory _selectedCategory = TicketCategory.general;
  bool _isLoading = false;

  Future<void> _submitTicket() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser!;
        final firestoreService = FirestoreService();

        // Generate a simple ID or let Firestore do it (we are doing manual ID in React app?)
        // React App: Likely auto-id, but let's check Ticket Model.
        // Ticket Model has 'id'.
        // We will generate a doc ref first to get ID.
        
        final docRef = firestoreService.getNewTicketRef();
        
        final ticket = Ticket(
          id: docRef.id,
          clientId: user.clientId,
          clientName: user.clientName ?? user.clientId,
          userId: user.uid,
          userName: user.name,
          category: _selectedCategory,
          status: TicketStatus.newTicket,
          subject: _subjectController.text,
          description: _descriptionController.text,
          attachments: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await firestoreService.createTicket(ticket, docRef: docRef);

        if (mounted) {
          context.pop(); // Go back to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raise New Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<TicketCategory>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: TicketCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Enter a subject' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('Submit Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
