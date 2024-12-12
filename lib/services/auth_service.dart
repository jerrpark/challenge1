import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';
import '../utils/validators.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  // 현재 사용자 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google 로그인 진행
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // credential 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 인증
      final userCredential = 
          await _auth.signInWithCredential(credential);

      // Firestore에 사용자 정보 저장
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Google 로그인 실패: $e');
      return null;
    }
  }

  // Firestore에 사용자 정보 저장
  Future<void> _saveUserToFirestore(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'provider': 'google',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 프로필 이미지 업데이트
  Future<bool> updateProfileImage(XFile image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Storage에 이미지 업로드
      final imageUrl = await _storage.uploadProfileImage(user.uid, image);
      if (imageUrl == null) return false;
      
      // Firestore 사용자 문서 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('프로필 이미지 업데이트 실패: $e');
      return false;
    }
  }

  // currentUser getter 추가
  User? get currentUser => _auth.currentUser;
} 