import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_keys.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}

final supabase = Supabase.instance.client;
