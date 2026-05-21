---
template: plan
version: 1.0
feature: catalog-tracking-split
date: 2026-05-21
author: gamja (assisted)
project: pill-mate
platform: Flutter (iOS + Android)
status: Draft
depends_on: pill-mate.plan.md
---

# catalog-tracking-split Planning Document

> **Summary**: 현재 단일 `medications` 테이블이 (1) 약/영양제의 정체성과 (2) 사용자 트래킹 인스턴스를 함께 들고 있어 검색/시드/공유가 어려움. 카탈로그(`catalog_items`)와 트래킹(`tracked_medications`)으로 분리하고, 한국 인기 영양제 50~100개를 시드 카탈로그로 동봉. 약 등록과 알람 등록을 별도 시나리오로 디커플 — 알람 없는 트래킹도 허용.
>
> **Project**: pill-mate
> **Version**: 0.2.0 (schema breaking change)
> **Platform**: Flutter 3.41.9 / Dart 3.9 (iOS + Android)
> **Author**: gamja
> **Date**: 2026-05-21
> **Status**: Draft (사용자 결정 3건 확정 후 초안)

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | (1) 약 등록 시 "검색"이 의미 없음 — 사용자가 직접 입력한 자신의 항목 안에서만 검색이라 카탈로그 발견 가치 0. (2) 알람과 약 등록이 한 흐름에 묶여 있어, 알람 없이 "내가 챙기는 영양제 목록"만 관리하고 싶은 경우 강제로 알람 셋업 거쳐야 함. (3) 향후 시드 카탈로그/공유/추천 같은 기능 확장의 모델 기반이 없음. |
| **Solution** | `medications` 단일 테이블을 `catalog_items`(약/영양제가 무엇인지) + `tracked_medications`(사용자 인스턴스)로 분리. `schedules`(알람)는 `tracked_medications`에 0..N 관계 — 즉 알람 없는 tracked가 허용됨. 한국 인기 영양제 50~100개를 시드 JSON으로 번들. 등록 플로우 3단계: 카탈로그 검색 → 인스턴스 속성 → 알람(skip 가능). |
| **Function/UX Effect** | 약 추가 시 카탈로그에서 검색으로 빠르게 발견 → 입력 마찰 감소. 알람 없이도 "오늘 챙긴 영양제" 추적 가능 (drawer 카드에 노출). 시드 항목은 미리 큐레이션된 아이콘/색상/카테고리로 시각적 일관성. |
| **Core Value** | "내가 챙기는 약·영양제를 빠르게 발견·등록하고, 알람은 원할 때만." 발견성 + 자율성 + 일관성. |

---

## 1. Overview

### 1.1 Purpose

기존 단일 테이블 모델의 한계를 해소하고, 약/영양제 도메인을 두 개념으로 분리한다:
- **catalog_items**: 약/영양제가 "무엇인지" — 이름, 카테고리, 기본 용량, 시각적 메타 (아이콘·색상). 시드(번들) + 사용자 직접 추가 둘 다 여기에 들어감.
- **tracked_medications**: 사용자가 "복용 중인" 인스턴스 — 메모, 커스텀 용량 오버라이드, archived 플래그. 카탈로그 항목과 FK로 연결.
- **schedules**: 알람 설정. tracked_medication에 0..N 관계. 0개 = 알람 없는 트래킹.

추가로 한국 사용자가 가장 흔히 챙기는 영양제 50~100개를 시드 카탈로그로 번들해 첫 등록 마찰을 제거한다.

### 1.2 Background

