import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class DatabaseInitializer {
  // Singleton pattern
  static final DatabaseInitializer _instance = DatabaseInitializer._internal();
  factory DatabaseInitializer() => _instance;
  DatabaseInitializer._internal();

  // Get Supabase client
  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  // Initialize database schema
  Future<void> initializeSchema() async {
    try {
      // Check if tables exist
      await _createServiceTable();
      await _createUserTable();
      await _createReportedTable();
      await _createContactTable();
      await _createHistoryTable();
      await _createFavoriteTable();
      await _createAlertTable();
      
      debugPrint('Database schema initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database schema: $e');
    }
  }

  // Create service table if it doesn't exist
  Future<void> _createServiceTable() async {
    try {
      await _client.rpc('create_service_table_if_not_exists');
    } catch (e) {
      debugPrint('Error creating service table: $e');
    }
  }

  // Create user table if it doesn't exist
  Future<void> _createUserTable() async {
    try {
      await _client.rpc('create_user_table_if_not_exists');
    } catch (e) {
      debugPrint('Error creating user table: $e');
    }
  }

  // Create reported table if it doesn't exist
  Future<void> _createReportedTable() async {
    try {
      await _client.rpc('create_reported_table_if_not_exists');
    } catch (e) {
      debugPrint('Error creating reported table: $e');
    }
  }

  // Create contact table if it doesn't exist
  Future<void> _createContactTable() async {
    try {
      await _client.rpc('create_contact_table_if_not_exists');
    } catch (e) {
      debugPrint('Error creating contact table: $e');
    }
  }

  // Create history table if it doesn't exist
  Future<void> _createHistoryTable() async {
    try {
      await _client.rpc('create_history_table_if_not_exists');
    } catch (e) {
      debugPrint('Error creating history table: $e');
    }
  }

  // Create favorite table if it doesn't exist
  Future<void> _createFavoriteTable() async {
    try {
      await _client.rpc('create_favorite_table_if_not_exists');
    } catch (e) {
      debugPrint('Error creating favorite table: $e');
    }
  }

  // Create alert table if it doesn't exist
  Future<void> _createAlertTable() async {
    try {
      await _client.rpc('create_alert_table_if_not_exists');
    } catch (e) {
      debugPrint('Error creating alert table: $e');
    }
  }
}
