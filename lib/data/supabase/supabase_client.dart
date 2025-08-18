import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_keys.dart';
import 'http_client.dart'; // 개발 환경용 SSL 검증 완화

late final SupabaseClient supabase;
bool _isInitialized = false;

// 외부에서 접근 가능한 getter
bool get isSupabaseInitialized => _isInitialized;

Future<void> initSupabase() async {
  // 이미 초기화되었으면 중복 초기화 방지
  if (_isInitialized) {
    print('✅ Supabase 이미 초기화됨');
    return;
  }

  try {
    print('🔄 Supabase 초기화 시작...');

    // Check if keys are available
    if (supabaseUrl == null || supabaseAnonKey == null) {
      print('⚠️ Supabase 키가 설정되지 않음 - 오프라인 모드로 실행');
      return; // 키가 없어도 앱은 계속 실행
    }

    final httpClient = getInsecureHttpClient();

    // Initialize Supabase with custom options
    await Supabase.initialize(
      url: supabaseUrl!,
      anonKey: supabaseAnonKey!,
      httpClient: httpClient,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      // 개발 환경용 SSL 검증 완화
      debug: true,
    );

    supabase = Supabase.instance.client;
    _isInitialized = true;
    print('✅ Supabase 초기화 완료');
  } catch (e) {
    print('❌ Supabase 초기화 실패: $e');
    _isInitialized = false;
    // 초기화 실패해도 앱은 계속 실행
  }
}
