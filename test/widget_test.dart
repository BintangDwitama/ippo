import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const IppoApp());
    expect(find.text('一歩'), findsOneWidget);
  });
}
