import 'package:flutter_test/flutter_test.dart';

import 'package:mapstyler_demo/main.dart';

void main() {
  testWidgets('rendert Workspace-Demo-Shell', (tester) async {
    await tester.pumpWidget(const MapstylerDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Mapstyler Workspace Demo'), findsOneWidget);
    expect(find.text('mapstyler_style'), findsOneWidget);
    expect(find.text('flutter_mapstyler'), findsOneWidget);
    expect(find.text('Core'), findsOneWidget);
  });

  testWidgets('zeigt alle Style-Segmente', (tester) async {
    await tester.pumpWidget(const MapstylerDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Core'), findsOneWidget);
    expect(find.text('Mapbox'), findsOneWidget);
    expect(find.text('QML'), findsOneWidget);
    expect(find.text('SLD'), findsOneWidget);
  });

  testWidgets('Style-Umschaltung aendert Titel', (tester) async {
    await tester.pumpWidget(const MapstylerDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Core Style'), findsWidgets);

    await tester.tap(find.text('Mapbox'));
    await tester.pumpAndSettle();
    expect(find.text('Mapbox Style'), findsWidgets);

    await tester.tap(find.text('QML'));
    await tester.pumpAndSettle();
    expect(find.text('QML Style'), findsWidgets);

    await tester.tap(find.text('SLD'));
    await tester.pumpAndSettle();
    expect(find.text('SLD Style'), findsWidgets);
  });
}
