---
template: plan
version: 1.2
feature: medication-tracker
date: 2026-05-18
author: gamja
project: medication-tracker
platform: Flutter (iOS + Android)
status: Draft
---

# medication-tracker Planning Document

> **Summary**: 영양제·약 복용 일정을 등록하면 로컬 푸시 알람·홈 위젯·캘린더로 알려주고, 연속 복용·빈도·최근 추이 리포트를 제공하는 **오프라인 전용** Flutter 크로스플랫폼 앱.
>
> **Project**: medication-tracker
> **Version**: 0.1.0
> **Platform**: Flutter 3.27+ / Dart 3.5+ (iOS + Android)
> **Author**: gamja
> **Date**: 2026-05-18
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 영양제·약을 챙기는 일정이 불규칙하면 복용을 자주 놓치고, 기존 앱들은 계정/네트워크를 요구하거나 홈 위젯·리포트가 빈약해 일상에서 신뢰하기 어렵다. |
| **Solution** | 모든 데이터를 디바이스 로컬(Drift)에 저장하는 오프라인 전용 Flutter 앱. 정확한 시각의 로컬 푸시 + 홈 위젯 + 캘린더 + 복용 패턴 리포트를 단일 패키지로 제공. |
| **Function/UX Effect** | 가입·로그인·네트워크 없이 즉시 사용 가능. 홈 화면에서 한 번에 오늘 복용 체크, 알람 신뢰성(롤링 스케줄 + 정확한 알람 권한 가이드)으로 누락 최소화. |
| **Core Value** | "복용을 잊지 않게 해주는, 내 기기 안에서만 작동하는 가장 빠르고 사적인 도구." 프라이버시 + 신뢰성 + 즉시성. |

---

## 1. Overview

### 1.1 Purpose

매일 정해진 시간에 영양제·약을 복용해야 하는 사용자가, **계정 가입이나 서버 연결 없이** 자신의 기기에서만 복약 스케줄을 관리하고 정확한 시각에 알림을 받을 수 있도록 한다. 또한 복용 이력을 시각화한 리포트로 행동 변화 동기를 제공한다.

### 1.2 Background

- 대부분의 복약 알림 앱이 회원가입·클라우드 동기화·구독결제를 요구해 진입장벽이 높음
- 의료/건강 데이터는 사용자가 외부 서버 전송을 꺼리는 경향이 강함 (개인정보 민감도)
- iOS/Android 모두 홈 위젯 지원이 성숙했지만, 양 플랫폼에서 동일 UX를 제공하는 앱이 드뭄
- 단순 알람만 있는 앱은 "복용 안 함" 처리·연속 복용(streak) 등 행동 변화 유도 기능이 부족
- Flutter 3.27 + Impeller 안정화로 단일 코드베이스 + 네이티브 수준 성능 확보 가능

### 1.3 Related Documents

- Design: `docs/02-design/features/medication-tracker.design.md` (예정)
- 참고: Flutter 공식 문서, drift.simonbinder.eu, flutter_local_notifications README

---

## 2. Scope

### 2.1 In Scope

- [ ] **약/영양제 등록**: 이름, 용량, 색상/형태, 메모, 아이콘
- [ ] **스케줄 등록**: 매일 / 주N회(요일 선택) / N일마다 / 시각(다중)
- [ ] **로컬 푸시 알람**: 정확한 시각, 스누즈, 액션 버튼(복용 완료 / 건너뜀)
- [ ] **홈 위젯**: iOS WidgetKit + Android AppWidget (소/중 사이즈)
- [ ] **캘린더 뷰**: 월간(복용률 색상), 일간(타임라인)
- [ ] **복용 체크 UI**: 오늘 일정 리스트, 한 번에 체크
- [ ] **리포트**: 연속 복용(streak), 약별 복용률, 시간대별 패턴, 최근 7/30/90일 추이
- [ ] **데이터 백업/복원**: JSON 파일 export/import (사용자 수동)
- [ ] **다크 모드 / 한국어·영어**
- [ ] **권한 온보딩**: 알림, 정확한 알람, 배터리 최적화 가이드

