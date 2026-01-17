import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: ${e.toString()}")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _fillDemo(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'ForgeTrack',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Enter email' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (val) => val!.isEmpty ? 'Enter password' : null,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Login'),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                ),
                SizedBox(height: 24),
                Text('Demo Accounts:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => _fillDemo('client@apple.com', 'password123'),
                      child: Text('Client'),
                    ),
                    OutlinedButton(
                      onPressed: () => _fillDemo('agent@factory.com', 'password123'),
                      child: Text('Agent'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
