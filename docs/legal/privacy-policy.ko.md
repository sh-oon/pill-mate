# 필메이트 개인정보처리방침

**최종 업데이트**: 2026-05-20
**적용 대상**: iOS / Android 앱 "필메이트 (Pill Mate)"
**개발자**: gamja (개인 개발자)
**문의**: shjung@surromind.ai

---

## 1. 핵심 요약

**필메이트는 완전한 오프라인 앱입니다.**

- 사용자 데이터를 외부 서버로 전송하지 않습니다.
- 회원가입, 로그인이 없습니다.
- 광고 SDK, 분석 SDK를 사용하지 않습니다.
- 모든 데이터는 사용자 기기 내부에만 저장됩니다.

## 2. 수집·이용하는 정보

| 정보 항목 | 저장 위치 | 외부 전송 여부 |
|-----------|-----------|----------------|
| 약물 이름, 복용 시간, 복용 주기, 메모 | 기기 내 SQLite DB | ❌ 전송 안 함 |
| 복용 이력 (intake logs) | 기기 내 SQLite DB | ❌ 전송 안 함 |
| 알림 설정, 온보딩 완료 여부 | 기기 내 SharedPreferences | ❌ 전송 안 함 |

사용자는 앱 설정에서 모든 데이터를 영구 삭제할 수 있습니다 (`설정 > 데이터 초기화`).

## 3. 요청하는 권한

| 권한 | 용도 | 거부 시 영향 |
|------|------|--------------|
| 알림 (POST_NOTIFICATIONS / UNUserNotificationCenter) | 복용 시간 알람 표시 | 알람 기능 사용 불가 |
| 정확한 알람 (SCHEDULE_EXACT_ALARM) | 약물 복용 시간 정확한 트리거 | 알람 시간이 최대 15분 지연될 수 있음 |
| 전체화면 인텐트 (USE_FULL_SCREEN_INTENT) | 미복용 시 긴급 재알림 | 일반 알림만 표시됨 |
| 부팅 완료 수신 (RECEIVE_BOOT_COMPLETED) | 기기 재부팅 후 알람 자동 재예약 | 재부팅 후 알람이 사라짐 |
| 배터리 최적화 제외 (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) | OEM별 백그라운드 종료 방지 | 일부 기기에서 알람 누락 가능 |

## 4. 제3자 제공

수집·이용·저장하는 모든 정보는 사용자 기기 내에만 보관되며, **제3자에게 제공·위탁·판매되지 않습니다.**

## 5. 아동 개인정보 보호

본 앱은 만 14세 미만 아동을 대상으로 하지 않습니다. 만 14세 미만 사용자의 데이터를 의도적으로 수집하지 않으며, 모든 데이터는 기기 내부에만 저장됩니다.

## 6. 변경 사항 통지

본 방침이 변경될 경우, 앱 업데이트 노트와 본 페이지를 통해 사전 공지합니다.

## 7. 문의

개인정보 처리 관련 문의: shjung@surromind.ai

---

## App Store / Play Store 양식 답변 가이드

### App Store Connect — App Privacy

| 카테고리 | 답변 |
|----------|------|
| Data Used to Track You | **None** |
| Data Linked to You | **None** |
| Data Not Linked to You | **None** |

**Privacy Policy URL**: (배포 후 호스팅 URL 입력)

### Google Play — Data Safety

| 질문 | 답변 |
|------|------|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | **Not applicable** (no data transmission) |
| Do you provide a way for users to request that their data is deleted? | **Yes — In-app: 설정 > 데이터 초기화** |