### 2.2 Out of Scope

- 서버 동기화, 클라우드 백업 (Phase 2 검토)
- 가족/공유 알림 (멀티 디바이스 동기화 불가)
- 처방전 OCR / 약물 상호작용 DB
- 의사·약사 연결 / 원격진료
- 약국 위치 검색
- 결제·구독 (완전 무료 또는 후속 일회성 인앱결제)
- 웹/데스크톱 빌드 (모바일 우선)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 약/영양제 CRUD (이름, 용량, 색상, 형태, 메모, 아이콘) | High | Pending |
| FR-02 | 복용 스케줄 CRUD (매일/주N회/N일마다, 시각 다중, 시작·종료일) | High | Pending |
| FR-03 | 로컬 푸시 알람 예약·취소·재예약 (롤링 스케줄링) | High | Pending |
| FR-04 | 알림 액션 버튼: "복용 완료" / "10분 후 다시" / "건너뜀" | High | Pending |
| FR-05 | 복용 기록 (IntakeLog) 자동 생성 및 사용자 수동 보정 | High | Pending |
| FR-06 | 홈 위젯 (iOS WidgetKit + Android AppWidget) — 오늘 일정 + 체크 액션 | High | Pending |
| FR-07 | 캘린더 뷰 (월간 복용률 색상, 일간 타임라인) | High | Pending |
| FR-08 | 리포트: 연속 복용 일수 (streak), 복용률 %, 시간대 분포, 7/30/90일 추이 차트 | High | Pending |
| FR-09 | 권한 온보딩 플로우 (알림, 정확한 알람, 배터리 최적화) | High | Pending |
| FR-10 | 데이터 백업/복원 (JSON 파일 export/import via share_plus) | Medium | Pending |
| FR-11 | 다크 모드 자동 전환 + 수동 토글 | Medium | Pending |
| FR-12 | 국제화: 한국어 / 영어 | Medium | Pending |
| FR-13 | 미복용 자동 처리 (예정시각 +N분 경과 시 missed) | Medium | Pending |
| FR-14 | 약 검색 (Drift FTS5, 한글 초성 검색 포함) | Low | Pending |
| FR-15 | 앱 잠금 (생체 인증, `local_auth`) | Low | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| **성능** | 앱 콜드 스타트 < 2초, 알람 트리거 정확도 ±30초 | Flutter DevTools, 수동 테스트 |
| **신뢰성** | 알람 누락률 < 1% (정상 권한 부여 시) | 7일 자체 사용 + 디바이스 로그 |
| **저장 효율** | 1년 데이터(약 10개 × 3회/일) DB < 5MB | sqlite_browser 측정 |
| **호환성** | iOS 15+, Android 10+ (SDK 29+) | targetSdk / minIOS 설정 |
| **접근성** | TalkBack/VoiceOver 호환, 동적 폰트 크기, 색맹 대비 | Accessibility Scanner |
| **개인정보** | 외부 네트워크 호출 0건 (옵션 OTA/크래시 제외) | Charles Proxy 검증 |
| **배터리** | 백그라운드 5% 미만 (workmanager 1시간 주기) | Battery Historian (Android) |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] FR-01 ~ FR-13 모두 구현 완료 (FR-14, FR-15는 차기 버전 가능)
- [ ] iOS 15+ / Android 10+ 실기기 알람 동작 검증
- [ ] 홈 위젯 양 플랫폼 동작 검증
- [ ] 위젯 ↔ 앱 데이터 동기화 검증 (복용 체크 즉시 반영)
- [ ] 다크 모드 / 라이트 모드 전 화면 검증
- [ ] 한국어 / 영어 번역 완료
- [ ] 단위 테스트 + 위젯 테스트 작성 (도메인 로직 우선)
- [ ] Patrol로 E2E 시나리오 1개 이상 (알람 권한 → 약 등록 → 복용 체크)
- [ ] PRIVACY.md / README.md 작성

