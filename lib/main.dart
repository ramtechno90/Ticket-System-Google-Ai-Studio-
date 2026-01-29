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
import 'screens/notifications_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

class MaterialAppWithRouter extends StatefulWidget {
  const MaterialAppWithRouter({super.key});

  @override
  State<MaterialAppWithRouter> createState() => _MaterialAppWithRouterState();
}

class _MaterialAppWithRouterState extends State<MaterialAppWithRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);

    _router = GoRouter(
      refreshListenable: authService,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = authService.currentUser != null;
        final isLoggingIn = state.uri.toString() == '/login';
        final isSplashing = state.uri.toString() == '/splash';

        if (authService.isLoading) {
          // If we're loading, stay on the splash screen.
          return isSplashing ? null : '/splash';
        }

        if (isSplashing) {
          // If we're done loading and on the splash screen, redirect.
          return isLoggedIn ? '/' : '/login';
        }

        if (!isLoggedIn && !isLoggingIn) {
          // If not logged in and not on the login page, redirect to login.
          return '/login';
        }

        if (isLoggedIn && isLoggingIn) {
          // If logged in and on the login page, redirect to the dashboard.
          return '/';
        }

        return null; // No redirect needed.
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
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
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Setup notification listeners once the router is ready
    _setupNotificationListeners();

    return MaterialApp.router(
      title: 'Ticketing System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }

  void _setupNotificationListeners() {
    // 1. Terminated State: App opened from notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });

    // 2. Background State: App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    // 3. Foreground State: App is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Here you could show a local notification or a snackbar
      // For simplicity, we can show a SnackBar if we are in a valid context
      // But MaterialApp.router context is above the Navigator.
      // We rely on the system tray notification which usually doesn't show in foreground on iOS unless configured.
      // On Android it doesn't show by default in foreground.
      // To show foreground notification properly requires flutter_local_notifications.
    });
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (message.data.containsKey('ticketId')) {
      final ticketId = message.data['ticketId'];
      // Navigate to the ticket
      // We need to wait for auth to be ready ideally, but GoRouter redirect will handle it if not logged in.
      _router.push('/ticket/$ticketId');
    }
  }
}