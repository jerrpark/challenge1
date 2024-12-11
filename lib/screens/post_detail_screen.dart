import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/like_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final LikeService _likeService = LikeService();
  bool _isLoading = false;

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _postService.deletePost(widget.postId);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글 삭제에 실패했습니다')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          if (widget.post['authorId'] == _userService.getCurrentUserId())
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('수정'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/edit_post',
                      arguments: {
                        'postId': widget.postId,
                        'post': widget.post,
                      },
                    );
                  },
                ),
                PopupMenuItem(
                  child: const Text('삭제'),
                  onTap: _deletePost,
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 정보
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _userService.getCurrentUserProfile(),
                    builder: (context, snapshot) {
                      final author = snapshot.data;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: author?['photoURL'] != null
                              ? CachedNetworkImageProvider(author!['photoURL'])
                              : null,
                          child: author?['photoURL'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(author?['displayName'] ?? '사용자'),
                        subtitle: Text(
                          widget.post['createdAt']?.toDate()?.toString() ?? '',
                        ),
                      );
                    },
                  ),
                  // 게시글 내용
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(widget.post['content'] ?? ''),
                  ),
                  // 미디어 파일
                  if (widget.post['mediaUrls']?.isNotEmpty ?? false)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.post['mediaUrls'].length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CachedNetworkImage(
                              imageUrl: widget.post['mediaUrls'][index],
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  // 좋아요, 댓글 버튼
                  ButtonBar(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.comment),
                        label: Text('${widget.post['comments'] ?? 0}'),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/comments',
                            arguments: {
                              'postId': widget.postId,
                              'postAuthorId': widget.post['authorId'],
                            },
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: StreamBuilder<bool>(
                          stream: _likeService.getLikeStatus(widget.postId),
                          builder: (context, snapshot) {
                            final isLiked = snapshot.data ?? false;
                            return Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : null,
                            );
                          },
                        ),
                        label: Text('${widget.post['likes'] ?? 0}'),
                        onPressed: () async {
                          try {
                            await _likeService.toggleLike(widget.postId);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('좋아요 처리에 실패했습니다'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
} 