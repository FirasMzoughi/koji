import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://hbgqbpyufaajqmedxodg.supabase.co';
  
  // Use dart-define for secure configuration
  static String get supabaseAnonKey {
    return const String.fromEnvironment('SUPABASE_ANON_KEY', 
      defaultValue: 'sb_publishable_nD_mz7oSnwq_4hYpg8wRSQ_PCxHFdMU'); // Fallback for development
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
