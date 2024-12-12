import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String imageUrl;
  final String? caption;
  final String? location;
  final DateTime createdAt;
  final List<String> likes;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.imageUrl,
    this.caption,
    this.location,
    required this.createdAt,
    required this.likes,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // createdAt이 null인 경우 현재 시간을 사용
    DateTime createdAt;
    try {
      createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }

    // likes 배열을 안전하게 변환
    List<String> likes = [];
    try {
      final likesData = data['likes'];
      if (likesData is List) {
        likes = List<String>.from(likesData);
      }
    } catch (e) {
      print('likes 변환 오류: $e');
    }

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfileImage: data['userProfileImage'],
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'],
      location: data['location'],
      createdAt: createdAt,
      likes: likes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'imageUrl': imageUrl,
      'caption': caption,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfileImage: map['userProfileImage'],
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'],
      location: map['location'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(map['likes'] ?? []),
    );
  }
} 