### 4.2 Quality Criteria

- [ ] `flutter analyze` 에러 0건
- [ ] 핵심 도메인 (스케줄링, 리포트 계산) 테스트 커버리지 ≥ 80%
- [ ] `flutter build ipa` / `flutter build appbundle` 성공
- [ ] 콜드 스타트 < 2초 (중급 기기 기준)
- [ ] 알람 트리거 7일 연속 누락 0건 (개인 검증)

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **iOS 로컬 알림 64개 한도** | High | High | 앱 실행/포그라운드 진입 시 향후 N일치만 예약하는 **롤링 스케줄링**. WorkManager(Android) / BGTask(iOS)로 주기 갱신 |
| **Android 14+ SCHEDULE_EXACT_ALARM 권한 거부** | High | Medium | 권한 미부여 시 inexact 알람으로 폴백 + 사용자에게 명시적 안내. 정확도 떨어진다는 경고 표시 |
| **제조사별 배터리 최적화 (샤오미·오포·삼성)** | High | High | 첫 실행 시 가이드 다이얼로그 + `permission_handler`로 IgnoreBatteryOptimizations 요청. 디바이스별 설정 링크 제공 |
| **홈 위젯 ↔ 앱 데이터 동기화 지연** | Medium | Medium | 복용 체크 시 즉시 위젯 갱신 호출 + WorkManager 1시간 주기 백업. 위젯용 요약 JSON 별도 저장 |
| **시간대 변경 / DST 처리 버그** | Medium | Low | `timezone` 패키지 + `tz.local` 일관 사용. 로컬 시간대 변경 감지 시 모든 알람 재예약 |
| **Drift 마이그레이션 실패로 데이터 손실** | High | Low | 스키마 변경 전 자동 백업 파일 생성. `schema_version` 단계별 마이그레이션, 롤백 시나리오 |
| **Isar 메인테이너 활동 둔화 (대안 검토 시)** | Medium | - | Drift 기본 채택으로 회피. (검토했으나 NoSQL 불필요) |
| **사용자 데이터 유실 두려움** | High | Medium | JSON 백업/복원 기능 (FR-10) + 주기적 백업 권유 알림 |
| **알람 권한 거부 사용자의 신뢰성 하락** | High | Medium | 권한 거부 시 앱 사용 가능하지만 상단 배너로 지속 안내. 통계에 "알림 미동작" 라벨 |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | 단일 모듈, 단순 구조 | 정적 사이트, 데모 | ☐ |
| **Dynamic** | Feature-based, 로컬/원격 데이터 통합 | 모바일 앱, MVP, SaaS | ☑ |
| **Enterprise** | 엄격한 레이어, DI, 멀티 모듈 | 대규모 시스템 | ☐ |

→ **Dynamic** 선택. Feature-based 모듈 구조 + 로컬 DB(Drift). bkit Dynamic 템플릿은 BaaS 가정하지만 본 앱은 **로컬 DB로 대체**.

