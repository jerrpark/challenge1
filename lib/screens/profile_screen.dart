import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../models/post.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkUserDocument();
  }

  Future<void> _checkUserDocument() async {
    await _userService.createUserIfNotExists(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel>(
        stream: _userService.getUserStream(widget.userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            print('Profile error: ${userSnapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('프로필을 불러오는데 실패했습니다'),
                  if (kDebugMode)
                    Text('Error: ${userSnapshot.error}'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final user = userSnapshot.data!;

          return Column(
            children: [
              // 프로필 정보 섹션
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 프로필 이미지
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                    SizedBox(height: 16),
                    
                    // 사용자 이름
                    Text(
                      user.username ?? '사용자',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // 소개글
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(user.bio!),
                      ),
                  ],
                ),
              ),

              Divider(),

              // 게시물 목록
              Expanded(
                child: StreamBuilder<List<Post>>(
                  stream: _postService.getUserPosts(widget.userId),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.hasError) {
                      return Center(child: Text('게시물을 불러오는데 실패했습니다'));
                    }

                    if (!postSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final posts = postSnapshot.data!;

                    if (posts.isEmpty) {
                      return Center(child: Text('아직 게시물이 없습니다'));
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/post-detail',
                              arguments: post,
                            );
                          },
                          child: Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 