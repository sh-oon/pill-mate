import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pill_mate/app.dart';

void main() {
  testWidgets('app boots and shows 필메이트 title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PillMateApp()),
    );
    await tester.pump();

    expect(find.text('필메이트'), findsWidgets);
  });
}
