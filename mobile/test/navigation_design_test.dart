import 'package:bongo_foodie/core/widgets/bongo_glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigation fits a narrow phone and preserves all actions', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(bottomNavigationBar: BongoGlassNavBar(
        currentIndex: 0,
        cartCount: 3,
        onTap: (index) => selected = index,
      )),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Cart'));
    expect(selected, 3);
  });
}
