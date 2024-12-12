import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../models/post.dart';
import 'create_post_screen.dart';
import '../services/comment_service.dart';
import '../screens/comment_screen.dart';
import '../models/comment.dart';

class HomeScreen extends StatelessWidget {
  static final PostService _postService = PostService();

  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instagram'),
      ),
      body: StreamBuilder<List<Post>>(
        stream: _postService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('오류가 발생했습니다'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!;
          
          if (posts.isEmpty) {
            return const Center(child: Text('게시물이 없습니다'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(post: post);
            },
          );
        },
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final CommentService _commentService = CommentService();

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('게시물 삭제'),
        content: Text('이 게시물을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _postService.deletePost(widget.post.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('게시물이 삭제되었습니다')),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('게시물 삭제 실패: $e')),
                  );
                }
              }
            },
            child: Text('삭제'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.userProfileImage != null
                  ? CachedNetworkImageProvider(widget.post.userProfileImage!)
                  : null,
              child: widget.post.userProfileImage == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(widget.post.userName),
            subtitle: widget.post.location != null && widget.post.location!.isNotEmpty
                ? Text(widget.post.location!)
                : null,
            trailing: widget.post.userId == _authService.currentUser?.uid
                ? PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          if (widget.post.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.post.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.grey[600]),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentScreen(
                              postId: widget.post.id,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          StreamBuilder<List<Comment>>(
                            stream: _commentService.getComments(widget.post.id),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              return Text(
                                '${snapshot.data!.length}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.send_outlined, color: Colors.grey[600]),
                  ],
                ),
                if (widget.post.likes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '좋아요 ${widget.post.likes.length}개',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(widget.post.caption!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 