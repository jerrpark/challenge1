import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:challenge1/utils/validators.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 댓글 작성
  Future<String?> createComment(
    String postId,
    String content,
  ) async {
    try {
      // 댓글 내용 유효성 검사
      if (!Validators.isValidContent(content)) {
        throw Exception('유효하지 않은 댓글 내용입니다');
      }

      final user = _auth.currentUser;
      if (user == null) return null;

      // 트랜잭션으로 댓글 생성 및 게시글의 댓글 수 업데이트
      final result = await _firestore.runTransaction((transaction) async {
        // 댓글 문서 생성
        final commentRef = _firestore.collection('comments').doc();
        transaction.set(commentRef, {
          'postId': postId,
          'authorId': user.uid,
          'content': content,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 게시글의 댓글 수 증가
        final postRef = _firestore.collection('posts').doc(postId);
        final postDoc = await transaction.get(postRef);
        final currentComments = postDoc.data()?['comments'] ?? 0;
        transaction.update(postRef, {'comments': currentComments + 1});

        return commentRef.id;
      });

      return result;
    } catch (e) {
      print('댓글 작성 실패: $e');
      return null;
    }
  }

  // 댓글 목록 조회
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 댓글 수정
  Future<bool> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('댓글 수정 실패: $e');
      return false;
    }
  }

  // 댓글 삭제
  Future<bool> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      // 트랜잭션으로 댓글 삭제 및 게시글의 댓글 수 감소
      await _firestore.runTransaction((transaction) async {
        // 댓글 삭제
        final commentRef = _firestore.collection('comments').doc(commentId);
        transaction.delete(commentRef);

        // 게시글의 댓글 수 감소
        final postRef = _firestore.collection('posts').doc(postId);
        final postDoc = await transaction.get(postRef);
        final currentComments = postDoc.data()?['comments'] ?? 0;
        transaction.update(postRef, {
          'comments': currentComments > 0 ? currentComments - 1 : 0
        });
      });

      return true;
    } catch (e) {
      print('댓글 삭제 실패: $e');
      return false;
    }
  }
} 