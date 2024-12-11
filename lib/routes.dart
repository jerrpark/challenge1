import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/post_list_screen.dart';
import 'screens/comment_screen.dart';
import 'screens/edit_post_screen.dart';
import 'screens/edit_profile_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const PostListScreen(),
  '/login': (context) => LoginScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/create_post': (context) => const CreatePostScreen(),
  '/comments': (context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as Map<String, String>;
    return CommentScreen(
      postId: args['postId']!,
      postAuthorId: args['postAuthorId']!,
    );
  },
  '/edit_post': (context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>;
    return EditPostScreen(
      postId: args['postId'],
      post: args['post'],
    );
  },
  '/edit_profile': (context) {
    final userProfile = ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>;
    return EditProfileScreen(userProfile: userProfile);
  },
}; 