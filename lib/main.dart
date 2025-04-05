import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/location_service.dart';

import 'services/notification_service.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'models/user_profile.dart';
import 'providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'services/cache_manager_service.dart';
import 'services/database_service.dart';
import 'models/emergency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load();
  
  // Initialize location service
  final locationService = LocationService();
  await locationService.initialize();
  

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize Supabase first using environment variables
  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await ServiceCacheManager.init();
  final DatabaseService databaseService = DatabaseService();

  await Future.wait([
    databaseService.searchServices(type: ServiceType.fireStation),
    databaseService.searchServices(type: ServiceType.government),
    databaseService.searchServices(type: ServiceType.medical),
    databaseService.searchServices(type: ServiceType.police),
  ]);

  // Initialize alert service after Supabase
  final alertService = AlertService();
  await alertService.initialize(notificationService);
  
  // Initialize auth service
  final authService = AuthService();
  authService.initialize();
  
  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<LocationService>.value(value: locationService),

        Provider<NotificationService>.value(value: notificationService),
        Provider<AlertService>.value(value: alertService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: EmergencyServicesApp(),
    ),
  );
}

class EmergencyServicesApp extends StatelessWidget {
  EmergencyServicesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Emergency Services',
      scaffoldMessengerKey: notificationService.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      home: HomeScreen(),
      routes: {
        '/auth': (context) => AuthScreen(),
      },
    );
  }
}
