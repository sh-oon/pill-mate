---
template: plan
version: 1.2
feature: catalog-phase-2c
date: 2026-05-21
author: 정성훈 <shjung@surromind.ai>
project: pill_mate
version_app: 1.0.0+4
---

# catalog-phase-2c Planning Document

> **Summary**: `tracked_medications`에 남아있는 카탈로그 중복 컬럼(name/category/shape/colorHex/iconKey/dosage/unit)을 catalog 우선 + 사용자 override 모델로 정리해 단일 진실 공급원(SSOT)을 catalog로 통일.
>
> **Project**: pill_mate
> **Version**: 1.0.0+4
> **Author**: 정성훈
> **Date**: 2026-05-21
> **Status**: Draft

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | Phase 2A에서 `medications` → `tracked_medications` rename 시 메타 컬럼(name/category/shape/colorHex/iconKey)을 catalog와 이중 보관한 상태로 남김. caller가 `tracked.name`을 직접 참조하면 catalog 큐레이션 갱신이 반영되지 않고, 데이터 불일치 가능성이 상존. |
| **Solution** | schemaVersion 6→7 마이그레이션으로 `tracked_medications`에서 중복 메타 컬럼 drop. `dosage/unit`만 “catalog 기본값 override 전용 nullable”로 유지. 모든 caller를 `display*` getter로 마이그레이션. 변수/파일명도 `tracked*`로 점진 rename. |
| **Function/UX Effect** | 사용자 가시 동작 무변경(원칙). catalog 큐레이션 자산(아이콘/색상/이름)을 변경하면 등록된 tracked에도 즉시 반영됨. UI는 동일하게 표시. |
| **Core Value** | 데이터 모델 정합성 확보 + 향후 시드 갱신/처방약(KFDA) 통합 시 단일 변경 지점 확립. 기술 부채 청산. |

---

## 1. Overview

### 1.1 Purpose

Phase 2A 커밋(`faf7fcb`)에서 의도적으로 미룬 컬럼 정리 작업을 마무리. `tracked_medications`가 catalog 메타를 이중 보관하는 상태를 종료하고, “catalog = 정의 / tracked = 인스턴스” 분리 원칙을 코드 레벨까지 강제.

### 1.2 Background

- **Phase 1** (`7ea9855`): `catalog_items` 테이블 + 시드 + repository 추가 (additive).
- **Phase 2A** (`faf7fcb`): `medications` → `tracked_medications` rename + `catalog_item_id` FK 추가. schemaVersion 4→5 wipe. 메타 컬럼은 “Phase 2B에서 정리 예정” 주석만 남기고 보존.
- **Phase 2B** (`d35ccd7`): tracked 등록 시 catalog 자동 생성 + `display*` getter 준비. 컬럼 정리는 “Phase 2C 또는 후속 작업으로 분리” 명시.
- **Phase 3** (`539b187` 등): 등록 플로우 3-step + drawer UI. caller는 여전히 `tracked.name` 등을 직참조.
- **schema v6** (`8ebaa67`): intake_logs FK setNull(보존) + catalog dedupe + orphan cleanup.

현재 caller 14개 파일(코드 검색 기준)이 `tracked.name/category/...`를 직참조 — `display*` getter 미사용 상태. Phase 2C에서 정리.

### 1.3 Related Documents

- 설계 원본: `docs/02-design/06-catalog-tracking-split.md` (§4.2 — tracked의 카탈로그 메타 제거 명시)
- 원본 Plan: `docs/01-plan/features/catalog-tracking-split.plan.md`
- 영향 받는 테이블: `lib/core/database/tables/tracked_medications.dart`
- Phase 2B 커밋 메시지(`d35ccd7`): “의도적으로 안 한 것” 섹션에 본 Phase의 작업 목록 정확히 기술됨

---

## 2. Scope

### 2.1 In Scope

- [ ] schemaVersion 6→7 마이그레이션 (`onUpgrade` step 추가, intake_logs와 동일한 “새 테이블 + 데이터 복사 + swap” 패턴)
- [ ] `TrackedMedications` 테이블 정의에서 컬럼 제거: `name`, `category`, `shape`, `colorHex`, `iconKey`
- [ ] `TrackedMedications` `dosage`, `unit`은 “override 전용 nullable”로 유지 (의미만 명확화 — 컬럼명 `customDosage/customUnit`로 rename 검토)
- [ ] `medNameSnapshot`은 보존 (tracked 삭제 후 intake_logs의 약 식별용 — Phase 2A 의도 유지)
- [ ] 마이그레이션 시 기존 tracked.name 등 메타를 catalog로 끌어올리고, catalog가 없으면 user-source로 생성 후 link
- [ ] `TrackedMedicationDraft`에서 `name/category/shape/iconKey/colorHex` 제거 → `catalogItemId` + override만 입력으로 받음
- [ ] `insertWithSchedules` / `updateWithSchedules` 시그니처 정리 (catalog는 입력으로 받거나 사전 resolve 후 id만 전달)
- [ ] 모든 caller(14파일)를 `display*` getter / catalog 직접 참조로 마이그레이션
- [ ] 변수명/파일명 점진 rename: `medication_repository.dart` → `tracked_medication_repository.dart`, `medicationId` 파라미터 → `trackedMedicationId`(FK 의미 명확화, 단 알림 payload는 호환성 유지)

