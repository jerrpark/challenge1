import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cross_file/cross_file.dart';
import 'storage_service.dart';
import '../utils/validators.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storage = StorageService();
  
  // 게시글 작성
  Future<String?> createPost({
    required String content,
    List<XFile>? images,
  }) async {
    try {
      // 컨텐츠 유효성 검사
      if (!Validators.isValidContent(content)) {
        throw Exception('유효하지 않은 게시글 내용입니다');
      }

      // 이미지 유효성 검사
      if (images != null) {
        for (var image in images) {
          final fileSize = await image.length();
          if (!Validators.isValidImageFile(fileSize)) {
            throw Exception('이미지 크기는 5MB를 초과할 수 없습니다');
          }
        }
      }

      final user = _auth.currentUser;
      if (user == null) return null;

      // 이미지가 있다면 ���저 업로드
      List<String> mediaUrls = [];
      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final postId = DateTime.now().millisecondsSinceEpoch.toString();
          final url = await _storage.uploadPostImage(postId, image);
          if (url != null) mediaUrls.add(url);
        }
      }

      // Firestore에 게시글 저장
      final docRef = await _firestore.collection('posts').add({
        'authorId': user.uid,
        'content': content,
        'mediaUrls': mediaUrls,
        'likes': 0,
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('게시글 작성 실패: $e');
      return null;
    }
  }

  // 게시글 조회 (페이지네이션)
  Stream<QuerySnapshot> getPostsStream({
    DocumentSnapshot? lastDocument,
    int limit = 10,
    List<String>? fields,
  }) {
    var query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots();
  }

  // 특정 사용자의 게시글 조회
  Stream<List<Map<String, dynamic>>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'content': data['content'],
            'mediaUrls': data['mediaUrls'],
            'createdAt': data['createdAt'],
          };
        }).toList());
  }

  // 게시글 수정
  Future<bool> updatePost(
    String postId,
    String content, {
    List<String>? deleteMediaUrls,
    List<XFile>? newMediaFiles,
  }) async {
    try {
      // 기존 이미지 삭제
      if (deleteMediaUrls != null) {
        for (var url in deleteMediaUrls) {
          await _storage.deleteFile(url);
        }
      }

      // 새 이미지 업로드
      List<String> newUrls = [];
      if (newMediaFiles != null) {
        for (var file in newMediaFiles) {
          final url = await _storage.uploadPostImage(postId, file);
          if (url != null) newUrls.add(url);
        }
      }

      await _firestore.collection('posts').doc(postId).update({
        'content': content,
        'mediaUrls': newUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('게시글 수정 실패: $e');
      return false;
    }
  }

  // 게시글 삭제
  Future<bool> deletePost(String postId) async {
    try {
      // 트랜잭션으로 게시글과 연관 데이터 삭제
      await _firestore.runTransaction((transaction) async {
        // 1. 게시글 문서 가져오기
        final postDoc = await transaction.get(
          _firestore.collection('posts').doc(postId)
        );
        final data = postDoc.data() as Map<String, dynamic>;

        // 2. 게시글의 모든 댓글 삭제
        final commentsQuery = await _firestore
            .collection('comments')
            .where('postId', isEqualTo: postId)
            .get();
        
        for (var commentDoc in commentsQuery.docs) {
          transaction.delete(commentDoc.reference);
        }

        // 3. Storage에서 이미지 삭제
        final mediaUrls = List<String>.from(data['mediaUrls'] ?? []);
        for (var url in mediaUrls) {
          await _storage.deleteFile(url);
        }

        // 4. 게시글 삭제
        transaction.delete(postDoc.reference);
      });

      return true;
    } catch (e) {
      print('게시글 삭제 실패: $e');
      return false;
    }
  }
} 