import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const ink = Color(0xFF172B4D);
const green = Color(0xFF16856B);
const paper = Color(0xFFF4F6FA);
const supabaseUrl = 'https://zazbwooscaiahzrgpnkh.supabase.co';
const supabaseKey = 'sb_publishable_cN341boWg-G4gghy1d4I7g_P1dylGZh';
final db = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(const SevkTakipApp());
}

class SevkTakipApp extends StatelessWidget {
  const SevkTakipApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SevkTakip', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: ink),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: ink, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
    home: const RoleSelectScreen());
}

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.warehouse_rounded, size: 72, color: green),
          const SizedBox(height: 14),
          const Text('SEVKTAKİP', textAlign: TextAlign.center,
            style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Ortak depo ve mağaza stok yönetimi', textAlign: TextAlign.center),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen(role: 'magaza'))),
            icon: const Icon(Icons.storefront_outlined), label: const Padding(padding: EdgeInsets.all(12), child: Text('Mağaza', style: TextStyle(fontSize: 17)))),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen(role: 'depo'))),
            icon: const Icon(Icons.inventory_2_outlined), label: const Padding(padding: EdgeInsets.all(12), child: Text('Depo', style: TextStyle(fontSize: 17)))),
          const SizedBox(height: 18),
          const Text('Hesap gerekmez. Stok ve talepler tüm cihazlarda ortak veritabanından yüklenir.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      )),
    ))),
  );
}

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, required this.role});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  List<Map<String,dynamic>> products = [], orders = [];
  String role = 'magaza', displayName = '';
  bool loading = true, busy = false;
  int tab = 0;
  bool get depot => role == 'depo';
  @override
  void initState() { super.initState(); role = widget.role; displayName = role == 'depo' ? 'Depo' : 'Mağaza'; load(); }
  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      products = List<Map<String,dynamic>>.from(await db.from('products').select().order('name'));
      orders = List<Map<String,dynamic>>.from(await db.from('orders').select('*,order_lines(*,products(name,unit))').order('created_at', ascending: false));
    } catch (e) { if (mounted) message('Veriler alınamadı: ' + e.toString(), true); }
    if (mounted) setState(() => loading = false);
  }
  void message(String text, [bool error = false]) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red : ink));
  Future<void> run(Future<void> Function() action) async {
    if (busy) return; setState(() => busy = true);
    try { await action(); await load(); }
    catch (e) { if (mounted) message('İşlem tamamlanamadı: ' + e.toString(), true); }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final titles = depot ? ['Genel Bakış','Depo Stoku','Talepler','Hareketler'] : ['Genel Bakış','Ürünler','Siparişlerim'];
    if (tab >= titles.length) tab = 0;
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titles[tab], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(displayName.isEmpty ? (depot ? 'Depocu alanı' : 'Mağaza alanı') : 'Merhaba, ' + displayName, style: const TextStyle(fontSize: 11, color: Colors.black54))]),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh)), IconButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectScreen())), tooltip: 'Rol değiştir', icon: const Icon(Icons.swap_horiz))]),
      body: IndexedStack(index: tab, children: [dashboard(), depot ? stockPage() : storePage(), depot ? requestsPage() : storeOrders(), if (depot) historyPage()]),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i),
        destinations: depot ? const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Özet'), NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Stok'), NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Talepler'), NavigationDestination(icon: Icon(Icons.history), label: 'Hareketler')] : const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Özet'), NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Ürünler'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Siparişler')]),
      floatingActionButton: depot && tab == 1 ? FloatingActionButton.extended(onPressed: addProduct, icon: const Icon(Icons.add), label: const Text('Ürün ekle')) : !depot && tab == 1 ? FloatingActionButton.extended(onPressed: () => createOrder(), icon: const Icon(Icons.add_shopping_cart), label: const Text('Talep oluştur')) : null);
  }
  Widget dashboard() {
    final pending = orders.where((o) => o['status'] == 'Bekliyor').length;
    final approved = orders.where((o) => o['status'] == 'Onaylandı').length;
    final low = products.where((p) => (p['quantity'] as num) <= (p['minimum'] as num)).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(22)), child: Text(depot ? 'Depo taleplerini incele ve stok hareketlerini yönet.' : 'İhtiyacın olan ürünleri ortak depodan talep et.', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
      const SizedBox(height: 16), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.5, children: [
        metric('Ürün çeşidi', products.length.toString()), metric(depot ? 'Bekleyen talep' : 'Siparişler', (depot ? pending : orders.length).toString()), metric('Kritik stok', low.toString()), metric('Onaylanan', approved.toString())]),
      const SizedBox(height: 16), const Text('Son talepler', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 17)), ...orders.take(5).map(orderCard)
    ]);
  }
  Widget metric(String label, String value) => Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.inventory_2_outlined, color: green), Text(value, style: const TextStyle(color: ink, fontSize: 25, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))])));
  Widget stockPage() => ListView(padding: const EdgeInsets.all(12), children: [
    if (products.isEmpty) const Text('Henüz ürün yok'),
    ...products.map((p) => Card(color: Colors.white, child: ListTile(title: Text(p['name'].toString()), subtitle: Text('Minimum: ' + p['minimum'].toString() + ' ' + p['unit'].toString()), trailing: Text(p['quantity'].toString() + ' ' + p['unit'].toString()), onTap: () => addStock(p))))
  ]);
  Widget storePage() => ListView(padding: const EdgeInsets.all(12), children: [
    if (products.isEmpty) const Text('Depoda henüz ürün yok'),
    ...products.map((p) => Card(color: Colors.white, child: ListTile(title: Text(p['name'].toString()), subtitle: Text('Stok: ' + p['quantity'].toString() + ' ' + p['unit'].toString()), trailing: const Icon(Icons.add_shopping_cart), onTap: () => createOrder(initialProduct: p['id'].toString()))))
  ]);
  Widget storeOrders() => ListView(padding: const EdgeInsets.all(12), children: orders.map(orderCard).toList());
  Widget requestsPage() => ListView(padding: const EdgeInsets.all(12), children: orders.where((o) => o['status'] == 'Bekliyor').map((o) => orderCard(o, actions: true)).toList());
  Widget historyPage() => ListView(padding: const EdgeInsets.all(12), children: orders.where((o) => o['status'] != 'Bekliyor').map(orderCard).toList());
  Widget orderCard(Map<String,dynamic> order, {bool actions = false}) {
    final lines = List<Map<String,dynamic>>.from((order['order_lines'] as List<dynamic>? ?? []).map((x) => Map<String,dynamic>.from(x as Map)));
    final id = order['id'].toString();
    return Card(color: Colors.white, margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Talep #' + id.substring(0, id.length < 6 ? id.length : 6) + ' · ' + order['status'].toString(), style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
      ...lines.map((l) { final p = l['products'] is Map ? Map<String,dynamic>.from(l['products'] as Map) : <String,dynamic>{}; return Text('• ' + (p['name']?.toString() ?? 'Ürün') + ' × ' + l['quantity'].toString() + ' ' + (p['unit']?.toString() ?? '')); }),
      if ((order['note'] as String? ?? '').isNotEmpty) Text('Not: ' + order['note'].toString()),
      if (actions) Row(children: [Expanded(child: OutlinedButton(onPressed: () => handleOrder(id, false), child: const Text('Reddet'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () => handleOrder(id, true), child: const Text('Onayla ve stok düş')))])
    ])));
  }
  Future<void> addProduct() async {
    final name = TextEditingController(), qty = TextEditingController(text: '0'), min = TextEditingController(text: '5');
    String unit = 'koli';
    final result = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setD) => AlertDialog(title: const Text('Yeni ürün'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Ürün adı')), DropdownButtonFormField<String>(value: unit, items: const [DropdownMenuItem(value: 'adet', child: Text('Adet')), DropdownMenuItem(value: 'koli', child: Text('Koli'))], onChanged: (v) => setD(() => unit = v ?? 'koli')), TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Başlangıç stoku')), TextField(controller: min, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum stok'))
    ])), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Kaydet'))])));
    if (result == true) { final q = int.tryParse(qty.text) ?? -1, m = int.tryParse(min.text) ?? -1; if (name.text.trim().isEmpty || q < 0 || m < 0) { message('Ürün bilgilerini kontrol et.', true); } else { await run(() async { await db.from('products').insert({'name': name.text.trim(), 'unit': unit, 'quantity': q, 'minimum': m}); }); } }
    name.dispose(); qty.dispose(); min.dispose();
  }
  Future<void> addStock(Map<String,dynamic> p) async {
    final c = TextEditingController(text: '1');
    final amount = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(title: Text(p['name'].toString()), content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Eklenecek miktar')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')), FilledButton(onPressed: () { final n = int.tryParse(c.text); if (n != null && n > 0) Navigator.pop(ctx, n); }, child: const Text('Ekle'))]));
    c.dispose(); if (amount == null) return;
    await run(() async { await db.from('products').update({'quantity': (p['quantity'] as num).toInt() + amount, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', p['id']); await db.from('stock_movements').insert({'product_id': p['id'], 'changed_by': null, 'delta': amount, 'reason': 'Elle stok ekleme'}); });
  }
  Future<void> createOrder({String? initialProduct}) async {
    if (products.isEmpty) { message('Önce depocu ürün eklemeli.', true); return; }
    final controls = {for (final p in products) p['id'].toString(): TextEditingController(text: p['id'].toString() == initialProduct ? '1' : '0')};
    final note = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Depoya talep oluştur'), content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ...products.map((p) => Row(children: [Expanded(child: Text(p['name'].toString() + ' (stok: ' + p['quantity'].toString() + ' ' + p['unit'].toString() + ')')), SizedBox(width: 70, child: TextField(controller: controls[p['id'].toString()], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Adet')))])),
      TextField(controller: note, decoration: const InputDecoration(labelText: 'Açıklama'))
    ]))), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')), FilledButton(onPressed: () { if (controls.values.any((c) => (int.tryParse(c.text) ?? 0) > 0) && controls.values.every((c) => (int.tryParse(c.text) ?? -1) >= 0)) Navigator.pop(ctx, true); }, child: const Text('Talebi gönder'))]));
    if (result == true) {
      final lines = controls.entries.map((e) => {'product_id': e.key, 'quantity': int.tryParse(e.value.text) ?? 0}).where((e) => (e['quantity'] as int) > 0).toList();
      await run(() async { final o = await db.from('orders').insert({'created_by': null, 'note': note.text.trim()}).select('id').single(); await db.from('order_lines').insert(lines.map((l) => {...l, 'order_id': o['id']}).toList()); if (mounted) setState(() => tab = 2); });
    }
    for (final c in controls.values) { c.dispose(); } note.dispose();
  }
  Future<void> handleOrder(String id, bool approve) async {
    await run(() async { await db.rpc('handle_order', params: {'p_order_id': id, 'p_approve': approve}); });
    if (mounted) message(approve ? 'Talep onaylandı, stok düşüldü.' : 'Talep reddedildi.');
  }
}
