import 'package:flutter_test/flutter_test.dart';
import 'package:sevktakip/main.dart';

void main() {
  testWidgets('opens without login and offers store and depot roles',
      (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    expect(find.text('SEVKTAKİP'), findsOneWidget);
    expect(find.text('Mağaza'), findsOneWidget);
    expect(find.text('Depo'), findsOneWidget);
    expect(find.text('Hesap gerekmez.'), findsOneWidget);
  });

  testWidgets('store role opens the shared-data store dashboard',
      (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    await tester.tap(find.text('Mağaza'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(find.text('Mağaza'), findsOneWidget);
    expect(find.text('Ürünler'), findsOneWidget);
    expect(find.text('Siparişler'), findsOneWidget);
  });

  testWidgets('depot role opens stock, requests and movement navigation',
      (tester) async {
    await tester.pumpWidget(const SevkTakipApp());
    await tester.tap(find.text('Depo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(find.text('Stok'), findsOneWidget);
    expect(find.text('Talepler'), findsOneWidget);
    expect(find.text('Hareketler'), findsOneWidget);
  });
}
