# QR Check App - 온보딩 시스템 구현 완료

## 구현 완료 내용

### 1. 인증 시스템 업그레이드

#### 추가된 로그인 방식
- ✅ Google 로그인
- ✅ Apple 로그인 (iOS 전용)
- ✅ 기존 이메일/비밀번호 로그인 유지

### 2. 새로운 파일

#### `lib/features/auth/presentation/pages/profile_setup_page.dart`
첫 로그인 후 사용자 프로필 입력 페이지
- 이름
- 학과
- 전공
- 학년 (드롭다운)
- 전화번호
- 국적 (드롭다운)

### 3. 업데이트된 파일

#### `lib/features/auth/presentation/pages/login_page.dart`
- 이메일 로그인 영역
- 소셜 로그인 영역 추가
  - Google 계정으로 계속하기 버튼
  - Apple 계정으로 계속하기 버튼 (iOS만 표시)

#### `lib/core/services/auth_service.dart`
새로운 메서드 추가:
- `signInWithGoogle()` - Google 로그인
- `signInWithApple()` - Apple 로그인 (iOS 전용)
- `isProfileComplete(uid)` - 프로필 완성 여부 확인

#### `lib/core/services/firestore_service.dart`
새로운 메서드 추가:
- `createUserProfile(userId, profileData)` - 사용자 프로필 생성
- `getUserProfile(uid)` - 사용자 프로필 조회

#### `lib/main.dart`
AuthWrapper 업데이트:
- 로그인하지 않음 → LoginPage
- 로그인했지만 프로필 미완성 → ProfileSetupPage
- 프로필 완성 → HomePage

### 4. Firestore 사용자 데이터 구조

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

### 5. 새로운 패키지

```yaml
dependencies:
  google_sign_in: ^6.2.2
  sign_in_with_apple: ^6.1.4
```

---

## Firebase 설정 필요 사항

### Google 로그인 설정

#### 1. Firebase Console
1. Firebase Console → Authentication → Sign-in method
2. Google 활성화
3. 프로젝트 지원 이메일 설정

#### 2. Android 설정
1. `android/app/build.gradle`에서 SHA-1 추가 필요
2. Firebase Console에서 SHA-1 등록
3. `google-services.json` 다운로드 및 교체

```bash
# SHA-1 확인
cd android
./gradlew signingReport
```

#### 3. iOS 설정
1. `ios/Runner/Info.plist`에 URL scheme 추가
2. Firebase Console에서 iOS 앱의 `GoogleService-Info.plist` 다운로드
3. Xcode에서 프로젝트에 추가

`Info.plist`에 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

### Apple 로그인 설정 (iOS 전용)

#### 1. Firebase Console
1. Firebase Console → Authentication → Sign-in method
2. Apple 활성화
3. Service ID 생성 및 설정

#### 2. Apple Developer Account
1. Certificates, Identifiers & Profiles
2. Identifiers → App IDs
3. Sign In with Apple 기능 활성화
4. Services ID 생성

#### 3. iOS 설정
1. Xcode에서 Signing & Capabilities
2. "+ Capability" → Sign In with Apple 추가

---

## 사용자 플로우

### 첫 회원가입 사용자
1. LoginPage에서 "Google 계정으로 계속하기" 또는 "Apple 계정으로 계속하기" 선택
2. 소셜 로그인 완료
3. 자동으로 ProfileSetupPage로 이동
4. 프로필 정보 입력 (필수)
5. "프로필 저장하고 시작하기" 버튼 클릭
6. HomePage로 이동

### 기존 사용자
1. LoginPage에서 소셜 로그인 선택
2. 로그인 완료
3. 프로필이 이미 존재하므로 바로 HomePage로 이동

---

## 플랫폼별 처리

### iOS
- Google 로그인 버튼 표시 ✅
- Apple 로그인 버튼 표시 ✅

### Android
- Google 로그인 버튼 표시 ✅
- Apple 로그인 버튼 숨김 ✅

`Platform.isIOS`를 사용하여 조건부 렌더링

---

## 테스트 체크리스트

### Google 로그인
- [ ] Android에서 Google 로그인 작동 확인
- [ ] iOS에서 Google 로그인 작동 확인
- [ ] 첫 로그인 시 프로필 설정 페이지로 이동 확인
- [ ] 프로필 입력 후 저장 확인
- [ ] 재로그인 시 바로 홈으로 이동 확인

### Apple 로그인
- [ ] iOS에서 Apple 로그인 작동 확인
- [ ] Android에서 Apple 버튼 숨김 확인
- [ ] 첫 로그인 시 프로필 설정 페이지로 이동 확인
- [ ] 프로필 입력 후 저장 확인

### 프로필 설정
- [ ] 모든 필수 필드 입력 확인
- [ ] 학년 드롭다운 작동 확인
- [ ] 국적 드롭다운 작동 확인
- [ ] 유효성 검증 작동 확인
- [ ] Firestore에 데이터 저장 확인

### 기존 기능
- [ ] 이메일 로그인 정상 작동
- [ ] 이메일 회원가입 정상 작동
- [ ] 로그아웃 정상 작동

---

## 다음 단계

### Firebase Console 설정
1. Google 로그인 활성화
2. Apple 로그인 활성화 (iOS 배포 시)
3. Firestore 보안 규칙 설정

### Firestore 보안 규칙 예시
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 개발 환경 설정
```bash
# 패키지 설치
flutter pub get

# Android 실행
flutter run

# iOS 실행 (Mac only)
flutter run -d ios
```

---

## 주의사항

1. **프로필 설정 페이지는 건너뛸 수 없습니다** - 필수 사용자 정보이므로 반드시 입력해야 합니다.
2. **Apple 로그인은 iOS에서만 작동합니다** - Android에서는 버튼이 표시되지 않습니다.
3. **Google 로그인은 SHA-1 등록이 필요합니다** - Firebase Console에 SHA-1을 등록해야 Android에서 작동합니다.
4. **개발자 모드 경고는 무시 가능** - Windows에서 나타나는 symlink 경고는 빌드에 영향을 주지 않습니다.

---

## 문제 해결

### Google 로그인이 작동하지 않을 때
1. Firebase Console에서 Google 로그인이 활성화되어 있는지 확인
2. Android: SHA-1이 Firebase Console에 등록되어 있는지 확인
3. iOS: `GoogleService-Info.plist`가 Xcode 프로젝트에 있는지 확인
4. `google-services.json` / `GoogleService-Info.plist` 최신 버전인지 확인

### Apple 로그인이 작동하지 않을 때
1. Firebase Console에서 Apple 로그인이 활성화되어 있는지 확인
2. Apple Developer Console에서 Sign In with Apple 기능이 활성화되어 있는지 확인
3. Xcode의 Signing & Capabilities에 Sign In with Apple이 추가되어 있는지 확인

### 프로필이 계속 요청될 때
1. Firestore에 사용자 문서가 제대로 생성되었는지 확인
2. 모든 필수 필드가 저장되었는지 확인
3. Firebase Console의 Firestore에서 데이터 확인

---

구현이 완료되었습니다! 🎉
