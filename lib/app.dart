import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/pending_action_flusher.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/medication/data/calendar_providers.dart';
import 'features/medication/data/intake_providers.dart';
import 'features/medication/data/medication_providers.dart';

class PillMateApp extends ConsumerStatefulWidget {
  const PillMateApp({super.key, this.pendingDeepLink});

  /// 알림 cold start로 진입한 경우의 deep link 경로 (예: `/drawer/3`).
  /// 스플래시 자연 진행 후 한 번만 push.
  final String? pendingDeepLink;

  @override
  ConsumerState<PillMateApp> createState() => _PillMateAppState();
}

class _PillMateAppState extends ConsumerState<PillMateApp>
    with WidgetsBindingObserver {
  bool _consumed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final link = widget.pendingDeepLink;
    if (link != null) {
      // 스플래시(1.1s) + 첫 라우팅 안정화를 위해 약간의 지연 후 push.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_consumed || !mounted) return;
          _consumed = true;
          final router = ref.read(appRouterProvider);
          router.push(link);
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // resume 시 (1) bg dispatch가 실패해 큐에 적재된 액션이 있으면 flush,
    // (2) intake/meds 관련 provider 무효화 → 시간 경과로 stale해진 missed/
    //     pending 경계 재계산 + 백그라운드에서 변경된 데이터 반영.
    _refreshIntakeState();
  }

  Future<void> _refreshIntakeState() async {
    final container = ProviderScope.containerOf(context, listen: false);
    await PendingActionFlusher(container).flushAll();
    if (!mounted) return;
    container.invalidate(todayLogsProvider);
    container.invalidate(dayDosesProvider);
    container.invalidate(monthMarksProvider);
    container.invalidate(trackedMedicationsStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '필메이트',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
