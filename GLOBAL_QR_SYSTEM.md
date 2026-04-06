# QR Check App - Global Participant Registration System

## 🌍 Overview

글로벌 대응 QR 기반 참가자 등록 시스템으로 업그레이드되었습니다.

### 핵심 기능
- ✅ QR 코드 생성 및 스캔
- ✅ 176개국 국적 선택
- ✅ 다국어 지원 (한국어 + 영어)
- ✅ 참가자 등록 시스템
- ✅ 실시간 참가자 관리

---

## 📦 새로 추가된 패키지

```yaml
# QR packages
qr_flutter: ^4.1.0          # QR 코드 생성
mobile_scanner: ^5.2.3      # QR 코드 스캔

# Localization
flutter_localizations       # Flutter 다국어 지원
intl: ^0.20.2              # 국제화
```

---

## 🗂️ 새로 생성된 파일

### QR 기능
1. `lib/features/qr/presentation/pages/qr_generate_page.dart` - QR 코드 생성
2. `lib/features/qr/presentation/pages/qr_scan_page.dart` - QR 코드 스캔

### 참가자 등록
3. `lib/features/participant/presentation/pages/register_participant_page.dart` - 참가자 등록

### 데이터 및 로컬라이제이션
4. `lib/core/data/country_data.dart` - 176개국 데이터
5. `lib/l10n/app_en.arb` - 영어 번역
6. `lib/l10n/app_ko.arb` - 한국어 번역
7. `l10n.yaml` - 로컬라이제이션 설정

---

## 📊 업데이트된 데이터 구조

### Firestore `participants` 컬렉션

```json
{
  "name": "string",
  "major": "string",
  "grade": "string",
  "phone": "string",
  "nationality": "string",  // ISO 국가 코드 (예: KR, US, JP)
  "checklistId": "string",
  "status": "pending" | "confirmed" | "removed",
  "createdAt": "Timestamp"
}
```

### ⚠️ 변경 사항
- **제거됨**: `department` 필드
- **추가됨**: `nationality`는 이제 ISO 국가 코드 (2자리) 저장

---

## 🎯 사용자 플로우

### 호스트 (Host)
1. 체크리스트 생성
2. QR 코드 생성 버튼 클릭
3. QR 코드 표시 및 공유
4. 참가자 승인/거부

### 참가자 (Participant)
1. QR 코드 스캔 또는 ID 입력
2. 참가자 등록 폼 작성
   - 이름
   - 전공
   - 학년
   - 전화번호
   - 국적 (176개국 선택)
3. 등록 제출
4. 호스트 승인 대기

---

## 🌐 다국어 지원

### 지원 언어
- **한국어** (ko) - 기본
- **English** (en)

### 자동 언어 감지
앱이 디바이스 언어를 자동으로 감지하여 적절한 언어로 표시합니다.

### 국가명 로컬라이제이션
- 한국어: "대한민국", "미국", "중국" 등
- English: "South Korea", "United States", "China" 등

---

## 📱 국적 선택 기능

### 특징
- ✅ 176개국 지원
- ✅ 검색 기능 (국가명 또는 코드)
- ✅ Draggable Bottom Sheet
- ✅ 언어별 국가명 표시
- ✅ 선택된 국가 강조 표시

### 데이터 구조
```dart
class CountryData {
  final String code;       // ISO 2-letter code (예: KR)
  final String nameEn;     // English name
  final String nameKo;     // Korean name
}
```

---

## 📸 QR 시스템

### QR 생성 (호스트)
- 체크리스트 ID를 QR 코드로 변환
- 복사 기능
- 공유 기능

### QR 스캔 (참가자)
- 카메라로 QR 코드 스캔
- 플래시 토글
- 카메라 전환
- 수동 ID 입력 옵션

---

## 🔐 권한 설정

### Android
`android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
```

### iOS
`ios/Runner/Info.plist`
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes</string>
```

---

## 🚀 실행 방법

### 1. 패키지 설치
```bash
flutter pub get
```

### 2. Localization 생성
```bash
flutter gen-l10n
```

### 3. 앱 실행
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 🧪 테스트 시나리오

### QR 생성
- [ ] 호스트가 QR 코드 생성 확인
- [ ] QR 코드 ID 복사 기능 확인
- [ ] QR 코드 표시 확인

### QR 스캔
- [ ] 참가자가 QR 코드 스캔 확인
- [ ] 수동 ID 입력 확인
- [ ] 등록 페이지 이동 확인

### 참가자 등록
- [ ] 모든 필드 입력 확인
- [ ] 국적 선택 (검색 포함) 확인
- [ ] 유효성 검증 확인
- [ ] Firestore 저장 확인

### 다국어
- [ ] 영어 환경에서 표시 확인
- [ ] 한국어 환경에서 표시 확인
- [ ] 국가명 로컬라이제이션 확인

### 권한
- [ ] Android 카메라 권한 요청 확인
- [ ] iOS 카메라 권한 요청 확인

---

## 🔧 문제 해결

### Localization 파일이 생성되지 않을 때
```bash
flutter clean
flutter pub get
flutter gen-l10n
```

### 카메라 권한 오류
1. Android: `AndroidManifest.xml` 확인
2. iOS: `Info.plist` 확인
3. 앱 재설치

### QR 스캔이 작동하지 않을 때
1. 카메라 권한 허용 확인
2. 조명 확인
3. QR 코드 품질 확인

---

## 📝 변경 사항 요약

### 제거된 것
- ❌ `department` 필드 (Firestore 및 모든 UI)

### 추가된 것
- ✅ QR 생성 페이지
- ✅ QR 스캔 페이지
- ✅ 참가자 등록 페이지
- ✅ 176개국 데이터
- ✅ 다국어 지원 (한국어/영어)
- ✅ 국적 선택 Bottom Sheet
- ✅ 카메라 권한 설정

### 업데이트된 것
- ✅ `profile_setup_page.dart` - 국적 선택 글로벌화
- ✅ `auth_service.dart` - department 체크 제거
- ✅ `main.dart` - 로컬라이제이션 추가

---

## 🌟 MVP 특징

### 심플함 유지
- 필수 필드만 포함
- 직관적인 UI
- 빠른 등록 프로세스

### 확장 가능
- 추가 언어 쉽게 추가 가능
- 추가 국가 쉽게 추가 가능
- Clean Architecture 유지

### 글로벌 대응
- 176개국 지원
- 다국어 UI
- ISO 표준 국가 코드 사용

---

**글로벌 QR 기반 참가자 등록 시스템 완성!** 🎉
