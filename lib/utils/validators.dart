class Validators {
  // 텍스트 컨텐츠 검증
  static bool isValidContent(String? content) {
    if (content == null || content.trim().isEmpty) return false;
    if (content.length > 1000) return false;  // 최대 1000자 제한
    return true;
  }

  // 이미지 파일 검증
  static bool isValidImageFile(int fileSize) {
    final maxSize = 5 * 1024 * 1024;  // 5MB
    return fileSize <= maxSize;
  }

  // 사용자 이름 검증
  static bool isValidUsername(String? username) {
    if (username == null || username.trim().isEmpty) return false;
    if (username.length < 2 || username.length > 30) return false;
    return true;
  }
} 