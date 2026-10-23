import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sevktakip/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens without login and shows both work areas', (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    await tester.pumpAndSettle();

    expect(find.text('SEVKTAKİP'), findsOneWidget);
    expect(find.text('Mağaza'), findsOneWidget);
    expect(find.text('Depocu'), findsOneWidget);
  });

  testWidgets('depot stock page opens and offers product creation',
      (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Depocu'));
    await tester.pumpAndSettle();
    expect(find.text('Genel Bakış'), findsOneWidget);

    await tester.tap(find.text('Stok'));
    await tester.pumpAndSettle();

    expect(find.text('Depo Stoku'), findsOneWidget);
    expect(find.text('Ürün ekle'), findsOneWidget);
    expect(find.text('Tavuk fileto'), findsOneWidget);
    expect(find.text('Patates'), findsOneWidget);
  });

  testWidgets('store area opens without login', (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mağaza'));
    await tester.pumpAndSettle();

    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(find.text('Mağaza alanı'), findsOneWidget);

    await tester.tap(find.text('Ürünler'));
    await tester.pumpAndSettle();
    expect(find.text('Tavuk fileto'), findsOneWidget);
    expect(find.text('Birim: koli'), findsNothing);
  });
}
