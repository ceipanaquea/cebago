import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper para acceder fácilmente al cliente de Supabase
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static bool get isAuthenticated => client.auth.currentUser != null;
}