### 6.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| **Framework** | Flutter / React Native / Native | **Flutter 3.27+** | 단일 코드, Impeller, 위젯·캘린더 패키지 성숙 |
| **언어** | Dart 3.x | **Dart 3.5+** | 패턴 매칭, 레코드, sealed class로 도메인 모델링 |
| **상태 관리** | Riverpod / Bloc / Signals / Provider | **Riverpod 2.x** | AsyncNotifier로 DB 비동기 자연스러움, 코드젠 안전성 |
| **라우팅** | go_router / auto_route | **go_router** | 선언적, 딥링크, Flutter 팀 공식 권장 |
| **로컬 DB** | Drift / Isar / ObjectBox / Hive | **Drift** (SQLite) | 관계형 모델 + SQL 집계(streak/리포트)에 최적, 마이그레이션 강력 |
| **모델/직렬화** | freezed + json_serializable | **freezed 2.x + json_serializable** | sealed class, copyWith, JSON 백업/복원 |
| **DI** | get_it + injectable / Riverpod | **Riverpod Providers** (DI 겸용) | 외부 DI 컨테이너 불필요, 일관성 |
| **로컬 알림** | flutter_local_notifications | **flutter_local_notifications + timezone** | 표준, 액션 버튼 지원, 시간대 안전 |
| **홈 위젯** | home_widget / 직접 네이티브 | **home_widget** | iOS/Android 통합 API, SharedPreferences 가교 |
| **캘린더** | table_calendar / syncfusion | **table_calendar** | 무료, 커스터마이징, eventLoader |
| **차트** | fl_chart / syncfusion_charts | **fl_chart** | 무료, 충분한 표현력 |
| **백그라운드** | workmanager / flutter_background_service | **workmanager** | 정확한 알람 재예약, OS 정책 준수 |
| **권한** | permission_handler | **permission_handler** | 표준, 알림·정확한 알람·배터리 통합 |
| **테스트** | flutter_test / mocktail / patrol | **flutter_test + mocktail + patrol** | 단위 + E2E (권한 다이얼로그 자동화) |
| **OTA** | Shorebird | **Shorebird** (옵션) | 알람 버그 핫픽스 시 스토어 우회 |
| **크래시** | Sentry / Crashlytics | **Sentry** (옵트인) | 익명 크래시만, 사용자 동의 필수 |

### 6.3 Clean Architecture Approach

```
Selected Level: Dynamic (Feature-based)

medication-tracker/
├── lib/
│   ├── main.dart
│   ├── app.dart                          # MaterialApp + go_router
│   ├── core/
│   │   ├── database/                     # Drift schema, DAO
│   │   │   ├── app_database.dart
│   │   │   ├── tables/                   # Medication, Schedule, IntakeLog
│   │   │   └── daos/
│   │   ├── notifications/                # flutter_local_notifications wrapper
│   │   │   ├── notification_service.dart
│   │   │   └── rolling_scheduler.dart    # iOS 64개 한도 대응
│   │   ├── widgets_home/                 # home_widget 갱신 로직
│   │   ├── permissions/                  # 권한 온보딩
│   │   ├── theme/                        # Material 3 + 다크모드
│   │   └── l10n/                         # 한국어/영어
│   ├── features/
│   │   ├── medication/                   # 약 CRUD
│   │   │   ├── data/                     # Repository (Drift DAO 래핑)
│   │   │   ├── domain/                   # Entity, UseCase
│   │   │   └── presentation/             # Screen, Provider
│   │   ├── schedule/                     # 스케줄 CRUD + 알람 동기화
│   │   ├── intake/                       # 복용 체크 UI
│   │   ├── calendar/                     # 캘린더 뷰
│   │   ├── report/                       # 리포트 (streak, 차트)
│   │   ├── widget_home/                  # 위젯용 데이터 직렬화
│   │   └── settings/                     # 백업/복원, 다크모드, 알림 설정
│   └── shared/
│       ├── extensions/
│       └── widgets/                      # 공용 UI 컴포넌트
├── ios/
│   └── Runner/
│       └── (WidgetKit 확장)
├── android/
│   └── app/
│       └── (AppWidget Provider)
├── test/
├── integration_test/                     # Patrol E2E
└── pubspec.yaml
```

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

- [x] 글로벌 `CLAUDE.md`: pnpm/yarn 자동 감지 — Flutter 프로젝트에 해당 안 됨 (pub 사용)
- [x] 글로벌 규칙: 선언적 프로그래밍, 디자인시스템 atomic 컴포넌트 — Flutter Widget에 적용
- [ ] `medication-tracker/analysis_options.yaml` (린트)
- [ ] `medication-tracker/CONVENTIONS.md`
- [ ] `medication-tracker/.editorconfig`

