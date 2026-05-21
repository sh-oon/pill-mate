---
template: gap-analysis
version: 1.0
feature: cross-platform-release-readiness
date: 2026-05-20
author: gamja (assisted)
project: pill-mate
status: Draft
scope: iOS+Android App/Play Store 출시 준비 + Web/Desktop 확장성 검토
---

# 크로스플랫폼 출시 갭 분석

## 현재 상태 (verified from repo)

| 항목 | 상태 |
|------|------|
| 프레임워크 | Flutter `>=3.41.0`, Dart `^3.9.0` |
| 활성 플랫폼 | iOS, Android (web/macOS/Windows/Linux 미생성) |
| Bundle/Application ID | `com.gamja.pill_mate` |
| 버전 | `0.1.0+1` (pubspec.yaml) |
| Min OS | iOS 15.0 / Android API 26 |
| 시그니처 | iOS: 미설정 / Android: **debug 키로 release 빌드** (build.gradle.kts TODO) |
| Locale | `ko` 하드코딩 (`en` 선언만 있음, ARB 없음) |
| CI/CD | 없음 (`.github/workflows`, fastlane, codemagic 모두 부재) |
| 테스트 | `test/widget_test.dart` 1개만 존재 |
| 크래시/분석 | sentry / crashlytics 미설치 |
| 개인정보처리방침 | 미작성 (저장소 내 없음) |
| iOS Privacy Manifest | `PrivacyInfo.xcprivacy` 부재 |
| 권한 사용 설명 | iOS: `NSUserNotificationUsageDescription`만 (한국어) |

핵심 의존성: drift(SQLite), flutter_local_notifications, permission_handler, **cupertino_native_better (iOS-only PlatformView)**.

---

## A. 스토어 출시(iOS+Android) 블로커 — 필수

### A1. 코드 사이닝
- **Android**: `android/app/build.gradle.kts:34` 가 debug signingConfig 사용. release용 keystore 발급 + `key.properties` + `signingConfigs.release` 추가 필요. 누락 시 Play Console 업로드 불가.
- **iOS**: Apple Developer Program ($99/yr) 가입 + App ID 등록 + Distribution Certificate + App Store provisioning profile. Xcode `Runner > Signing & Capabilities`에서 Team 지정.

### A2. iOS Privacy Manifest (`PrivacyInfo.xcprivacy`)
- 2024-05 이후 App Store 신규 업로드 시 **필수**. `ios/Runner/PrivacyInfo.xcprivacy` 신규 작성 필요.
- 선언 대상: `NSPrivacyAccessedAPITypes` (UserDefaults, FileTimestamp 등), `NSPrivacyTracking=false`, 수집 데이터 없음 선언.

### A3. Android target SDK 갱신
- Play Store: 신규 앱은 Android 14(API 34) 타깃. 2025-08부터 Android 15(API 35). 현재 `targetSdk = flutter.targetSdkVersion` 위임 — 사용 Flutter 버전 확인 필요.
- `USE_FULL_SCREEN_INTENT` 권한: Android 14+ **restricted permission**. 신규 앱은 Play Console에서 정당화(의료/알람 카테고리) 제출하지 않으면 자동 거부.

### A4. iOS Background Modes 정합성
- `Info.plist`의 `UIBackgroundModes`: `fetch`, `processing`, `remote-notification` 선언됨.
- `processing` 사용 시 `BGTaskSchedulerPermittedIdentifiers` 키로 task identifier 명시 안 하면 App Store Review에서 reject. 현재 plist에 해당 키 **없음** → 확인 필요. `remote-notification` 도 실제 푸시 사용 안 하면 제거 권장 (이 앱은 local notification만 사용).

### A5. 개인정보처리방침 + 데이터 안전
- iOS App Privacy: 수집 없음(오프라인 앱)이라도 App Store Connect 양식 작성 필수.
- Play Console **Data Safety form**: 약물 정보 = 건강 데이터 카테고리. "수집 안 함, 기기 내 저장만" 명시 필요.
- 공개 호스팅된 Privacy Policy URL 필수 (GitHub Pages / Notion / personal site로 OK).

### A6. 스토어 자산
- 앱 아이콘: iOS 1024×1024 마스터, Android 512×512 + adaptive icon (foreground+background). `flutter_native_splash` / `flutter_launcher_icons` 도입 권장.
- 스크린샷: iOS 6.7"·6.5"·5.5" 각 3~10장 + iPad 12.9"; Android 폰+태블릿 각 2장+.
- 짧은 설명, 긴 설명, 키워드, promo 영상(선택).

### A7. 버전 정책
- `0.1.0+1` → 출시 시 `1.0.0+1`로 승격. 이후 빌드 번호는 단조 증가 필수 (TestFlight/Play 내부 테스트에서 동일 빌드 번호 재업로드 불가).

---

## B. 품질/안정성 갭 — 강력 권장

### B1. 테스트 커버리지
- 현재 `widget_test.dart` 1개. 약 등록·알림 스케줄·미복용 처리 등 **앱의 핵심 가치 경로 0% 커버**.
- 권장 최소:
  - drift DB 마이그레이션 unit test
  - `medication_notification_manager.syncAll` 동작 검증
  - notification deep link payload 파싱 (`parseDosePayload`)
  - 1~2개 골든 widget test (HomeScreen, MedicationDetail)

