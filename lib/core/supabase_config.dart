import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://hbgqbpyufaajqmedxodg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_nD_mz7oSnwq_4hYpg8wRSQ_PCxHFdMU'; // TODO: Replace with actual anon key
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
