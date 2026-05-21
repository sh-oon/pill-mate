# Play Console — Permission Declarations

Android 14+에서 다음 권한은 **restricted**로 분류되어 Play Console에 정당화를 제출해야 자동 거부를 피할 수 있습니다.

## 1. USE_FULL_SCREEN_INTENT

### 사용 여부
Manifest 선언: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

코드 사용처: `lib/core/notifications/notification_service.dart` 등에서 **미복용 시 긴급 알림** 시나리오에 사용.

### Play Console Declaration 양식 답변

**Q. Why does your app need this permission?**

> Pill Mate is a medication reminder app for users managing critical prescriptions
> (e.g., chronic conditions, post-surgery medication). When a scheduled dose is
> missed and the user has not responded to standard notifications within a
> configured window, the app displays a full-screen reminder that wakes the device
> screen so the user can act on the alert promptly. This is comparable to an
> alarm clock use case.

**Q. Alternative considered**

> Standard heads-up notifications were tried, but users in real-world conditions
> (sleeping, device face-down, silent mode at night) frequently miss them.
> Full-screen intent is only used for the *urgent retry* category after the user
> has explicitly enabled it in settings.

**Q. App category**

> Medical / Health & Fitness — Medication reminder.

### 추가 첨부물

- 데모 영상(20~30초): 알림 → 미응답 → 풀스크린 인텐트 트리거 → 사용자 액션
- 설정 화면 스크린샷: 사용자가 긴급 알림을 ON/OFF 할 수 있는 UI

---

## 2. SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM

### Play Console 양식 답변

**Q. Why does your app need exact alarms?**

> Medication adherence depends on precise dose timing (e.g., antibiotics every
> 8 hours, insulin at meals). Inexact alarms (`setInexactRepeating`) can drift
> by 15+ minutes which is medically meaningful. Exact alarms are scheduled only
> for reminders the user explicitly configures.

**Q. Are exact alarms used for user-initiated tasks only?** — **Yes.**

---

## 3. REQUEST_IGNORE_BATTERY_OPTIMIZATIONS

### Play Console 양식 답변

**Q. Core functionality requirement?**

> Some OEMs (Samsung, Xiaomi, Huawei, OPPO) aggressively kill background alarm
> scheduling on battery-optimized apps. To deliver scheduled medication reminders
> reliably the app prompts the user (one-time, user-dismissable) to whitelist
> the app from battery optimization. The prompt is only shown once and the user
> can deny without losing app functionality.

---

## 체크리스트

- [ ] Play Console > App content > Sensitive app permissions > Declarations 제출
- [ ] 데모 영상 업로드 (YouTube unlisted URL 또는 직접 업로드)
- [ ] 의료 카테고리(Medical) 또는 건강/피트니스(Health & Fitness)로 분류 선택
- [ ] FOREGROUND_SERVICE는 현재 manifest에 선언되어 있지만 코드에서 사용 시 추가 declaration 필요 — **사용 여부 재확인 후 미사용 시 manifest에서 제거 권장**
