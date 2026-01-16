import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/enums.dart';
import '../screens/create_user_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(user?.name.substring(0, 1) ?? 'U', style: TextStyle(fontSize: 24)),
              backgroundColor: Colors.white,
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
               // Already on dashboard or navigate
               Navigator.pop(context);
            },
          ),
          if (user?.role == UserRole.admin)
             ListTile(
               leading: Icon(Icons.person_add),
               title: Text('Create User'),
               onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => CreateUserScreen()));
               },
             ),
          Spacer(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
               auth.logout();
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
