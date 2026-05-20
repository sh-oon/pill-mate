# Pill Mate — Privacy Policy

**Last updated**: 2026-05-20
**Applies to**: iOS / Android app "Pill Mate (필메이트)"
**Developer**: gamja (independent developer)
**Contact**: shjung@surromind.ai

---

## 1. TL;DR

**Pill Mate is a fully offline app.**

- No user data is transmitted to any server.
- No account, login, or registration required.
- No advertising SDKs, no analytics SDKs.
- All data is stored locally on the user's device.

## 2. What we store (locally only)

| Data | Storage | Sent externally? |
|------|---------|-------------------|
| Medication name, schedule, interval, notes | On-device SQLite database | ❌ No |
| Intake history (taken / missed logs) | On-device SQLite database | ❌ No |
| Notification settings, onboarding flag | On-device SharedPreferences | ❌ No |

Users can permanently delete all data from `Settings > Reset Data`.

## 3. Permissions requested

| Permission | Purpose | Impact if denied |
|------------|---------|-------------------|
| Notifications | Display medication reminders | Reminder feature unavailable |
| Exact alarms (Android) | Trigger at the precise dose time | Reminders may drift up to ~15 minutes |
| Full-screen intent (Android) | Urgent retry for missed doses | Only standard notifications shown |
| Boot completed (Android) | Re-schedule alarms after device reboot | Reminders lost after reboot |
| Ignore battery optimizations (Android) | Prevent OEM background-kill of alarms | Some devices may skip reminders |

## 4. Third-party sharing

We do not share, sell, or transmit any of the data stored locally on the user's device to any third party.

## 5. Children's privacy

This app is not directed to children under 13 (or 14 in Korea). We do not knowingly collect any data, and all data remains on the device.

## 6. Changes to this policy

Updates will be announced in the app release notes and on this page.

## 7. Contact

Privacy-related inquiries: shjung@surromind.ai

---

## App Store / Play Store form answers

### App Store Connect — App Privacy

| Category | Answer |
|----------|--------|
| Data Used to Track You | **None** |
| Data Linked to You | **None** |
| Data Not Linked to You | **None** |

**Privacy Policy URL**: (fill in hosted URL after deployment)

### Google Play — Data Safety

| Question | Answer |
|----------|--------|
| Does your app collect or share any of the required user data types? | **No** |
| Is all collected user data encrypted in transit? | **Not applicable** |
| Do you provide a way for users to request that their data is deleted? | **Yes — in-app: Settings > Reset Data** |
