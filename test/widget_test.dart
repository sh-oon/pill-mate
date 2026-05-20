import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pill_mate/app.dart';
import 'package:pill_mate/core/storage/onboarding_storage.dart';

ProviderScope _boot(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const PillMateApp(),
  );
}

/// flutter_test 기본 viewport(800×600)는 폰 UI를 가정하는 본 앱과 맞지 않아
/// onboarding Column이 RenderFlex overflow를 일으킴. iPhone 14 Pro 사이즈로 고정.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('splash → onboarding (first launch)', (tester) async {
    _usePhoneViewport(tester);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_boot(prefs));

    // 스플래시 즉시 노출
    expect(find.text('필메이트'), findsOneWidget);

    // 스플래시 + 라우터 전환 대기
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('필이에요!'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('시간에 맞춰 알려드려요'), findsOneWidget);
    expect(find.text('복용 기록을 보여드려요'), findsOneWidget);
    expect(find.text('기록은 기기에만 저장돼요'), findsOneWidget);
  });

  testWidgets('splash → home (onboarding already completed)',
      (tester) async {
    _usePhoneViewport(tester);
    SharedPreferences.setMockInitialValues({
      'pm.onboarding.completed.v1': true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_boot(prefs));

    expect(find.text('필메이트'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // 홈 화면 노출
    expect(find.text('오늘 복용'), findsOneWidget);
  });
}
