import 'package:flutter_test/flutter_test.dart';
import 'package:challenge1/utils/validators.dart';

void main() {
  group('Validators', () {
    test('isValidContent returns true for valid content', () {
      expect(Validators.isValidContent('Hello World'), true);
      expect(Validators.isValidContent('A' * 1000), true);
    });

    test('isValidContent returns false for invalid content', () {
      expect(Validators.isValidContent(null), false);
      expect(Validators.isValidContent(''), false);
      expect(Validators.isValidContent('A' * 1001), false);
    });

    test('isValidImageFile returns true for valid file size', () {
      expect(Validators.isValidImageFile(1024 * 1024), true); // 1MB
      expect(Validators.isValidImageFile(5 * 1024 * 1024), true); // 5MB
    });

    test('isValidImageFile returns false for invalid file size', () {
      expect(Validators.isValidImageFile(6 * 1024 * 1024), false); // 6MB
    });

    test('isValidEmail returns true for valid email', () {
      expect(Validators.isValidEmail('test@example.com'), true);
      expect(Validators.isValidEmail('user.name@domain.co.kr'), true);
    });

    test('isValidEmail returns false for invalid email', () {
      expect(Validators.isValidEmail(null), false);
      expect(Validators.isValidEmail(''), false);
      expect(Validators.isValidEmail('invalid'), false);
      expect(Validators.isValidEmail('test@'), false);
    });

    test('isValidUsername returns true for valid username', () {
      expect(Validators.isValidUsername('John'), true);
      expect(Validators.isValidUsername('A' * 30), true);
    });

    test('isValidUsername returns false for invalid username', () {
      expect(Validators.isValidUsername(null), false);
      expect(Validators.isValidUsername(''), false);
      expect(Validators.isValidUsername('A'), false);
      expect(Validators.isValidUsername('A' * 31), false);
    });
  });
} 