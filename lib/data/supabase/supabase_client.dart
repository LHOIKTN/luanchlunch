import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_keys.dart';

late final SupabaseClient supabase;
bool _isInitialized = false;

Future<void> initSupabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if Supabase is already initialized
  if (_isInitialized) {
    return; // Already initialized, just return
  }
  
  // Initialize Supabase
  await Supabase.initialize(url: supabaseUrl!, anonKey: supabaseAnonKey!);
  supabase = Supabase.instance.client;
  _isInitialized = true;
}
