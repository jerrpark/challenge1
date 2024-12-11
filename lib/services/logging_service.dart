import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class LoggingService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // 에러 로깅
  Future<void> logError(dynamic error, StackTrace? stackTrace) async {
    try {
      await _crashlytics.recordError(error, stackTrace);
    } catch (e) {
      print('에러 로깅 실패: $e');
    }
  }

  // 이벤트 로깅
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      print('이벤트 로깅 실패: $e');
    }
  }

  // 사용자 속성 설정
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      print('사용자 속성 설정 실패: $e');
    }
  }
} 