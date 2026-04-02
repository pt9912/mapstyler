import 'package:flutter_test/flutter_test.dart';

import 'package:mapstyler_demo/main.dart';

void main() {
  testWidgets('renders workspace demo shell', (tester) async {
    await tester.pumpWidget(const MapstylerDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Mapstyler Workspace Demo'), findsOneWidget);
    expect(find.text('mapstyler_style'), findsOneWidget);
    expect(find.text('flutter_mapstyler'), findsOneWidget);
    expect(find.text('Core'), findsOneWidget);
  });
}
