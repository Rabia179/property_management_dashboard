import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_dashboard/main.dart';

void main() {
  testWidgets('Property Dashboard starts', (tester) async {
    await tester.pumpWidget(const PropertyApp());
    await tester.pump();

    expect(find.byType(PropertyApp), findsOneWidget);
  });
}