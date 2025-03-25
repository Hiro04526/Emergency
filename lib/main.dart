import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/location_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'models/user_profile.dart';
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
  
  runApp(
    MultiProvider(
      providers: [
        Provider<LocationService>.value(value: locationService),
        Provider<ApiService>.value(value: apiService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<AlertService>.value(value: alertService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: const EmergencyServicesApp(),
    ),
  );
}

class EmergencyServicesApp extends StatelessWidget {
  const EmergencyServicesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    return MaterialApp(
      title: 'Emergency Services',
      scaffoldMessengerKey: notificationService.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}
