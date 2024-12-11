import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 프로필 이미지 업로드
  Future<String?> uploadProfileImage(String userId, XFile image) async {
    try {
      final ref = _storage.ref().child('profiles/$userId/profile.jpg');
      final uploadTask = ref.putData(await image.readAsBytes());
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('프로필 이미지 업로드 실패: $e');
      return null;
    }
  }

  // 게시글 이미지 업로드
  Future<String?> uploadPostImage(String postId, XFile image) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('posts/$postId/$fileName');
      final uploadTask = ref.putData(await image.readAsBytes());
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('게시글 이미지 업로드 실패: $e');
      return null;
    }
  }

  // 파일 삭제
  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      print('파일 삭제 실패: $e');
      return false;
    }
  }
} 