### 2.2 Out of Scope

- 알림 payload 포맷 변경 (`dose:scheduleId:medicationId:isoScheduledAt`) — 호환성 위해 이름만 유지, 의미만 trackedMedicationId
- 시드 카탈로그 갱신 정책 (별도 PR, `seed_version` 도입)
- FTS5 한글 초성 검색 (별도 PR)
- 처방약(KFDA) 카탈로그 통합 (Phase 2 plan에서 future work로 명시)
- UI 디자인/UX 변경
- `intake_logs.medication_id` 컬럼명 변경(FK 의미는 trackedMedicationId지만 호환성 유지)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | schemaVersion 6→7 onUpgrade에서 tracked 메타 컬럼 drop + catalog로 백필 | High | Pending |
| FR-02 | 백필 시 catalog 없는 tracked는 user-source catalog 자동 생성 후 link | High | Pending |
| FR-03 | 마이그레이션 실패 시 rollback 가능하도록 `PRAGMA foreign_keys = OFF` + 트랜잭션 패턴 사용 | High | Pending |
| FR-04 | `TrackedMedicationWithSchedules.displayName` 등 getter가 catalog 우선 → override 폴백 순서 보장 | High | Pending |
| FR-05 | 모든 caller(home, calendar, reports, medication_*, notification_manager, sheets, mockups)가 `display*` getter 사용 | High | Pending |
| FR-06 | Drift 자동 생성 코드(`app_database.g.dart`) 재생성 후 컴파일 무에러 | High | Pending |
| FR-07 | flutter analyze --fatal-warnings 통과 | High | Pending |
| FR-08 | 기존 사용자 데이터(meds + schedules + intake_logs)가 v6→v7 업그레이드 후 그대로 조회 가능 | High | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 마이그레이션 < 500ms (tracked 100건 기준) | 실기기 로그 |
| Data Integrity | 마이그레이션 전후 tracked/schedules/intake_logs row count 동일 | SQL count 비교 |
| Backward Compatibility | v6 DB 가진 사용자가 앱 업데이트 시 데이터 손실 0건 | manual upgrade test |
| Maintainability | tracked 메타 직참조 0건 (grep 기준) | `grep -r "tracked.name\b"` 결과 비어있음 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] schemaVersion 7로 정상 업그레이드 (v6→v7 onUpgrade 동작 확인)
- [ ] `TrackedMedications` 테이블에서 중복 메타 컬럼 제거
- [ ] 모든 caller가 `display*` getter 사용 (직참조 0건)
- [ ] flutter analyze: clean
- [ ] flutter test: 기존 테스트 통과
- [ ] 홈/캘린더/리포트/드로어/상세 화면 수동 회귀 — 약 이름/아이콘/색상 정상 표시
- [ ] markTaken/markSkipped 후 intake_logs 정상 기록

### 4.2 Quality Criteria

- [ ] grep `tracked\.name|tracked\.category|tracked\.shape|tracked\.colorHex|tracked\.iconKey` → 0건
- [ ] grep `TrackedMedicationDraft\(name:` → 0건 (Step별 caller 정리)
- [ ] Drift schema diff vs expected — 신규 컬럼/제거 컬럼 검토 완료
- [ ] PR description에 마이그레이션 SQL 첨부

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 마이그레이션 도중 실패 → 사용자 DB 손상 | High | Low | `PRAGMA foreign_keys = OFF` + 신규 테이블 swap 패턴 (intake_logs v6 마이그레이션과 동일). 실패 시 신규 테이블만 drop하면 rollback. |
| 백필 시 catalog 미존재 tracked에 user-source catalog 무분별 생성 | Medium | Medium | (name, category) 매칭 dedupe(`_resolveOrCreateCatalog`) 활용 — 동일 이름이면 기존 catalog 재사용. |
| caller 14파일 마이그레이션 누락 → 런타임 NoSuchMethodError | High | Medium | 컴파일 시점에 잡히도록 컬럼 자체를 제거(타입 시스템 보호). flutter analyze 통과를 DoD에 포함. |
| 알림 payload 호환성 깨짐 | High | Low | payload 포맷 변경 out-of-scope 명시. 컬럼명만 변경, payload 문자열은 그대로. |
| schemaVersion bump 누락 → 기존 사용자 앱이 새 컬럼 못 찾음 | High | Low | onUpgrade 추가 + 수동 업그레이드 테스트 절차를 DoD에 포함. |
| Mockup 파일이 더미 데이터로 컴파일 안 됨 | Low | High | mockup은 별도 라우트(dev only) — 같이 정리하되 회귀 우선순위는 낮음. |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure | Static sites | ☐ |
| **Dynamic** | Feature-based modules | Web apps w/ backend | ☐ |
| **Enterprise** | Strict layer separation | High-traffic systems | ☐ |
| **Flutter App (현 프로젝트)** | feature-folder + Drift + Riverpod | Native mobile (iOS/Android) | ☑ |

