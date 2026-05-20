import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class PillMateApp extends ConsumerStatefulWidget {
  const PillMateApp({super.key, this.pendingDeepLink});

  /// 알림 cold start로 진입한 경우의 deep link 경로 (예: `/drawer/3`).
  /// 스플래시 자연 진행 후 한 번만 push.
  final String? pendingDeepLink;

  @override
  ConsumerState<PillMateApp> createState() => _PillMateAppState();
}

class _PillMateAppState extends ConsumerState<PillMateApp> {
  bool _consumed = false;

  @override
  void initState() {
    super.initState();
    final link = widget.pendingDeepLink;
    if (link == null) return;
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
