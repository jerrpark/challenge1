import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import 'post_service.dart';
import 'package:challenge1/utils/validators.dart';
import 'package:challenge1/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final PostService _postService = PostService();

  // 현재 사용자 ID 가져오기
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // 현재 사용자 프로필 가져오기
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // 프로필 수정
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    File? photoFile,
    bool deletePhoto = false,
  }) async {
    try {
      // 이름 유효성 검사
      if (displayName != null && !Validators.isValidUsername(displayName)) {
        throw Exception('유효하지 않은 사용자 이름입니다');
      }

      // 프로필 이미지 유효성 검사
      if (photoFile != null) {
        final fileSize = await photoFile.length();
        if (!Validators.isValidImageFile(fileSize)) {
          throw Exception('이미지 크기는 5MB를 초과할 수 없습니다');
        }
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 프로필 사진 처리
      if (photoFile != null || deletePhoto) {
        // 기존 프로필 사진 삭제
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final currentPhotoURL = userDoc.data()?['photoURL'];
        if (currentPhotoURL != null) {
          try {
            await _storage.refFromURL(currentPhotoURL).delete();
          } catch (e) {
            print('기존 프로필 사진 삭제 실패: $e');
          }
        }

        // 새 프로필 사진 업로드
        if (photoFile != null) {
          final String fileName = '${user.uid}_profile.jpg';
          final Reference ref = _storage
              .ref()
              .child('profiles/${user.uid}/$fileName');

          final UploadTask uploadTask = ref.putFile(photoFile);
          final TaskSnapshot snapshot = await uploadTask;
          final String url = await snapshot.ref.getDownloadURL();
          updates['photoURL'] = url;
        } else {
          updates['photoURL'] = null;
        }
      }

      // 표시 이름 업데이트
      if (displayName != null) {
        updates['displayName'] = displayName;
        await user.updateDisplayName(displayName);
      }

      // 소개글 업데이트
      if (bio != null) {
        updates['bio'] = bio;
      }

      // Firestore 문서 업데이트
      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      print('프로필 수정 실패: $e');
      rethrow;
    }
  }

  // 회원 탈퇴
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Storage에서 프로필 이미지 삭제
      final storageRef = _storage.ref().child('users/${user.uid}');
      try {
        final result = await storageRef.listAll();
        await Future.wait(
          result.items.map((ref) => ref.delete()),
        );
      } catch (e) {
        print('Storage 파일 삭제 실패: $e');
      }

      // Firestore에서 사용자 데이터 삭제
      await _firestore.collection('users').doc(user.uid).delete();

      // Firebase Auth에서 사용자 삭제
      await user.delete();
    } catch (e) {
      print('회원 탈퇴 실패: $e');
      rethrow;
    }
  }

  // 사용자 계정 삭제
  Future<bool> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 트랜잭션으로 연관 데이터 삭제
      await _firestore.runTransaction((transaction) async {
        // 1. 사용자의 게시글 조회
        final postsQuery = await _firestore
            .collection('posts')
            .where('authorId', isEqualTo: user.uid)
            .get();

        // 2. 각 게시글의 댓글 삭제
        for (var postDoc in postsQuery.docs) {
          final commentsQuery = await _firestore
              .collection('comments')
              .where('postId', isEqualTo: postDoc.id)
              .get();
          
          for (var commentDoc in commentsQuery.docs) {
            transaction.delete(commentDoc.reference);
          }

          // 게시글의 미디어 파일 삭제
          final postData = postDoc.data();
          final mediaUrls = List<String>.from(postData['mediaUrls'] ?? []);
          for (var url in mediaUrls) {
            await _storageService.deleteFile(url);
          }

          // 게시글 삭제
          transaction.delete(postDoc.reference);
        }

        // 3. 사용자의 댓글 삭제
        final userCommentsQuery = await _firestore
            .collection('comments')
            .where('authorId', isEqualTo: user.uid)
            .get();
        
        for (var commentDoc in userCommentsQuery.docs) {
          transaction.delete(commentDoc.reference);
        }

        // 4. 프로필 이미지 삭제
        if (user.photoURL != null) {
          await _storageService.deleteFile(user.photoURL!);
        }

        // 5. 사용자 문서 삭제
        transaction.delete(_firestore.collection('users').doc(user.uid));
      });

      // 6. Firebase Auth에서 사용자 삭제
      await user.delete();

      return true;
    } catch (e) {
      print('사용자 계정 삭제 실패: $e');
      return false;
    }
  }

  Stream<UserModel> getUserStream(String userId) {
    print('Getting user stream for userId: $userId');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          try {
            if (!doc.exists) {
              print('Document does not exist for userId: $userId');
              throw Exception('사용자를 찾을 수 없습니다');
            }
            
            final data = doc.data();
            if (data == null) {
              print('Document data is null for userId: $userId');
              throw Exception('사용자 데이터가 없습니다');
            }
            
            return UserModel.fromMap(data);
          } catch (e) {
            print('Error in getUserStream: $e');
            rethrow;
          }
        });
  }

  // 사용자 문서가 없는 경우 생성
  Future<void> createUserIfNotExists(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      print('Creating new user document for userId: $userId');
      await _firestore.collection('users').doc(userId).set({
        'id': userId,
        'createdAt': FieldValue.serverTimestamp(),
        // 기본값 설정
        'username': '사용자',
        'bio': '',
        'profileImageUrl': null,
      });
    }
  }
} 