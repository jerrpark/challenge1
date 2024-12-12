class UserModel {
  final String id;
  final String? username;
  final String? bio;
  final String? profileImageUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    this.username,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'],
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 