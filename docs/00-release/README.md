# Release Runbook

iOS + Android 스토어 출시를 위한 작업 인덱스. **사용자 액션** (직접 해야 함) vs **자동화됨** (CI가 처리)로 구분.

## 📑 문서 인덱스

| 문서 | 용도 |
|------|------|
| [`cross-platform-release-gap.md`](cross-platform-release-gap.md) | 전체 갭 분석 — 무엇이 부족한지 |
| [`play-console-permissions-justification.md`](play-console-permissions-justification.md) | Play Console restricted permission declaration 텍스트 |
| [`store-assets-checklist.md`](store-assets-checklist.md) | 아이콘/스크린샷/카피라이팅 체크리스트 |
| [`../legal/privacy-policy.ko.md`](../legal/privacy-policy.ko.md) | 개인정보처리방침 (한국어) |
| [`../legal/privacy-policy.en.md`](../legal/privacy-policy.en.md) | Privacy Policy (English) |

---

## 🤖 자동화됨

### CI/CD (GitHub Actions)
- **`.github/workflows/ci.yml`** — PR 시 analyze + test + Android/iOS smoke build
- **`.github/workflows/release.yml`** — `main` push 시:
  - Conventional Commits 분석 → semantic-release
  - `pubspec.yaml` version 자동 bump + `+buildNumber` 증가
  - `vX.Y.Z` 태그 + GitHub Release 생성
  - **서명된** Android AAB + APK 빌드 후 Release에 첨부 (secrets 있을 때)
  - iOS는 placeholder (Apple Dev 가입 전)

### 버전 관리
- `scripts/bump-pubspec-version.sh` — semantic-release가 호출
- `.releaserc.json` — commit prefix → 버전 bump 규칙

---

## 👤 사용자 액션 (1회성)

### A. Android 서명 키 발급 + GitHub Secrets 등록
```bash
# 1) keystore 생성 (안전한 곳에 보관, 분실 시 Play 앱 영구 잠금)
keytool -genkey -v -keystore ~/pill-mate-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2) Base64 인코딩 (GitHub Secrets는 binary 직접 못 받음)
base64 -i ~/pill-mate-upload.jks | pbcopy

# 3) GitHub repo > Settings > Secrets and variables > Actions 에 등록:
#    - ANDROID_KEYSTORE_BASE64    : (위에서 복사한 base64 문자열)
#    - ANDROID_KEYSTORE_PASSWORD  : keystore 비밀번호
#    - ANDROID_KEY_ALIAS          : upload
#    - ANDROID_KEY_PASSWORD       : key 비밀번호 (보통 keystore 비번과 동일)
```

→ 로컬에서 release 빌드할 때는 `android/key.properties` 작성 (`key.properties.example` 참고).

### B. Play Console 등록 + 양식 제출
- [ ] Play Developer 계정 생성 ($25 일회성)
- [ ] 앱 등록, 카테고리: **Medical** 또는 **Health & Fitness**
- [ ] **Data Safety form** 답변: `../legal/privacy-policy.ko.md` 하단 가이드 사용
- [ ] **Sensitive Permissions Declaration**: `play-console-permissions-justification.md` 텍스트 그대로 제출
- [ ] Privacy Policy URL 등록 (GitHub Pages 등에 호스팅 후)
- [ ] 스토어 자산 업로드: `store-assets-checklist.md` 참고

### C. Apple Developer Program (계정 발급 후)
- [ ] Apple Developer Program 가입 ($99/yr)
- [ ] App Store Connect에 앱 생성, Bundle ID: `com.gamja.pill_mate` 또는 새로 발급
- [ ] **App Store Connect API Key** 발급 (Users and Access > Integrations):
  - Issuer ID, Key ID, .p8 파일
- [ ] GitHub Secrets 등록:
  - `APPLE_API_KEY_ID`
  - `APPLE_API_ISSUER_ID`
  - `APPLE_API_KEY_P8` (파일 내용 base64)
- [ ] `release.yml`의 `build-ios` job을 `no-codesign smoke`에서 archive + TestFlight 업로드로 교체
- [ ] **PrivacyInfo.xcprivacy 파일을 Xcode에서 Runner 타겟에 추가**:
  - Xcode > Runner project > Runner target > Build Phases > Copy Bundle Resources에 자동 포함 여부 확인
  - 누락 시: Project Navigator에서 `Runner/PrivacyInfo.xcprivacy` 드래그하여 Add Files to "Runner" → Target Membership: Runner 체크

### D. 호스팅 — Privacy Policy URL
- [ ] GitHub Pages 활성화 (Settings > Pages > main branch > /docs)
- [ ] `docs/legal/privacy-policy.{ko,en}.md` 가 자동 렌더링되도록 `docs/index.md` 또는 `_config.yml` 추가
- [ ] 양 스토어 콘솔에 URL 등록

---

## 🔄 출시 흐름 (v1.0.0 첫 출시 기준)

```
1. main 브랜치에 feat/* PR merge          (한 번이라도 feat: 커밋 있어야 함)
   ↓
2. release.yml 자동 실행
   ↓
3. semantic-release가 v0.1.0 → v1.0.0 결정    (※ 첫 실행 시 1.0.0이 기본)
   ↓
4. pubspec.yaml = 1.0.0+N 으로 자동 bump 커밋
   ↓
5. git tag v1.0.0 + GitHub Release 생성
   ↓
6. Android AAB/APK 빌드 후 Release에 첨부
   ↓
7. 👤 (수동) Play Console > Production 트랙 또는 Internal Testing 트랙으로 AAB 업로드
   ↓
8. 👤 (수동) Play Console 심사 제출
```

iOS는 D 완료 후 `build-ios` job이 TestFlight 자동 업로드까지 처리하도록 교체.

---

## 첫 v1.0.0 릴리스 시 주의

semantic-release는 기본적으로 **태그가 없으면 1.0.0부터 시작**합니다.
현재 pubspec은 `0.1.0+1`이지만, 첫 자동 릴리스 시 `1.0.0` 태그로 점프합니다.

만약 0.x로 계속 가고 싶다면:
```bash
git tag v0.1.0
git push origin v0.1.0
# 이후 다음 feat: 커밋부터 v0.2.0으로 bump됨
```
