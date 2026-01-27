import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_ticket_screen.dart';
import 'screens/ticket_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MaterialAppWithRouter(),
    );
  }
}

class MaterialAppWithRouter extends StatelessWidget {
  const MaterialAppWithRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context); // Watch auth state

    final GoRouter router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authService.currentUser != null; // Simplified
        final isLoggingIn = state.uri.toString() == '/login';
        
        if (authService.isLoading) return null; // Wait for loading

        if (!isLoggedIn && !isLoggingIn) return '/login';
        if (isLoggedIn && isLoggingIn) return '/';
        
        return null;
      },
      routes: [
         GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/new-ticket',
          builder: (context, state) => const CreateTicketScreen(),
        ),
        GoRoute(
          path: '/ticket/:id',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
             return TicketDetailScreen(ticketId: id);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Ticketing System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}