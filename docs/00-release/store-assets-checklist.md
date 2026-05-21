# 스토어 자산 체크리스트

## 앱 아이콘

### iOS (`ios/Runner/Assets.xcassets/AppIcon.appiconset`)
- [ ] 1024×1024 마스터 아이콘 (App Store용, PNG, alpha 채널 없음)
- [ ] 디바이스별 사이즈 자동 생성 → `flutter_launcher_icons` 또는 Xcode "Single Size" 옵션 활용

### Android
- [ ] 512×512 Play Store 등록용 아이콘
- [ ] **Adaptive Icon** (`android/app/src/main/res/mipmap-*/`):
  - [ ] `ic_launcher_foreground.png` (전경, 108×108dp safe zone)
  - [ ] `ic_launcher_background.xml` 또는 color (단색 권장)
- [ ] 권장 도구: `pubspec.yaml`에 `flutter_launcher_icons: ^0.14.x` dev-dep 추가 후 `flutter pub run flutter_launcher_icons`

## 스플래시 스크린

### iOS
- 현재 `LaunchScreen.storyboard` 사용. 디자인 통일 시 `flutter_native_splash` 도입 권장.

### Android
- 현재 `LaunchTheme` style 사용. Android 12+ Splash Screen API 자동 적용됨.

## 스크린샷

### iOS App Store (각 최소 1장, 최대 10장)
- [ ] **6.7"** (iPhone 16/15/14 Pro Max) — 1290×2796 (필수)
- [ ] **6.5"** (iPhone 14 Plus/11 Pro Max) — 1242×2688 (필수)
- [ ] **5.5"** (iPhone 8 Plus) — 1242×2208 (deprecated, 필요시)
- [ ] **iPad Pro 12.9"** — 2048×2732 (iPad 지원 시 필수)
- [ ] **iPad Pro 11"** — 1668×2388 (선택)

### Google Play
- [ ] **폰**: 1080×1920 ~ 7680×7680, 최소 2장 (권장 4~8장)
- [ ] **태블릿 7"**: 1024×600 ~ 7680×7680
- [ ] **태블릿 10"**: 1280×800 ~ 7680×7680
- [ ] **Feature graphic**: 1024×500 (필수)

### 스크린샷 추천 컷
1. 홈 화면 (오늘 복용 일정 + 진행도)
2. 약 추가 플로우 (이름 + 시간 + 주기 입력)
3. 알림 수신 화면 (lock screen 또는 heads-up)
4. 캘린더 (월별 복용 현황 visualization)
5. 리포트 (주간/월간/연간 통계)
6. 약 서랍 (drawer) — 등록된 약 리스트

## 스토어 카피라이팅

### 앱 이름
- iOS / Android 공통: **필메이트** (현지화 시 영문: **Pill Mate**)

### 짧은 설명 (Short description, Play 80자 / App Store subtitle 30자)
- 후보 1: `오프라인 복약 알리미 — 광고 없음, 회원가입 없음`
- 후보 2: `복용 시간을 정확히, 누락 없이`
- 후보 3: `Offline medication reminder, no account required`

### 긴 설명 (Long description, Play 4000자 / App Store 4000자)
초안:
```
필메이트는 약과 영양제 복용 시간을 잊지 않도록 도와주는 완전 오프라인 알리미입니다.
회원가입, 로그인, 인터넷 연결 없이 동작합니다.

핵심 기능
• 복용 시간 정확한 알림 — 분 단위 예약, 미복용 시 긴급 재알림
• 약 서랍 — 등록한 약을 검색·정렬로 빠르게 찾기
• 캘린더 — 월별 복용 현황을 한눈에
• 리포트 — 주간/월간/연간 복용 추이
• 사전 알림 — 복용 N분 전 미리 알려주는 옵션
• 다크 모드 자동 전환

개인정보 보호
• 모든 데이터는 기기 안에만 저장됩니다.
• 외부 서버로 어떤 정보도 전송하지 않습니다.
• 광고 SDK, 분석 SDK 사용하지 않습니다.

추천 대상
• 만성질환으로 정해진 시간에 복용해야 하는 분
• 영양제 루틴을 만들고 싶은 분
• 외부 동기화 없이 개인적으로 관리하고 싶은 분
```

### 키워드 (App Store ASO, 100자)
- `필메이트,약,약알리미,복약,복약알람,영양제,건강,오프라인,알람,리마인더`

### 카테고리
- **Primary**: Medical (의료) — 약 복용 관리는 의료 도구로 분류 권장
- **Secondary**: Health & Fitness (건강 및 피트니스)

## 콘텐츠 등급

### App Store
- 4+ (만 4세 이상, 의료/건강 정보 제공)

### Google Play (IARC)
- Everyone / 전체이용가
- 건강·의료 정보를 다루지만 의약 처방 제공 안 함 → 등급 영향 없음

## 출시 전 마지막 체크

- [ ] `pubspec.yaml`의 `version: 0.1.0+1` → `1.0.0+1`로 승격
- [ ] `pubspec.yaml`의 `publish_to: 'none'` 유지 (pub.dev 자동 게시 방지)
- [ ] iOS bundle display name: `필메이트` 확인 (Info.plist:10)
- [ ] Android label: `필메이트` 확인 (AndroidManifest.xml application label)
- [ ] iOS deployment target: 15.0 이상 (Podfile)
- [ ] Android `targetSdk`: 34 이상 (Play 2024 요건)
- [ ] 모든 권한이 실제로 사용되고 있는지 grep 확인
