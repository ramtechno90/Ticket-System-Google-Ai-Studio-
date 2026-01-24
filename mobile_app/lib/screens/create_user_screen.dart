import 'package:flutter/material.dart';
import '../models/enums.dart';

class CreateUserScreen extends StatefulWidget {
  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _clientIdController = TextEditingController();
  UserRole _role = UserRole.client_user;
  bool _isLoading = false;

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
       setState(() => _isLoading = true);
       // Note: In a real app, you would need to initialize a secondary Firebase App
       // to create a user without logging out the current admin.
       // For this demo, we just show a success message.
       await Future.delayed(Duration(seconds: 1));
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User creation logic requires secondary app init.')));
         setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create User')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: InputDecoration(labelText: 'Role'),
                items: UserRole.values.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r.value));
                }).toList(),
                onChanged: (val) => setState(() => _role = val!),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _clientIdController,
                decoration: InputDecoration(labelText: 'Client ID / Manufacturer'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createUser,
                child: _isLoading ? CircularProgressIndicator() : Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
