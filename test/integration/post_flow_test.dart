import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:challenge1/main.dart' as app;
import 'package:challenge1/services/auth_service.dart';
import 'package:challenge1/services/post_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Post Flow Test', () {
    testWidgets('Create and delete post flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 로그인
      final authService = AuthService();
      await authService.signInWithGoogle();
      await tester.pumpAndSettle();

      // 게시글 작성
      final postService = PostService();
      final postId = await postService.createPost(
        content: 'Test post content',
      );
      expect(postId, isNotNull);

      // 게시글 삭제
      final deleteResult = await postService.deletePost(postId!);
      expect(deleteResult, true);
    });
  });
} 