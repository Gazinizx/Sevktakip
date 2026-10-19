import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const navy = Color(0xFF12233F);
const deep = Color(0xFF0B172B);
const mint = Color(0xFF43D6B0);
const canvas = Color(0xFFF5F7FB);
const muted = Color(0xFF7B879B);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
  }
  runApp(const SevkTakipApp());
}

class SevkTakipApp extends StatelessWidget {
  const SevkTakipApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SevkTakip', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: mint)),
    home: const HomeShell(),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int page = 0;
  final pages = const [
    ('Genel Bakış', Icons.grid_view_rounded), ('Siparişler', Icons.receipt_long_rounded),
    ('Depo Stoku', Icons.inventory_2_rounded), ('Sevkiyat', Icons.local_shipping_rounded),
    ('SKT Takibi', Icons.event_busy_rounded), ('Satın Alma', Icons.shopping_cart_checkout_rounded),
    ('İşlem Geçmişi', Icons.history_rounded),
  ];
  final products = [
    ['🍗', 'Çıtır tavuk', '20 adet', '23.10.2026', 'Yakın SKT'],
    ['🍗', 'Çıtır tavuk', '10 adet', '27.10.2026', 'Normal'],
    ['🍞', 'Brioche ekmek', '120 adet', '24.10.2026', 'Yakın SKT'],
    ['🍟', 'Patates kızartması', '65 kg', '18.01.2027', 'Normal'],
    ['🧴', 'Burger sosu', '8 paket', '02.11.2026', 'Normal'],
  ];
  final orders = [
    ['Kayseri Forum', 'SV-1048', 'Çıtır tavuk · 12 adet', 'Bekliyor'],
    ['Talas Şubesi', 'SV-1047', 'Patates · 8 kg, Burger sosu · 3 paket', 'Hazırlanıyor'],
    ['Kocasinan', 'SV-1046', 'Burger köftesi · 20 adet', 'Sevk edildi'],
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      drawer: wide ? null : Drawer(child: _sidebar()),
      body: Row(children: [
        if (wide) SizedBox(width: 252, child: _sidebar()),
        Expanded(child: Column(children: [
          Container(height: 76, padding: const EdgeInsets.symmetric(horizontal: 22), color: Colors.white,
            child: Row(children: [
              if (!wide) Builder(builder: (ctx) => IconButton(onPressed: () => Scaffold.of(ctx).openDrawer(), icon: const Icon(Icons.menu_rounded))),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pages[page].$1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
                const Text('Stok, sipariş ve sevkiyat kontrol merkezi', style: TextStyle(fontSize: 11, color: muted)),
              ])),
              const Icon(Icons.notifications_none_rounded, color: navy, size: 25),
              const SizedBox(width: 12),
              Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFE3F8F1), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.person_rounded, color: Color(0xFF168D71))),
            ])),
          Expanded(child: _content()),
        ])),
      ]),
    );
  }

  Widget _sidebar() => Container(color: deep, child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(22, 24, 18, 30), child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(13), child: SvgPicture.asset('assets/sevktakip-logo.svg', width: 44, height: 44)),
      const SizedBox(width: 12),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SEVKTAKİP', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        SizedBox(height: 3), Text('DEPO YÖNETİM SİSTEMİ', style: TextStyle(color: Color(0xFF93A4BD), fontSize: 9, letterSpacing: 1)),
      ]),
    ])),
    const Padding(padding: EdgeInsets.fromLTRB(22, 0, 22, 10), child: Text('ÇALIŞMA ALANI', style: TextStyle(color: Color(0xFF74869F), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4))),
    ...List.generate(pages.length, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        selected: page == i, selectedTileColor: const Color(0xFF223955),
        leading: Icon(pages[i].$2, color: page == i ? mint : const Color(0xFF93A4BD), size: 20),
        title: Text(pages[i].$1, style: TextStyle(color: page == i ? Colors.white : const Color(0xFFB4C0D1), fontSize: 13, fontWeight: page == i ? FontWeight.w700 : FontWeight.w500)),
        onTap: () { setState(() => page = i); if (MediaQuery.sizeOf(context).width < 900) Navigator.maybePop(context); },
      ),
    )),
    const Spacer(),
    Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF172A45), borderRadius: BorderRadius.circular(16)),
      child: const Row(children: [Icon(Icons.warehouse_rounded, color: mint), SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Merkez Depo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)), SizedBox(height: 3), Text('Demo çalışma alanı', style: TextStyle(color: Color(0xFF93A4BD), fontSize: 10))])]),
    ),
  ])));

  Widget _content() {
    if (page == 2 || page == 4) return _listPage(page == 2 ? 'Depo stoku' : 'SKT takip merkezi', page == 2 ? 'Ürün stokları SKT tarihine göre ayrı tutulur.' : 'Yaklaşan son kullanma tarihleri önceliklidir.', products.where((p) => page == 2 || p[4] == 'Yakın SKT').toList());
    if (page == 1 || page == 3 || page == 6) return _orderPage();
    if (page == 5) return _purchasePage();
    return _dashboard();
  }

  Widget _dashboard() => SingleChildScrollView(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: double.infinity, padding: const EdgeInsets.all(26), decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, Color(0xFF234B68)]), borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: mint.withValues(alpha: .16), borderRadius: BorderRadius.circular(30)), child: const Text('DEPO OPERASYONLARI', style: TextStyle(color: mint, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4))),
        const SizedBox(height: 14), const Text('Günaydın, depo ekibi 👋', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), const Text('Siparişleri hazırlayın, stokları takip edin ve SKT yaklaşan ürünleri kontrol edin.', style: TextStyle(color: Color(0xFFD0DCE8), fontSize: 12)),
        const SizedBox(height: 18), FilledButton.icon(onPressed: () => setState(() => page = 1), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Siparişlere git'), style: FilledButton.styleFrom(backgroundColor: mint, foregroundColor: deep)),
      ])),
    const SizedBox(height: 22),
    LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1000 ? 4 : c.maxWidth > 600 ? 2 : 1;
      return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: cols == 1 ? 3.0 : 1.45, children: [
        _metric('Stok kayıtları', products.length.toString(), Icons.inventory_2_rounded, const Color(0xFFE6EDFF), const Color(0xFF4D69C8)),
        _metric('Bekleyen sipariş', orders.where((o) => o[3] == 'Bekliyor').length.toString(), Icons.receipt_long_rounded, const Color(0xFFFFEFD8), const Color(0xFFBD7A19)),
        _metric('Yaklaşan SKT', products.where((p) => p[4] == 'Yakın SKT').length.toString(), Icons.event_busy_rounded, const Color(0xFFFFE4E4), const Color(0xFFD44B55)),
        _metric('Satın alma uyarısı', '2', Icons.shopping_cart_checkout_rounded, const Color(0xFFDDF7EF), const Color(0xFF168D71)),
      ]);
    }),
    const SizedBox(height: 22), _panel('Son siparişler', TextButton(onPressed: () => setState(() => page = 1), child: const Text('Tüm siparişler')), Column(children: orders.map(_orderRow).toList())),
    const SizedBox(height: 16), _panel('SKT uyarıları', TextButton(onPressed: () => setState(() => page = 4), child: const Text('Tümünü gör')), Column(children: products.where((p) => p[4] == 'Yakın SKT').map(_productRow).toList())),
  ]));

  Widget _metric(String label, String value, IconData icon, Color bg, Color fg) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE9EDF4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 40, height: 40, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: fg)),
    const Spacer(), Text(value, style: const TextStyle(color: navy, fontSize: 26, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: muted, fontSize: 11)),
  ]));
  Widget _panel(String title, Widget? action, Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE9EDF4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 14))), if (action != null) action]),
    const SizedBox(height: 8), child,
  ]));
  Widget _listPage(String title, String subtitle, List<List<String>> items) => SingleChildScrollView(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 20), _panel('Ürün kayıtları', null, Column(children: items.map(_productRow).toList())),
  ]));
  Widget _productRow(List<String> p) => ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 4), leading: Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFEAF2F6), borderRadius: BorderRadius.circular(13)), child: Text(p[0], style: const TextStyle(fontSize: 21))), title: Text(p[1], style: const TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 12)), subtitle: Text(p[2] + ' · SKT ' + p[3], style: const TextStyle(color: muted, fontSize: 11)), trailing: _pill(p[4], p[4] == 'Yakın SKT' ? const Color(0xFFFFE7E7) : const Color(0xFFDDF7EF), p[4] == 'Yakın SKT' ? const Color(0xFFC64C55) : const Color(0xFF168D71)));
  Widget _orderPage() => SingleChildScrollView(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Şube siparişleri ve sevkiyat', style: TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 7), const Text('Şube siparişlerini izle ve sevkiyat durumunu güncelle.', style: TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 20), _panel('Sipariş kuyruğu', null, Column(children: orders.map(_orderRow).toList())),
    const SizedBox(height: 16), _panel('Sevkiyat güvenliği', null, const Text('Ürün miktarı ve hangi SKT kaydından çıktığı ayrı ayrı tutulmalıdır. Bu ilk sürüm demo verileriyle çalışır; gerçek stok düşümü henüz bağlı değildir.', style: TextStyle(color: muted, height: 1.6))),
  ]));
  Widget _orderRow(List<String> o) => ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 4), leading: const CircleAvatar(backgroundColor: Color(0xFFE3F8F1), child: Icon(Icons.storefront_rounded, color: Color(0xFF168D71))), title: Text(o[0], style: const TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 12)), subtitle: Text(o[1] + ' · ' + o[2], style: const TextStyle(color: muted, fontSize: 11)), trailing: _pill(o[3], o[3] == 'Sevk edildi' ? const Color(0xFFDDF7EF) : const Color(0xFFE6EDFF), o[3] == 'Sevk edildi' ? const Color(0xFF168D71) : const Color(0xFF4D69C8)));
  Widget _purchasePage() => SingleChildScrollView(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Satın alma listesi', style: TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 7), const Text('Minimum stok altındaki ürünler ana şirkete sipariş önerisi oluşturur.', style: TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 20), _panel('Önerilen alımlar', null, const Column(children: [
      ListTile(leading: Icon(Icons.shopping_cart_outlined, color: Color(0xFFC64C55)), title: Text('Burger sosu'), subtitle: Text('8 paket mevcut · Minimum 12 paket')),
      ListTile(leading: Icon(Icons.shopping_cart_outlined, color: Color(0xFFC64C55)), title: Text('Baharat karışımı'), subtitle: Text('3 paket mevcut · Minimum 8 paket')),
    ])),
  ]));
  Widget _historyPage() => _orderPage();
  Widget _pill(String text, Color bg, Color fg) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)), child: Text(text, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w800)));
}
