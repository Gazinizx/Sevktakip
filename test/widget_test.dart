import 'package:flutter_test/flutter_test.dart';
import 'package:sevktakip/main.dart';

void main() {
  testWidgets('SevkTakip opens the dashboard', (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    expect(find.text('SEVKTAKİP'), findsOneWidget);
    expect(find.text('Günaydın, depo ekibi 👋'), findsOneWidget);
  });
}
