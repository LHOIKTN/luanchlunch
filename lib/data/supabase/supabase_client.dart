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
  
  // Check if keys are available
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Supabase URL 또는 Anon Key가 설정되지 않았습니다.');
  }
  
  // Initialize Supabase with custom options
  await Supabase.initialize(
    url: supabaseUrl!,
    anonKey: supabaseAnonKey!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    // 개발 환경용 SSL 검증 완화
    debug: true,
  );
  
  supabase = Supabase.instance.client;
  _isInitialized = true;
}