- 현재 `medications` 테이블이 카탈로그 속성(name, category, dosage, unit, shape, colorHex, iconKey)과 사용자 속성(memo, archived, createdAt)을 함께 들고 있음
- `feat/drawer-search` (#12) 머지로 검색 UI는 있지만 검색 대상이 "사용자가 이미 등록한 자기 약 목록"이라 발견성 가치 없음
- `feat/drawer-sort` (#15)도 동일한 한계 — 처음 등록할 때 카탈로그 부재가 본질적 마찰
- 사용자 의도: 약/영양제 "관리"와 알람 "설정"은 별개 시나리오. 챙기는 영양제 목록만 두고 알람은 일부에만 걸고 싶음
- pill-mate.plan.md의 Open Question "약 데이터 사전 등록 DB (KFDA) 활용 여부"가 미해결 — 본 plan에서 결론: **번들 큐레이션** 채택, KFDA는 Out of Scope

### 1.3 Related Documents

- 모태 plan: `docs/01-plan/features/pill-mate.plan.md`
- 본 plan의 design: `docs/02-design/features/catalog-tracking-split.design.md` (예정)
- 현재 schema: `lib/core/database/tables/{medications,schedules,intake_logs,interval_occurrences}.dart`

---

## 2. Scope

### 2.1 In Scope

- [ ] **Schema 재설계**: `catalog_items` 신설, `medications` → `tracked_medications`로 의미 분리 + 컬럼 정리, `schedules`/`intake_logs`/`interval_occurrences` FK를 `tracked_medications`로 redirect
- [ ] **Drift 마이그레이션**: schemaVersion bump + **전체 wipe + recreate** (사용자 결정: 기존 데이터 무시)
- [ ] **시드 카탈로그**: `assets/seed/catalog_supplements.ko.json` — 한국 인기 영양제 50~100개. 첫 부팅 시 1회 INSERT
- [ ] **카탈로그 검색**: drawer 검색이 카탈로그 + 사용자 추가 항목 통합 검색 (한글 초성 매칭 포함)
- [ ] **등록 플로우 재설계 (3-step)**:
  - Step 1: 카탈로그 검색/선택 (또는 "직접 추가" → 빈 catalog_item 생성)
  - Step 2: tracked 인스턴스 속성 (custom dosage, memo, 시작/종료일)
  - Step 3: 알람 설정 — **skip 가능**. skip 시 tracked만 생성하고 schedules 0개
- [ ] **약 서랍(drawer) UI 변경**: 알람 있는 항목 vs 없는 항목 시각적 구분 (배지 또는 정렬). 필터는 추후 ENH
- [ ] **홈 화면 변경 없음**: 알람 있는 tracked만 노출 (기존 동작 유지). 알람 없는 항목은 drawer에서만
- [ ] **tracked detail 화면**: "알람 추가" 액션 추가 — 알람 없는 tracked에서 진입 시 schedule 셋업 sheet 열림
- [ ] **Repository/Provider 리팩터링**: medication_repository → catalog_repository + tracked_medication_repository 분리

### 2.2 Out of Scope

- 처방약 카탈로그 (식약처 의약품DB) — Phase 2 검토. 현재는 "직접 추가"로 사용자가 입력
- 카탈로그 동기화/업데이트 (네트워크) — 오프라인 원칙 유지
- 카탈로그 항목 사용자 평점/리뷰 — 단일 사용자 앱
- 다국어 카탈로그 (en/ja) — 한국어만. en은 UI 라벨만, 카탈로그 항목은 ko name + name_en optional
- 카탈로그 항목 cascade 정책 변경 — 사용자 추가 카탈로그 삭제 시 동작은 Design 단계에서 결정
- 기존 사용자 데이터 마이그레이션 — 결정: wipe
- 약 사진/이미지 업로드 — 향후 ENH

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-CT-01 | `catalog_items` 테이블 생성 (id, name, name_en, category, default_dosage, default_unit, shape, colorHex, iconKey, tags, source enum, createdAt) | High | Pending |
| FR-CT-02 | `tracked_medications` 테이블 생성 (id, catalog_item_id FK, custom_dosage, memo, archived, startDate, endDate, createdAt, updatedAt) | High | Pending |
| FR-CT-03 | `schedules`/`intake_logs`/`interval_occurrences`의 medicationId FK를 tracked_medication_id로 마이그레이션 | High | Pending |
| FR-CT-04 | Drift schemaVersion bump + onUpgrade에서 전체 drop+create | High | Pending |
| FR-CT-05 | 시드 카탈로그 JSON 50~100개 큐레이션 (영양제 위주) | High | Pending |
| FR-CT-06 | 첫 부팅(또는 catalog 비어있을 때) 시드 JSON → catalog_items INSERT | High | Pending |
| FR-CT-07 | 카탈로그 검색 (이름, name_en, tags, 한글 초성) | High | Pending |
| FR-CT-08 | 등록 플로우 Step 1: 카탈로그 검색/선택 화면 + "직접 추가" 분기 | High | Pending |
| FR-CT-09 | 등록 플로우 Step 2: tracked 인스턴스 속성 입력 | High | Pending |
| FR-CT-10 | 등록 플로우 Step 3: 알람 설정 + **"건너뛰기" 버튼** 노출 | High | Pending |
| FR-CT-11 | drawer에서 알람 있음/없음 시각적 구분 (배지 또는 색상) | Medium | Pending |
| FR-CT-12 | tracked detail에서 "알람 추가" 액션 (schedules 0개일 때 prominent) | High | Pending |
| FR-CT-13 | catalog_repository: search, getById, addUserCustom, getSeeded | High | Pending |
| FR-CT-14 | tracked_medication_repository: 기존 medication_repository에서 분리 + FK 통합 | High | Pending |
| FR-CT-15 | 홈 화면이 알람 있는 tracked만 노출하는지 검증 (기존 쿼리 수정) | High | Pending |
| FR-CT-16 | 사용자가 "직접 추가"한 catalog_item 삭제 시 동작: tracked 있으면 archive, 없으면 delete | Medium | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| **시드 로딩** | 카탈로그 100개 INSERT < 200ms (cold start) | Stopwatch 측정 |
| **검색 응답** | 검색어 입력 후 결과 < 50ms (100개 카탈로그 기준) | DevTools timeline |
| **APK 사이즈 증가** | JSON 시드로 인한 증가 < 30KB | bundletool size analyze |
| **마이그레이션 안전성** | 기존 사용자 데이터 wipe 시 명시적 안내 (다이얼로그) — 단 결정: 기존 사용자 무시 | UX 검토 |
| **카탈로그 일관성** | 시드 항목 100% 아이콘·색상 메타 채워짐 | JSON schema validation |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] FR-CT-01 ~ FR-CT-15 모두 구현 완료
- [ ] 시드 카탈로그 JSON 큐레이션 완료 (최소 50개, 권장 100개)
- [ ] 등록 플로우 3단계 모두 실기기에서 동작 검증
- [ ] Step 3 "건너뛰기" 후 tracked만 생성되고 schedules 0개 상태 확인
- [ ] tracked detail에서 "알람 추가" 정상 동작 확인
- [ ] drawer에서 알람 있음/없음 항목 모두 보이는지 검증
- [ ] 홈은 알람 있는 항목만 노출 검증
- [ ] 카탈로그 검색이 한글 초성 매칭 동작 확인
- [ ] 기존 medication 관련 lib/ 코드에 dead reference 0건 (grep)
- [ ] 본 plan에 명시된 마이그레이션 후 앱 클린 부팅 성공

### 4.2 Quality Criteria

- [ ] `flutter analyze --fatal-warnings` 통과
- [ ] catalog_repository / tracked_medication_repository 단위 테스트 (drift in-memory)
- [ ] 시드 JSON validation 스크립트 통과
- [ ] APK 사이즈 증가 < 30KB

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **시드 카탈로그 큐레이션 품질** | Medium | Medium | 초기 50개로 시작 → 사용 데이터 보고 확장. iconKey/category 매핑은 기존 enum 재사용 |
| **FK 변경 마이그레이션 누락** | High | Low | 전체 wipe 전략으로 회피. 단 사용자에게 명시 안내 |
| **등록 플로우 step 추가로 시간 증가** | Medium | Medium | 카탈로그 자동완성으로 Step 2 입력 자동 채움 → 전체 시간 감소 가능 |
| **"알람 없는 tracked"의 UX 발견성** | Medium | Medium | drawer 카드에 시각적 차별화 + tracked detail의 "알람 추가" CTA 강조 |
| **시드 데이터 저작권/정확성** | Medium | Low | 일반 명칭(비타민D, 오메가3 등)만 사용. 브랜드명·제품명 회피 |
| **카탈로그 항목 사용자 추가가 시드와 중복** | Low | Medium | 검색 시 시드 항목 우선 노출 + "이미 비슷한 항목 있어요" 힌트 |
| **drawer 정렬/검색 기존 PR과 충돌** | Medium | Low | 카탈로그 → tracked 매핑 후 정렬/검색 로직 재사용. 별도 작업으로 분리 |
| **APK 사이즈 증가로 store 거부** | Low | Low | 30KB 추가는 무시 가능 |

---

## 6. Architecture Considerations

### 6.1 Schema Sketch (Design에서 확정)

```
┌──────────────────────┐         ┌────────────────────────┐         ┌────────────────────┐
│ catalog_items        │ 1   *   │ tracked_medications    │ 1   0..N│ schedules          │
│──────────────────────│◄────────│────────────────────────│────────►│────────────────────│
│ id (TEXT slug)       │         │ id (INT autoinc)       │         │ id                 │
│ name                 │         │ catalog_item_id (FK)   │         │ tracked_med_id(FK) │
│ name_en              │         │ custom_dosage          │         │ timeOfDay          │
│ category             │         │ memo                   │         │ repeatKind         │
│ default_dosage       │         │ archived               │         │ daysOfWeekMask     │
│ default_unit         │         │ startDate              │         │ intervalDays       │
│ shape                │         │ endDate                │         │ remindBeforeMin    │
│ colorHex             │         │ createdAt              │         │ urgentRepeatMin    │
│ iconKey              │         │ updatedAt              │         │ enabled            │
│ tags (JSON)          │         └────────────────────────┘         └────────────────────┘
│ source ('seed'|'user')│                    ▲
│ createdAt            │                    │ 1
└──────────────────────┘                    │
                                            │ *
                                  ┌─────────┴──────────┐
                                  │ intake_logs        │
                                  │────────────────────│
                                  │ id                 │
                                  │ tracked_med_id(FK) │
                                  │ schedule_id(FK)    │
                                  │ takenAt            │
                                  │ status             │
                                  └────────────────────┘
```

상세는 Design 문서에서.

### 6.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| **분리 방식** | (A) full 분리 / (B) 같은 테이블에 catalog_id nullable | **A** | 사용자가 알람 없는 tracked + 시드 둘 다 명시적으로 요구. ROI 높음 |
| **catalog_id 타입** | INT autoinc / TEXT slug | **TEXT slug** (예: `vit-d3-1000iu`) | 시드 JSON에 안정적 ID 부여, 사용자 추가는 UUID v4 |
| **시드 출처** | 직접 큐레이션 / KFDA API / Wikipedia | **직접 큐레이션 50~100개** (영양제 위주) | 오프라인 일관성, 저작권 안전, 충분한 커버리지 |
| **마이그레이션 전략** | 데이터 보존 / wipe | **wipe** | 사용자 결정. 알파 단계라 손실 무시 |
| **사용자 추가 항목 위치** | catalog 통합 / 별도 user_items | **catalog 통합 (source='user')** | 검색 UX 일관성, 다음 등록 시 재사용 |
| **알람 없는 tracked 노출** | 홈+서랍 / 서랍만 | **서랍만** | 홈은 "오늘 챙길 것" 중심 유지. 알람 없는 건 trackthing only |
| **schedules cardinality** | 1..1 / 0..N | **0..N** | "알람 없는 tracked" + "여러 시각" 자연스러움 (기존도 0..N이지만 의도 명시) |
| **catalog 동기화** | 빌드 시 / 첫 부팅 / 매 부팅 | **첫 부팅 (테이블 empty일 때)** | 사용자 추가 항목 덮어쓰기 방지 |

### 6.3 시드 JSON 구조 예시

```json
{
  "version": 1,
  "items": [
    {
      "id": "vit-d3-1000iu",
      "name": "비타민 D3",
      "name_en": "Vitamin D3",
      "category": "sup",
      "default_dosage": "1000",
      "default_unit": "IU",
      "shape": "softgel",
      "colorHex": "#FFD580",
      "iconKey": "pill",
      "tags": ["면역", "뼈건강"]
    },
    {
      "id": "omega3",
      "name": "오메가3",
      "name_en": "Omega-3",
      "category": "sup",
      "default_dosage": "1000",
      "default_unit": "mg",
      "shape": "softgel",
      "colorHex": "#FFCC80",
      "iconKey": "pill",
      "tags": ["혈관", "뇌건강"]
    }
  ]
}
```

상세 카탈로그 50~100개 목록은 Design 단계에서 큐레이션 + validation.

---

## 7. Convention Prerequisites

본 변경은 기존 `pill-mate.plan.md` 7.x 컨벤션 그대로 적용. 추가로:

| Category | 추가 사항 | Priority |
|----------|-----------|:--------:|
| **Schema 명명** | catalog 관련 컬럼은 `default_*` prefix, tracked 인스턴스는 `custom_*` prefix | High |
| **ID 타입** | catalog_items.id = TEXT slug (kebab-case), tracked_medications.id = INT autoinc (기존) | High |
| **시드 JSON 경로** | `assets/seed/catalog_supplements.ko.json` (locale-suffixed 향후 확장) | Medium |
| **시드 validation** | Dart 스크립트 `tool/validate_seed_catalog.dart` — CI에서 실행 | Medium |

---

## 8. Next Steps

1. [ ] **본 PR (release-readiness) 머지 우선**
2. [ ] **Design 문서 작성**: `/pdca design catalog-tracking-split`
   - Drift 스키마 SQL DDL
   - 마이그레이션 onUpgrade 코드
   - 시드 로더 구현 시퀀스
   - 등록 플로우 3-step state machine
   - Repository 인터페이스
   - UI mockup (drawer 배지, Step 3 skip 버튼, tracked detail "알람 추가")
3. [ ] **시드 카탈로그 큐레이션**: 50~100개 목록 + iconKey/색상 매핑
4. [ ] **구현**: `/pdca do catalog-tracking-split`
5. [ ] **테스트 인프라 PR 선행**: drift in-memory harness — `test: drift mock harness` PR (본 plan과 별개, 기존 widget test도 함께 살림)
6. [ ] **Catalog seed validation 스크립트**: `tool/validate_seed_catalog.dart` + CI 통합

---

## 9. Open Questions

| 질문 | 결정 필요 시점 | 비고 |
|------|---------------|------|
| 사용자가 카탈로그 항목 자체를 편집할 수 있는가? (이름/아이콘 변경) | Design | 시드 항목은 read-only, source='user' 항목만 편집 가능이 합리적 |
| 시드 카탈로그 업데이트는 앱 업데이트로만? | Design | OTA로 갱신은 오프라인 원칙 어김. 앱 업데이트로 충분 |
| 카테고리 enum 확장 ('med' / 'sup' 외 'herb' / 'food'?) | Design | 현재 'med'/'sup' 유지, 추가는 사용 사례 보고 |
| 같은 catalog_item을 여러 번 tracked로 등록 허용? (예: 아침/저녁 별도 entry) | Design | 허용 권장 — schedules 0..N로 해결되지만 UX 명확성 필요 |
| 향후 처방약 카탈로그(KFDA) 통합 시 시드 vs 사용자 vs KFDA 3-source 처리 | Phase 2 | 현재 'seed'/'user' enum에 'kfda' 추가 가능하도록 확장형 설계 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-05-21 | Initial draft. 사용자 결정 3건(시드 동봉, wipe 허용, 등록≠알람 디커플) 반영 | gamja (assisted) |
