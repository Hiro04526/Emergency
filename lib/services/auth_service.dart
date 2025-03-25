import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Stream controller for auth state changes
  final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);
  
  // Initialize the service
  void initialize() {
    // Set initial authentication state
    final session = Supabase.instance.client.auth.currentSession;
    authStateNotifier.value = session != null;
    
    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          authStateNotifier.value = true;
          break;
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.userDeleted:
          authStateNotifier.value = false;
          break;
        default:
          break;
      }
    });
  }

  // Check if user is currently authenticated
  bool get isAuthenticated => Supabase.instance.client.auth.currentSession != null;
  
  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    
    if (response.user != null && response.session != null && userData != null) {
      // Register additional user data
      try {
        await Supabase.instance.client.rpc(
          'registerUser',
          params: userData,
        );
      } catch (e) {
        print('Error registering user data: $e');
        // Consider whether to handle this error more gracefully
      }
    }
    
    return response;
  }
  
  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
  
  // Get current user
  User? get currentUser => Supabase.instance.client.auth.currentUser;
  
  // Utility method to check if a feature requires authentication
  // Returns true if the user can access the feature, false otherwise
  bool canAccessAuthFeature(BuildContext context, {bool showDialog = true}) {
    if (isAuthenticated) {
      return true;
    }
    
    if (showDialog) {
      // Show auth dialog
      showAuthRequiredDialog(context);
    }
    
    return false;
  }
  
  // Show a dialog prompting the user to authenticate
  void showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text(
          'You need to be logged in to access this feature. Would you like to log in or sign up now?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/auth');
            },
            child: const Text('Log In / Sign Up'),
          ),
        ],
      ),
    );
  }

  // Utility method to check if a user can access contributor features
  // These are features that require login but aren't premium
  bool canAccessContributorFeature(BuildContext context, {bool showDialog = true}) {
    if (isAuthenticated) {
      return true;
    }
    
    if (showDialog) {
      // Show a specific dialog for contributor features
      showContributorFeatureDialog(context);
    }
    
    return false;
  }
  
  // Show a dialog specifically for contributor features
  void showContributorFeatureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'You need to be logged in to contribute content to our platform. Would you like to log in or sign up now?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/auth');
            },
            child: const Text('Log In / Sign Up'),
          ),
        ],
      ),
    );
  }
} 