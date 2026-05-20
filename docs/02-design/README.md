---
template: design-index
version: 1.0
project: pill-mate
date: 2026-05-19
author: gamja
status: Draft
---

# Phase 4 — 알림 시스템 심화 설계 인덱스

> Phase 3(로컬 알림 스케줄링 기본)이 머지된 직후의 후속 작업들에 대한 설계 모음.
> 각 문서는 독립적으로 구현 가능하며 별도 PR로 분리.

## 배경

Phase 3에서 다음이 완료됨:
- `MedicationNotificationManager` — scheduleId 기반 daily/weekly 반복 알림 등록
- `MedicationRepository` mutation hook으로 add/update/delete/toggle 시 자동 동기화
- `NotificationActionHandler` — foreground에서 액션(복용 완료 / 건너뜀) 처리
- 부팅 시 `syncAll()`로 시스템 알림 재구성

다음 5개 항목이 미해결로 남았으며, 각각이 사용자 가치에 직접 닿는다.

## 문서 목록

| # | 문서 | 한 줄 요약 | 의존성 | 추천 우선순위 |
|---|---|---|---|---|
| 01 | [snooze 일회성 알림](./01-snooze-one-shot-notifications.md) | 알림에서 "10분 후" 액션이 실제로 10분 뒤 한 번 더 울리게 | 없음 | ★★★ |
| 02 | [백그라운드 isolate 액션 처리](./02-background-action-isolate.md) | 앱이 떠있지 않을 때 액션 누르면 즉시 DB 반영 | 01과 무관, 액션 핸들러 공유 | ★★★ |
| 03 | [N일 간격(interval) 반복](./03-interval-repeat-rescheduling.md) | "3일마다" 같은 반복을 다음 occurrence 단발 등록 + 재등록 패턴으로 | 백그라운드 isolate(02)에 일부 의존 | ★★ |
| 04 | [알림 본문 탭 → 라우팅](./04-notification-deep-link.md) | 알림 탭 시 해당 약 상세 화면으로 이동 | go_router 진입점 추가 | ★★ |
| 05 | [N분 전 사전 알림 + urgent 미복용 재알림](./05-pre-reminder-and-urgent-retry.md) | "5분 전 미리 + 미복용 시 5분마다 최대 N회" | 일부 01과 패턴 공유 | ★ |

## 진행 순서 (추천)

1. **01 snooze** — Phase 3에서 TODO로 남긴 가장 작은 갭. 단발 알림 등록 패턴을 이 문서에서 확립하면 03/05도 같은 패턴 재사용.
2. **02 백그라운드 isolate** — 액션 즉시 반영의 사용자 가치가 큼. 별도 ProviderContainer + DB 인스턴스 운영 패턴 확립.
3. **04 deep link** — 작은 작업이지만 사용자 체감 큰 항목. 02 끝나면 글로벌 핸들러가 잘 자리 잡혀 있어 추가 부담 없음.
4. **05 사전/긴급 알림** — 이미 `AlarmScheduler`에 슬롯 ID 규칙 있음. 03 패턴(다음 occurrence 단발)을 응용.
5. **03 interval** — 가장 복잡. 사용자 액션마다 다음 occurrence를 재등록하는 라이프사이클 필요. 위 4개 모두 끝난 후가 안전.

## 공통 원칙

- **단발 알림 + 페이로드 큐**: snooze/interval/urgent 모두 "예약된 시점에 한 번 울리고, 사용자 액션 후 다음 것을 등록" 패턴. ID 충돌을 막기 위해 `(scheduleId, occurrence, kind)` 조합으로 ID 인코딩.
- **상태의 진실은 DB**: 시스템 알림은 일시적 표면. 부팅 시 `syncAll()`이 항상 DB 기준으로 재구성하므로, 시스템 알림 ↔ DB 불일치 우려를 줄임.
- **백그라운드 isolate 안전**: 새 isolate에서 동작할 코드는 `ProviderContainer`/`AppDatabase`/`MedicationNotificationManager`/`IntakeRepository`만 만들고 닫는다. UI/Riverpod observers는 건드리지 않는다.
- **OS 정책 한계 인지**: iOS는 시스템 알림 등록 상한(약 64개) 존재. interval/urgent를 너무 길게 미리 등록하지 않는다.