### B2. 크래시·로그 수집
- 출시 후 issue triage 불가. `sentry_flutter` 또는 `firebase_crashlytics` 도입 필요.
- 오프라인 앱이라 익명 crash 전송만 동의 받기 (개인정보 무관).

### B3. CI/CD
- 현재 0개 워크플로. 최소 구성:
  - PR 시 `flutter analyze` + `flutter test`
  - main merge 시 Android `aab`, iOS `ipa` 빌드
  - 태그 push 시 TestFlight / Play Internal Track 자동 업로드 (fastlane 또는 Codemagic)

### B4. 국제화 (Locale)
- `main.dart:14`: `initializeDateFormatting('ko')` 하드코딩.
- `app.dart`: `locale: const Locale('ko')` 하드코딩 (시스템 locale 따라가지 않음).
- `pubspec.yaml`: `flutter: generate: true` 활성화되어 있으나 `lib/l10n/` 디렉토리 + `l10n.yaml` + `.arb` 파일 없음.
- 한국 단일 출시면 OK. 글로벌은 ARB 인프라 + 동적 locale resolver 필요.

### B5. 접근성
- 폰트 스케일/스크린리더 검증 흔적 없음. Pretendard 사용 → `MediaQuery.textScaleFactor` 대응 확인 필요.

---

## C. 진짜 "크로스플랫폼" 확장 (Web / Desktop)

> Flutter는 web/macOS/Windows/Linux를 모두 지원하지만 이 앱은 **mobile 전용 의존성**이 많아 그대로 못 옮김.

| 의존성 | Web | macOS | Windows | Linux | 비고 |
|--------|-----|-------|---------|-------|------|
| `cupertino_native_better` | ❌ | ❌ | ❌ | ❌ | iOS PlatformView 전용. 대체 위젯 필요 |
| `flutter_local_notifications` | △ | ✅ | ✅ | ✅ | web은 브라우저 Notification API 한정, 백그라운드 알람 불가 |
| `drift` + `sqlite3_flutter_libs` | △ | ✅ | ✅ | ✅ | web은 `drift/wasm` 별도 |
| `permission_handler` | ❌ | △ | ❌ | ❌ | 데스크톱 대부분 N/A |
| `flutter_timezone` | △ | ✅ | ✅ | ✅ | web은 브라우저 TZ |
| `path_provider` | ❌ | ✅ | ✅ | ✅ | web은 브라우저 스토리지 |

**현실 평가**:
- **Web**: 백그라운드 알람 = 앱의 핵심 가치인데 PWA에선 OS push 없이는 불가능. 출시 가치 낮음.
- **macOS/Windows/Linux**: 기술적으로 가능하나 `cupertino_native_better`를 platform-conditional로 격리하고, 데스크톱용 UI 레이아웃 별도 작업 필요. 약 복용은 모바일에 휴대하는 시나리오라 ROI 낮음.

**권장**: 모바일 2종 안정화 → v1.x 출시 후 사용자 요청 시 Web(읽기 전용 대시보드)부터 검토.

---

## D. 우선순위 로드맵

### Sprint 1 — 출시 블로커 해소 (1~2주)
1. Android keystore + release signingConfig (A1)
2. iOS Apple Developer 등록 + provisioning (A1)
3. `PrivacyInfo.xcprivacy` 작성 (A2)
4. `Info.plist` background modes 정리 + `BGTaskSchedulerPermittedIdentifiers` (A4)
5. `USE_FULL_SCREEN_INTENT` 정당화 문서 준비 (A3)
6. 버전 1.0.0+1 승격 (A7)

### Sprint 2 — 스토어 제출 (1주)
7. 앱 아이콘/스플래시 (A6)
8. 스크린샷 + 스토어 카피라이팅 (A6)
9. Privacy Policy 호스팅 + Data Safety form (A5)
10. TestFlight / Play Internal Track 첫 업로드

### Sprint 3 — 출시 후 안정성 (병행)
11. Sentry/Crashlytics 통합 (B2)
12. 핵심 경로 테스트 5종 (B1)
13. GitHub Actions PR check + release 자동화 (B3)

### Sprint 4 — 옵션
14. 영어 ARB (B4) — 글로벌 출시 결정 시
15. 접근성 감사 (B5)
16. Web/Desktop 평가 (C)

---

## E. 확인 필요 (사용자 결정 사항)

- 출시 대상 국가: 한국만 vs. 글로벌? → B4 ARB 작업 범위 결정
- Apple Developer 계정 보유 여부?
- 분석/크래시 수집 동의 정책: 완전 오프라인 유지 vs. 익명 crash만 허용?
- 홈 위젯 (계획서 1.2 언급): 현재 구현되지 않음 — 출시 전 포함 여부?
- 사전 알림(pre-reminder), 긴급 재시도(urgent retry) 기능 안정화 검증 완료 여부 (docs/02-design/05)?
