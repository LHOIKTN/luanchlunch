import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_keys.dart';

late final SupabaseClient supabase;

Future<void> initSupabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl!, anonKey: supabaseAnonKey!);
  supabase = Supabase.instance.client;
}
