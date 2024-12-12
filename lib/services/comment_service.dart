import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 댓글 작성
  Future<void> createComment({
    required String postId,
    required String content,
    required String userId,
  }) async {
    try {
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      await commentRef.set({
        'id': commentRef.id,
        'postId': postId,
        'userId': userId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('댓글 작성 실패: $e');
      rethrow;
    }
  }

  // 댓글 목록 가져오기
  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Comment.fromFirestore(doc))
              .toList();
        });
  }

  // 댓글 수정
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'content': content,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // 댓글 삭제
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
} 