> bkit Starter/Dynamic/Enterprise 분류는 웹 중심이라 현 프로젝트(Flutter)와 직접 매칭 안 됨. 사실상 Dynamic급 복잡도이나 BaaS 대신 Drift on-device DB 사용.

### 6.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| 마이그레이션 방식 | wipe / 데이터 보존 백필 / dual-write | **데이터 보존 백필** | Phase 2A는 알파라 wipe했지만, 현재는 사용 중 데이터 보존 필수. |
| SQLite ALTER 패턴 | ALTER COLUMN drop / 새 테이블 + swap | **새 테이블 + swap** | SQLite는 ALTER COLUMN drop 미지원. v6 intake_logs 마이그레이션과 동일 패턴 재사용. |
| catalog 백필 정책 | tracked 메타 유지 / catalog로 끌어올림 | **catalog로 끌어올림 + dedupe** | SSOT 통일 + 시드와 일관. `_resolveOrCreateCatalog` 재사용. |
| override 컬럼명 | `dosage/unit` 유지 / `customDosage/customUnit` rename | **rename 검토** | 의미 명확화 (override 전용 표시). Design 단계에서 결정. |
| caller 마이그레이션 시점 | 컬럼 제거 전 / 후 | **컬럼 제거와 동시** | 컴파일 에러로 누락 방지(타입 시스템 보호). |
| 알림 payload 컬럼명 | 변경 / 유지 | **유지** | 기존 알림 토큰 호환성 + payload 파서 단일 (out-of-scope). |

### 6.3 폴더 구조 영향

```
변경 영역:
lib/core/database/
  app_database.dart              — schemaVersion 6→7, onUpgrade step 추가
  tables/tracked_medications.dart — 컬럼 제거
lib/features/medication/
  data/medication_repository.dart — Draft/Companion 정리, 마이그레이션 caller 정리
  data/medication_providers.dart  — 변경 최소
  presentation/...                — display* getter 사용
lib/features/{home,calendar,reports}/
  presentation/...                — display* getter 사용
lib/core/widgets/sheets/...       — display* getter 사용
lib/mockups/...                   — Draft 시그니처 변경 반영 (dev only)
```

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

- [x] Drift 마이그레이션 패턴 — v5→v6 intake_logs 마이그레이션 코드(`app_database.dart:60-95`)가 참고 표준
- [x] Catalog dedupe 패턴 — `_resolveOrCreateCatalog` (`medication_repository.dart:245`)
- [x] Display getter 패턴 — `TrackedMedicationWithSchedules.displayName/displayDosage/...` 이미 정의됨
- [ ] tracked vs medication 변수명 — Phase 2A에서 “호환성 위해 유지” 결정. Phase 2C에서 점진 rename 시작

### 7.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **마이그레이션 SQL 작성 위치** | onUpgrade 안에 inline | inline 유지 (v6 패턴 일관) | High |
| **caller 마이그레이션 검증** | grep 기반 | grep 명령어 PR 본문 명시 | High |
| **Draft 시그니처** | name/category 등 필수 | `catalogItemId` + override만 | High |
| **변수명 점진 rename 정책** | 호환성 위해 medication 유지 | trackedMedication로 전환 시작 (FK 컬럼 우선) | Medium |

### 7.3 Environment Variables Needed

해당 없음 — DB 마이그레이션 한정, 외부 env 의존성 없음.

### 7.4 Pipeline Integration

해당 없음 — 9-phase Development Pipeline은 신규 프로젝트 부트스트랩용. 본 작업은 기존 코드베이스 리팩터.

---

## 8. Next Steps

1. [ ] Design 문서 작성 — `/pdca design catalog-phase-2c`
   - 마이그레이션 SQL 상세 (intake_logs v6 패턴 활용)
   - 백필 알고리즘 의사코드 (catalog dedupe + user-source 생성)
   - caller 마이그레이션 체크리스트 (14파일)
   - Draft 시그니처 before/after
2. [ ] 사용자 데이터 백업 정책 확인 (실기기 마이그레이션 전)
3. [ ] 구현 시작 — `/pdca do catalog-phase-2c`
4. [ ] Gap analysis — `/pdca analyze catalog-phase-2c`

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-21 | Initial draft — Phase 2A/2B 커밋 분석 + 잔여 작업 추출 | 정성훈 |
