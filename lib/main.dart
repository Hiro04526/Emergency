import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/location_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'models/user_profile.dart';
import 'providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final locationService = LocationService();
  await locationService.initialize();
  
  final apiService = ApiService();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize alert service
  final alertService = AlertService();
  alertService.initialize(notificationService);

  await supabase.Supabase.initialize(
    url: 'https://aofppzgxmwazyhmzwpgr.supabase.co/',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvZnBwemd4bXdhenlobXp3cGdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI2NjgzMTYsImV4cCI6MjA1ODI0NDMxNn0.-PvVy-pXJIr69jj_xx32-L27zZhyFjYt8LLjVPX1oh4',
  );
  
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
        Provider<ApiService>.value(value: apiService),
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
