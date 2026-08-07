import 'package:byte_beam/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(const ByteBeamApp());

    expect(find.text('ByteBeam'), findsOneWidget);
  });
}
