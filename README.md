# Pill Mate (필메이트)

> Offline medication & supplement tracker. Local notifications, calendar, reports.
> No account, no cloud, no ads. iOS + Android.

**Status**: Pre-release (v0.1.0). Heading toward v1.0.0 store launch.

## Tech stack

- **Flutter** 3.41.9 (pinned via `.fvmrc`)
- **State**: flutter_riverpod 3 + generators
- **Routing**: go_router
- **DB**: Drift (SQLite) — local only
- **Notifications**: flutter_local_notifications + timezone-aware scheduling
- **iOS UI**: cupertino_native_better (UIKit Liquid Glass via PlatformView)

## Local development

```bash
# Use the pinned Flutter version
fvm use
fvm flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Run on device
fvm flutter run

# Tests
fvm flutter test
```

## Releases

Versioning is **fully automated** via [Conventional Commits](https://www.conventionalcommits.org) + semantic-release.

| Commit prefix | Bumps |
|---------------|-------|
| `feat:`  | minor (1.0.0 → 1.1.0) |
| `fix:` / `perf:` / `refactor:` | patch (1.0.0 → 1.0.1) |
| `BREAKING CHANGE:` footer | major (1.0.0 → 2.0.0) |
| `docs:` / `chore:` / `ci:` / `test:` | no release |

On every push to `main`, `.github/workflows/release.yml`:
1. Analyzes commits since the last `v*` tag
2. Bumps `pubspec.yaml` version + increments build number
3. Tags `vX.Y.Z` + creates GitHub Release with changelog
4. Builds signed Android AAB + APK and attaches them
5. (iOS) builds smoke until Apple Dev account + secrets are added

See [`docs/00-release/`](docs/00-release/) for the full release runbook.

## Project structure

```
lib/
├── core/                # database, notifications, router, theme, widgets
└── features/            # home, medication, calendar, settings, splash, onboarding
docs/
├── 00-release/          # store submission, signing, CI
├── 01-plan/             # PDCA plan documents
├── 02-design/           # design docs (notifications, deep link, isolate)
└── legal/               # privacy policy (ko / en)
```

## Security & privacy

- Fully offline — no network, no telemetry, no analytics SDKs.
- See [`docs/legal/privacy-policy.ko.md`](docs/legal/privacy-policy.ko.md).
- See [`ios/Runner/PrivacyInfo.xcprivacy`](ios/Runner/PrivacyInfo.xcprivacy) for declared API usage.

## License

See [`LICENSE`](LICENSE).
