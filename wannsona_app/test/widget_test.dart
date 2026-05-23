import 'package:flutter_test/flutter_test.dart';
import 'package:wannsona_app/main.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WannsonaApp());
  });
}
