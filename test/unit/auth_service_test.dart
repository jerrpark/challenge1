import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:challenge1/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    authService = AuthService();
  });

  group('AuthService', () {
    test('signInWithGoogle success', () async {
      when(mockAuth.signInWithCredential(any))
          .thenAnswer((_) async => UserCredential(user: mockUser));
      when(mockUser.uid).thenReturn('test-uid');

      final result = await authService.signInWithGoogle();
      
      expect(result, isNotNull);
      verify(mockAuth.signInWithCredential(any)).called(1);
    });

    test('signInWithGoogle failure', () async {
      when(mockAuth.signInWithCredential(any))
          .thenThrow(FirebaseAuthException(code: 'error'));

      final result = await authService.signInWithGoogle();
      
      expect(result, isNull);
    });
  });
} 