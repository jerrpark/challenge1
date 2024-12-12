import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 게시물 업로드
  Future<void> createPost({
    required File imageFile,
    required String caption,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');

    try {
      print('게시물 업로드 시작');
      
      // 이미지를 Storage에 업로드
      print('이미지 업로드 시작');
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('posts/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );

      // 업로드 진행 상태 모니터링
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('이미지 업로드 진행률: $progress%');
      });

      // 업로드 완료 대기
      await uploadTask;
      print('이미지 업로드 완료');

      // 이미지 URL 가져오기
      final imageUrl = await storageRef.getDownloadURL();
      print('이미지 URL 획득: $imageUrl');

      // Firestore에 게시물 데이터 저장
      print('Firestore 데이터 저장 시작');
      await _firestore.collection('posts').add({
        'userId': user.uid,
        'userName': user.displayName ?? '사용자',
        'userProfileImage': user.photoURL,
        'imageUrl': imageUrl,
        'caption': caption,
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
      });
      
      print('게시물 업로드 완료');
    } catch (e) {
      print('게시물 업로드 실패: $e');
      throw Exception('게시물 업로드에 실패했습니다: $e');
    }
  }

  // 모든 게시물 가져오기
  Stream<List<Post>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // 특정 사용자의 게시물 가져오기
  Stream<List<Post>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromMap(doc.data())).toList());
  }

  // 게시물 좋아요/좋아요 취소
  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');

    final postRef = _firestore.collection('posts').doc(postId);
    final post = await postRef.get();
    
    if (!post.exists) throw Exception('게시물을 찾을 수 없습니다.');
    
    final likes = List<String>.from(post.data()?['likes'] ?? []);
    
    if (likes.contains(user.uid)) {
      likes.remove(user.uid);
    } else {
      likes.add(user.uid);
    }
    
    await postRef.update({'likes': likes});
  }

  // 게시물 삭제
  Future<void> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      // 게시물 문서 가져오기
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) throw Exception('게시물을 찾을 수 없습니다');

      // 게시물 작성자 확인
      if (postDoc.data()?['userId'] != user.uid) {
        throw Exception('자신의 게시물만 삭제할 수 있습니다');
      }

      // Storage에서 이미지 삭제
      final imageUrl = postDoc.data()?['imageUrl'];
      if (imageUrl != null) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('이미지 삭제 실패: $e');
        }
      }

      // Firestore에서 게시물 삭제
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print('게시물 삭제 실패: $e');
      rethrow;
    }
  }
} 