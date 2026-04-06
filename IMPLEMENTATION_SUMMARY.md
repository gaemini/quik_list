# 온보딩 시스템 구현 완료 요약

## ✅ 완료된 작업

### 1. 소셜 로그인 추가
- **Google 로그인** - Android와 iOS 모두 지원
- **Apple 로그인** - iOS 전용 (Android에서는 자동으로 숨김)
- 기존 이메일/비밀번호 로그인 유지

### 2. 프로필 설정 페이지 생성
새로운 파일: `lib/features/auth/presentation/pages/profile_setup_page.dart`

입력 필드:
- 이름 (필수)
- 학과 (필수)
- 전공 (필수)
- 학년 (드롭다운, 필수)
- 전화번호 (필수)
- 국적 (드롭다운, 필수)

### 3. 서비스 레이어 업데이트

#### `auth_service.dart` 추가 메서드
```dart
Future<UserCredential> signInWithGoogle()
Future<UserCredential> signInWithApple()
Future<bool> isProfileComplete(String uid)
```

#### `firestore_service.dart` 추가 메서드
```dart
Future<void> createUserProfile(String userId, Map<String, dynamic> profileData)
Future<Map<String, dynamic>?> getUserProfile(String uid)
```

### 4. 네비게이션 로직 구현

`main.dart`의 `AuthWrapper` 업데이트:
```
미로그인 → LoginPage
로그인 + 프로필 미완성 → ProfileSetupPage
로그인 + 프로필 완성 → HomePage
```

### 5. UI/UX 개선

**LoginPage 업데이트:**
- 기존 이메일 로그인 영역
- 구분선 ("또는")
- 소셜 로그인 섹션
  - Google 버튼 (모든 플랫폼)
  - Apple 버튼 (iOS만)

### 6. 패키지 추가
```yaml
google_sign_in: ^6.2.2
sign_in_with_apple: ^6.1.4
```

---

## 📱 사용자 플로우

### 신규 사용자 (소셜 회원가입)
1. LoginPage 접근
2. "Google 계정으로 계속하기" 또는 "Apple 계정으로 계속하기" 선택
3. 소셜 로그인 진행
4. **자동으로 ProfileSetupPage로 이동**
5. 필수 프로필 정보 입력
6. "프로필 저장하고 시작하기" 클릭
7. HomePage로 이동

### 기존 사용자 (재로그인)
1. LoginPage 접근
2. 소셜 로그인 선택
3. 프로필이 이미 존재하므로 **바로 HomePage로 이동**

---

## 🔒 보안 및 데이터 구조

### Firestore 사용자 문서
컬렉션: `users`
문서 ID: Firebase Auth UID

```json
{
  "uid": "string",
  "email": "string",
  "name": "string",
  "department": "string",
  "major": "string",
  "grade": "string",
  "phone": "string",
  "nationality": "string",
  "provider": "google" | "apple" | "email",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

---

## ⚙️ Firebase 설정 필요 사항

### Google 로그인
1. Firebase Console → Authentication → Google 활성화
2. **Android**: SHA-1 등록 필요
3. **iOS**: `Info.plist`에 URL scheme 추가 필요

### Apple 로그인 (iOS만)
1. Firebase Console → Authentication → Apple 활성화
2. Apple Developer Account 설정 필요
3. Xcode: Sign In with Apple Capability 추가 필요

자세한 설정 방법은 `ONBOARDING_SETUP.md` 참고

---

## 🎯 핵심 기능

### 프로필 완성 확인
`AuthService.isProfileComplete(uid)` 메서드가 다음을 확인:
- Firestore에 사용자 문서 존재 여부
- 모든 필수 필드 존재 및 null이 아닌지 확인

### 플랫폼별 조건부 렌더링
```dart
if (Platform.isIOS)
  // Apple 로그인 버튼만 표시
```

### 프로필 설정 필수화
- 프로필 설정 페이지는 뒤로가기 불가 (`automaticallyImplyLeading: false`)
- 모든 필드가 필수 입력
- 프로필 저장 전까지 앱 사용 불가

---

## 📋 테스트 체크리스트

### 필수 테스트
- [ ] Google 로그인 (Android)
- [ ] Google 로그인 (iOS)
- [ ] Apple 로그인 (iOS)
- [ ] 첫 로그인 → 프로필 설정 페이지 이동
- [ ] 프로필 저장 → Firestore 데이터 확인
- [ ] 재로그인 → 바로 홈 페이지 이동
- [ ] 기존 이메일 로그인 정상 작동

### 에러 처리 테스트
- [ ] Google 로그인 취소 처리
- [ ] Apple 로그인 취소 처리
- [ ] 프로필 입력 유효성 검증
- [ ] 네트워크 오류 처리

---

## 📁 변경된 파일

### 새로 생성된 파일
1. `lib/features/auth/presentation/pages/profile_setup_page.dart`
2. `ONBOARDING_SETUP.md` (설정 가이드)

### 수정된 파일
1. `pubspec.yaml` - 패키지 추가
2. `lib/features/auth/presentation/pages/login_page.dart` - UI 및 소셜 로그인 추가
3. `lib/core/services/auth_service.dart` - Google/Apple 로그인 메서드 추가
4. `lib/core/services/firestore_service.dart` - 프로필 관련 메서드 추가
5. `lib/main.dart` - AuthWrapper 로직 업데이트

---

## 🚀 다음 단계

### Firebase Console 설정 (필수)
1. Authentication에서 Google 로그인 활성화
2. Authentication에서 Apple 로그인 활성화 (iOS 배포 시)
3. Firestore 보안 규칙 설정

### 플랫폼별 설정 (필수)
1. **Android**: SHA-1 생성 및 Firebase에 등록
2. **iOS**: Xcode에서 Sign In with Apple Capability 추가
3. **iOS**: `Info.plist`에 Google URL scheme 추가

### 개발 및 테스트
```bash
# 패키지 설치 완료
flutter pub get  # ✅ 완료

# 앱 실행
flutter run

# 코드 분석
flutter analyze  # ✅ 완료 (경고만 있음, 에러 없음)
```

---

## ⚠️ 중요 사항

1. **프로필 설정은 건너뛸 수 없습니다** - 사용자 신원 확인을 위한 필수 정보
2. **Apple 로그인은 iOS 전용** - Android에서는 버튼이 표시되지 않음
3. **Google 로그인은 SHA-1 필수** - Android에서 작동하려면 Firebase에 SHA-1 등록 필요
4. **Firestore 보안 규칙 설정** - 프로덕션 배포 전 반드시 설정

---

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. Firebase Console 설정이 완료되었는지
2. SHA-1이 등록되었는지 (Android)
3. Xcode Capability가 추가되었는지 (iOS)
4. `google-services.json` / `GoogleService-Info.plist`가 최신인지

자세한 문제 해결 방법은 `ONBOARDING_SETUP.md` 참고

---

**구현 완료!** 🎉

Clean Architecture 스타일을 유지하면서 확장 가능한 온보딩 시스템이 완성되었습니다.
