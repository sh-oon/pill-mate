import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 온보딩 완료 여부 영속화.
class OnboardingStorage {
  OnboardingStorage(this._prefs);

  static const String _key = 'pm.onboarding.completed.v1';

  final SharedPreferences _prefs;

  bool get isCompleted => _prefs.getBool(_key) ?? false;

  Future<void> markCompleted() => _prefs.setBool(_key, true);

  Future<void> reset() => _prefs.remove(_key);
}

/// SharedPreferences 인스턴스를 부트스트랩에서 한 번 로드 후 주입.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  ),
);

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  return OnboardingStorage(ref.watch(sharedPreferencesProvider));
});

/// 현재 상태 + 변경 시 라우터 재평가용 Notifier.
class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(onboardingStorageProvider).isCompleted;

  Future<void> complete() async {
    await ref.read(onboardingStorageProvider).markCompleted();
    state = true;
  }

  Future<void> reset() async {
    await ref.read(onboardingStorageProvider).reset();
    state = false;
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(
  OnboardingCompletedNotifier.new,
);
