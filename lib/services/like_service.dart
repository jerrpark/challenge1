import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 좋아요 토글
  Future<bool> toggleLike(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid);

      final postRef = _firestore.collection('posts').doc(postId);

      // 트랜잭션으로 좋아요 토글과 카운트 업데이트를 동시에 처리
      bool isLiked = false;
      await _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);
        
        if (likeDoc.exists) {
          // 좋아요 취소
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'likes': FieldValue.increment(-1),
          });
          isLiked = false;
        } else {
          // 좋아요 추가
          transaction.set(likeRef, {
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {
            'likes': FieldValue.increment(1),
          });
          isLiked = true;
        }
      });

      return isLiked;
    } catch (e) {
      print('좋아요 토글 실패: $e');
      rethrow;
    }
  }

  // 좋아요 상태 확인
  Stream<bool> getLikeStatus(String postId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }
} 