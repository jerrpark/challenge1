# Firestore 규칙

## 컬렉션 구조

### users
- 문서 ID: `{uid}` (Firebase Auth UID)
typescript
{
uid: string, // 사용자 고유 ID
email: string, // 이메일
displayName: string, // 표시 이름
photoURL: string, // 프로필 사진 URL
provider: string, // 로그인 제공자 (google, apple 등)
createdAt: timestamp, // 계정 생성일
updatedAt: timestamp // 정보 수정일
}


### posts
- 문서 ID: 자동 생성
typescript
{
authorId: string, // 작성자 ID (users 컬렉션 참조)
content: string, // 게시글 내용
mediaUrls: string[], // 미디어 파일 URL 배열
likes: number, // 좋아요 수
comments: number, // 댓글 수
createdAt: timestamp, // 작성일
updatedAt: timestamp // 수정일
}


### comments
- 문서 ID: 자동 생성
typescript
{
postId: string, // 게시글 ID
authorId: string, // 작성자 ID
content: string, // 댓글 내용
createdAt: timestamp, // 작성일
updatedAt: timestamp // 수정일
}


## Firestore 보안 규칙
javascript
rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {
// 인증된 사용자 확인
function isAuthenticated() {
return request.auth != null;
}
// 본인 확인
function isOwner(userId) {
return request.auth.uid == userId;
}
// users 컬렉션 규칙
match /users/{userId} {
allow read: if isAuthenticated();
allow create: if isAuthenticated() && isOwner(userId);
allow update: if isAuthenticated() && isOwner(userId);
allow delete: if isAuthenticated() && isOwner(userId);
}
// posts 컬렉션 규칙
match /posts/{postId} {
allow read: if isAuthenticated();
allow create: if isAuthenticated();
allow update, delete: if isAuthenticated() &&
resource.data.authorId == request.auth.uid;
}
// comments 컬렉션 규칙
match /comments/{commentId} {
allow read: if isAuthenticated();
allow create: if isAuthenticated();
allow update, delete: if isAuthenticated() &&
resource.data.authorId == request.auth.uid;
}
}
}


# Firebase Storage 규칙

## 저장소 구조
/users/{uid}/profile/ # 프로필 이미지 저장
/posts/{postId}/media/ # 게시글 미디어 파일 저장


## Storage 보안 규칙
javascript
rules_version = '2';
service firebase.storage {
match /b/{bucket}/o {
// 인증된 사용자 확인
function isAuthenticated() {
return request.auth != null;
}
// 파일 크기 및 형식 검증
function isValidImage() {
return request.resource.contentType.matches('image/.')
&& request.resource.size < 5 1024 1024; // 5MB 제한
}
function isValidVideo() {
return request.resource.contentType.matches('video/.')
&& request.resource.size < 50 1024 1024; // 50MB 제한
}
// 프로필 이미지 규칙
match /users/{userId}/profile/{fileName} {
allow read: if isAuthenticated();
allow write: if isAuthenticated()
&& request.auth.uid == userId
&& isValidImage();
}
// 게시글 미디어 규칙
match /posts/{postId}/media/{fileName} {
allow read: if isAuthenticated();
allow create: if isAuthenticated()
&& (isValidImage() || isValidVideo());
allow delete: if isAuthenticated();
}
}
}


## 데이터 관리 지침

1. 데이터 정합성
   - 사용자 삭제 시 관련 게시글, 댓글 모두 삭제
   - 게시글 삭제 시 관련 댓글 및 미디어 파일 모두 삭제
   - 트랜잭션 사용하여 데이터 일관성 유지

2. 인덱싱
   - 자주 조회되는 필드에 대해 인덱스 생성
   - 복합 쿼리를 위한 복합 인덱스 설정

3. 데이터 백업
   - 정기적인 데이터 백업 실행
   - 중요 데이터 변경 시 로그 기록

## 추가 규칙

1. 보안
   - 민감한 사용자 정보는 암호화하여 저장
   - 외부 공개 필요 없는 필드는 private 설정

2. 성능
   - 대용량 미디어 파일은 압축하여 저장
   - 페이지네이션 구현으로 데이터 로딩 최적화

3. 확장성
   - 향후 기능 추가를 고려한 유연한 구조 설계
   - 데이터 마이그레이션 계획 수립

## 구현 계획 체크리스트

### 1. Firebase 초기 설정
- [x] Firebase 프로젝트 생성
- [x] iOS/Android 앱 등록
- [x] 필요한 Firebase SDK 설치
  - [x] Firebase Core
  - [x] Firebase Auth
  - [x] Cloud Firestore
  - [x] Firebase Storage

### 2. 인증 구현
- [x] 소셜 로그인 구현
  - [x] Google 로그인
- [x] 로그인 후 사용자 정보 Firestore에 저장
  - [x] users 컬렉션에 사용자 문서 생성
  - [x] 프로필 이미지 Storage 업로드

### 3. 게시글 관리 구현
- [x] 게시글 CRUD 작업
  - [x] 게시글 작성 기능
    - [x] 텍스트 내용 저장
    - [x] 이미지 파일 Storage 업로드
    - [x] mediaUrls 배열에 URL 저장
  - [x] 게시글 조회 기능
    - [x] 전체 게시글 목록 페이지네이션
    - [x] 특정 사용자의 게시글 필터링
  - [x] 게시글 수정 기능
  - [x] 게시글 삭제 기능
    - [x] Storage의 이미지 파일 삭제
    - [x] Firestore 문서 삭제

### 4. 댓글 시스템 구현
- [x] 댓글 CRUD 작업
  - [x] 댓글 작성
  - [x] 댓글 조회
  - [x] 댓글 수정
  - [x] 댓글 삭제
- [x] 게시글의 댓글 수 동기화

### 5. 미디어 파일 관리
- [x] Storage 업로드 구현
  - [x] 이미지 파일 처리
    - [x] 압축 및 리사이징
    - [x] 5MB 제한 확인
- [x] 파일 다운로드 구현
  - [x] 이미지 캐싱

### 6. 데이터 정합성 관리
- [x] 캐스케이드 삭제 구현
  - [x] 사용자 삭제 시 연관 데이터 처리
  - [x] 게시글 삭제 시 관련 데이터 처리
- [x] 트랜잭션 처리
  - [x] 댓글 수 업데이트

### 7. 성능 최적화
- [x] 인덱스 설정
  - [x] 단일 필드 인덱스
  - [x] 복합 인덱스
- [x] 쿼리 최적화
  - [x] 페이지네이션 구현
  - [x] 필요한 필드만 조회

### 8. 보안 구현
- [x] Firestore 규칙 적용
- [x] Storage 규칙 적용
- [x] 사용자 권한 검증
- [x] 데이터 유효성 검사

### 9. 에러 처리 및 로깅
- [x] 에러 핸들링 구현
  - [x] 커스텀 예외 클래스 정의
  - [x] 에러 메시지 표준화
- [x] 로깅 시스템 구축
  - [x] Crashlytics 설정
  - [x] Analytics 설정
- [x] 모니터링 설정
  - [x] 성능 모니터링
  - [x] 에러 모니터링

### 10. 테스트
- [x] 단위 테스트 작성
- [x] 통합 테스트 작성
- [x] 보안 규칙 테스트
- [x] 성능 테스트

## 작업 우선순위
1. Firebase 초기 설정 및 인증 구현
2. 기본적인 CRUD 작업 구현
3. 미디어 파일 처리 구현
4. 데이터 정합성 및 보안 구현
5. 성능 최적화 및 테스트