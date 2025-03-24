import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Class to handle database initialization
class DatabaseInitializer {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  /// Initialize the database connection and verify it's working
  Future<bool> initializeDatabase() async {
    try {
      // Test the connection by making a simple query
      await _supabase.from('emergency_services').select('id').limit(1);
      debugPrint('Supabase connection successful');
      return true;
    } catch (e) {
      debugPrint('Error connecting to Supabase: $e');
      return false;
    }
  }
}