### 7.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **Naming** | missing | snake_case 파일, PascalCase 클래스, camelCase 변수 | High |
| **Folder structure** | missing | Feature-based (위 6.3 구조) | High |
| **Import order** | missing | dart → flutter → 외부 패키지 → 상대경로 (dart_style 기본) | Medium |
| **Lint 규칙** | missing | `flutter_lints` + 추가 (avoid_print, prefer_const_constructors) | High |
| **에러 처리** | missing | Result/Either 패턴 또는 sealed class 결과 타입 | Medium |
| **로그** | missing | `talker` 패키지 (외부 송신 X) | Low |
| **테스트 구조** | missing | `test/` 미러링, `_test.dart` 접미사 | Medium |

### 7.3 Environment Variables Needed

오프라인 앱이라 런타임 환경변수 최소화. 빌드 타임 상수 위주.

| Variable | Purpose | Scope | To Be Created |
|----------|---------|-------|:-------------:|
| `SENTRY_DSN` | 옵트인 크래시 리포트 (옵션) | Build-time | ☐ |
| `SHOREBIRD_TOKEN` | OTA 업데이트 (옵션) | CI only | ☐ |
| `APP_VERSION` | 표시용 버전 | Build-time (pubspec 자동) | - |

→ `.env` 불필요. `--dart-define`으로 빌드 시 주입.

### 7.4 Pipeline Integration

9-phase Development Pipeline은 웹 중심이라 Flutter에 부분 적용. 본 프로젝트에 필요한 Phase:

| Phase | Status | Document Location | Note |
|-------|:------:|-------------------|------|
| Phase 1 (Schema) | ☐ | `docs/01-plan/schema.md` | Drift 테이블 정의 (Design에서 상세) |
| Phase 2 (Convention) | ☐ | `docs/01-plan/conventions.md` | 위 7.2 기반 작성 |
| Phase 3 (Mockup) | ☐ | — | Figma 또는 Flutter Sketch 도구 |
| Phase 4 (API) | — | — | **N/A (오프라인 전용)** |
| Phase 5 (Design System) | ☐ | — | Material 3 토큰 + 공용 위젯 |
| Phase 6 (UI Integration) | ☐ | — | DB ↔ UI 통합 |
| Phase 7 (SEO/Security) | △ | — | SEO N/A, 보안만 (생체인증, 백업 암호화) |
| Phase 8 (Review) | ☐ | — | gap-detector |
| Phase 9 (Deployment) | ☐ | — | App Store / Play Store + Shorebird |

---

## 8. Next Steps

1. [ ] **Design 문서 작성**: `/pdca design medication-tracker`
   - Drift 스키마 상세 (테이블, 인덱스, 관계)
   - 화면 구성 및 네비게이션 흐름 (go_router)
   - 알람 롤링 스케줄링 알고리즘
   - 위젯 데이터 동기화 시퀀스 다이어그램
   - 리포트 계산 SQL 쿼리
2. [ ] **프로젝트 초기화**: `flutter create medication-tracker --org com.gamja.medtracker --platforms=ios,android`
3. [ ] **`pubspec.yaml` 의존성 추가**: 위 6.2 패키지
4. [ ] **컨벤션 문서**: `medication-tracker/CONVENTIONS.md`
5. [ ] **구현 시작**: `/pdca do medication-tracker`

---

## 9. Open Questions

| 질문 | 결정 필요 시점 | 비고 |
|------|---------------|------|
| 약 데이터 사전 등록 DB (KFDA 약품정보) 활용 여부 | Design 단계 | 오프라인이라면 앱 번들에 포함 → 용량 증가 |
| 위젯 사이즈 종류 (소/중/대) | Design 단계 | iOS는 systemSmall/Medium/Large |
| 알람음 커스터마이징 허용 | Design 단계 | 시스템 기본만 vs 번들 사운드 |
| 멀티 프로필 (본인 외 가족) | Phase 2 | MVP는 단일 사용자 |
| 다국어 추가 (일본어/중국어) | Phase 2 | 한국어/영어 우선 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-18 | Initial draft | gamja |
