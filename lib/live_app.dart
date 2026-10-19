import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _navy = Color(0xFF12233F);
const _mint = Color(0xFF43D6B0);
const _muted = Color(0xFF7B879B);

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    if (!supabaseConfigured) return const HomeShell();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (Supabase.instance.client.auth.currentSession == null) return const SignInPage();
        return const LiveHomePage();
      },
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}
class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool signup = false, busy = false;
  String? error;
  @override
  void dispose() { email.dispose(); password.dispose(); name.dispose(); super.dispose(); }
  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (signup) {
        await auth.signUp(email: email.text.trim(), password: password.text, data: {'full_name': name.text.trim()});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt oluşturuldu. Yönetici rol ve şube ataması yapmalıdır.')));
      } else {
        await auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Padding(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.local_shipping_rounded, color: _mint, size: 38)),
        const SizedBox(height: 18), const Text('SEVKTAKİP', style: TextStyle(color: _navy, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.4)),
        const SizedBox(height: 8), Text(signup ? 'Yeni hesap oluştur' : 'Depo ve şube giriş ekranı', style: const TextStyle(color: _muted)),
        if (signup) ...[const SizedBox(height: 14), TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad soyad', border: OutlineInputBorder()))],
        const SizedBox(height: 14), TextField(controller: email, decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder())),
        const SizedBox(height: 14), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder())),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        const SizedBox(height: 18), FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Bekle...' : signup ? 'Kayıt ol' : 'Giriş yap')),
        TextButton(onPressed: () => setState(() { signup = !signup; error = null; }), child: Text(signup ? 'Giriş ekranına dön' : 'Yeni hesap oluştur')),
        const Text('Yeni hesaplar varsayılan şube rolündedir. Depo/yönetici yetkisi yönetici tarafından atanır.', style: TextStyle(color: _muted, fontSize: 11)),
      ])),
    ))));

class LiveHomePage extends StatefulWidget {
  const LiveHomePage({super.key});
  @override
  State<LiveHomePage> createState() => _LiveHomePageState();
}
class _LiveHomePageState extends State<LiveHomePage> {
  final db = Supabase.instance.client;
  int tab = 0, revision = 0;
  Map<String,dynamic>? profile;
  bool loading = true;
  RealtimeChannel? channel;
  final titles = const ['Genel Bakış', 'Stok ve SKT', 'Siparişler', 'Satın Alma'];
  @override
  void initState() { super.initState(); loadProfile(); channel = db.channel('sevktakip-live')
    .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'orders', callback: (_) => refresh())
    .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'stock_batches', callback: (_) => refresh())
    .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'products', callback: (_) => refresh()).subscribe(); }
  @override
  void dispose() { if (channel != null) db.removeChannel(channel!); super.dispose(); }
  void refresh() { if (mounted) setState(() => revision++); }
  Future<void> loadProfile() async {
    try { profile = await db.from('profiles').select().eq('id', db.auth.currentUser!.id).maybeSingle(); } catch (_) {}
    if (mounted) setState(() => loading = false);
  }
  bool get depot => profile?['role'] == 'depo' || profile?['role'] == 'yonetici';
  void toast(String s, {bool error = false}) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error ? Colors.red : _navy, content: Text(s))); }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (profile == null || profile?['active'] == false) return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_outline, size: 44), const SizedBox(height: 12), const Text('Hesap yetkisi bekleniyor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const Text('Yönetici, Supabase içinden hesabı etkinleştirip rol ve şube atamalı.', textAlign: TextAlign.center),
      FilledButton(onPressed: () => db.auth.signOut(), child: const Text('Çıkış yap')),
    ]))));
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(drawer: wide ? null : Drawer(child: navigation()), body: Row(children: [
      if (wide) SizedBox(width: 245, child: navigation()),
      Expanded(child: Column(children: [
        Container(height: 70, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          if (!wide) Builder(builder: (ctx) => IconButton(onPressed: () => Scaffold.of(ctx).openDrawer(), icon: const Icon(Icons.menu))),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titles[tab], style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w900)),
            Text((profile?['full_name'] ?? 'SevkTakip') .toString() + ' · ' + (profile?['role'] ?? '').toString(), style: const TextStyle(color: _muted, fontSize: 11)),
          ])),
          IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)), IconButton(onPressed: () => db.auth.signOut(), icon: const Icon(Icons.logout)),
        ])),
        Expanded(child: IndexedStack(index: tab, children: [dashboard(), stockPage(), ordersPage(), purchasePage()])),
      ])),
    ]));
  }

  Widget navigation() => Container(color: const Color(0xFF0B172B), child: SafeArea(child: Column(children: [
    const Padding(padding: EdgeInsets.all(22), child: Row(children: [Icon(Icons.local_shipping_rounded, color: _mint, size: 34), SizedBox(width: 10), Text('SEVKTAKİP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2))])),
    ...List.generate(titles.length, (i) => ListTile(selected: tab == i, selectedTileColor: const Color(0xFF223955), leading: Icon([Icons.grid_view, Icons.inventory_2, Icons.receipt_long, Icons.shopping_cart][i], color: tab == i ? _mint : Colors.white70), title: Text(titles[i], style: TextStyle(color: tab == i ? Colors.white : Colors.white70, fontSize: 13)), onTap: () { setState(() => tab = i); if (MediaQuery.sizeOf(context).width < 850) Navigator.maybePop(context); })),
    const Spacer(), const Padding(padding: EdgeInsets.all(16), child: Text('CANLI VERİ', style: TextStyle(color: Colors.white54, fontSize: 10))),
  ])));

  Widget dashboard() => FutureBuilder<List<dynamic>>(key: ValueKey('dash$revision'), future: Future.wait([
    db.from('products').select('id').eq('active', true),
    db.from('orders').select('id').inFilter('status', ['bekliyor','hazirlaniyor','sevk_edildi']),
    db.from('stock_batches').select('id,expiry_date').eq('location_type', depot ? 'depo' : 'sube').gt('quantity', 0),
  ]), builder: (context, snap) {
    if (snap.hasError) return errorWidget(snap.error.toString());
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final p = snap.data![0] as List, o = snap.data![1] as List, s = snap.data![2] as List;
    final today = DateTime.now();
    final soon = s.where((x) { final d = DateTime.tryParse(x['expiry_date'].toString()); return d != null && !d.isBefore(DateTime(today.year,today.month,today.day)) && d.difference(today).inDays <= 7; }).length;
    return ListView(padding: const EdgeInsets.all(24), children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, Color(0xFF234B68)]), borderRadius: BorderRadius.circular(22)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OPERASYON MERKEZİ', style: TextStyle(color: _mint, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
        SizedBox(height: 12), Text('Stok kontrol altında.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        SizedBox(height: 8), Text('Sipariş, sevkiyat ve son kullanma tarihleri tek merkezde.', style: TextStyle(color: Colors.white70)),
      ])),
      const SizedBox(height: 18), Wrap(spacing: 12, runSpacing: 12, children: [
        metric('Aktif ürün', p.length.toString(), Icons.inventory_2), metric('Açık sipariş', o.length.toString(), Icons.receipt_long), metric('7 gün içinde SKT', soon.toString(), Icons.event_busy),
      ]),
      const SizedBox(height: 18), note('Canlı senkronizasyon', 'Sipariş ve stok değişiklikleri Supabase Realtime ile yenilenir. Gerçek kullanım için önce veritabanı migration dosyasını çalıştır.'),
    ]);
  });

  Widget stockPage() => FutureBuilder<List<dynamic>>(key: ValueKey('stock$revision'), future: Future.wait([
    db.from('stock_batches').select('id,product_id,location_type,expiry_date,quantity,products(name,unit)').eq('location_type', depot ? 'depo' : 'sube').order('expiry_date'),
    db.from('products').select('id,name,unit').eq('active', true).order('name'),
  ]), builder: (context, snap) {
    if (snap.hasError) return errorWidget(snap.error.toString());
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final batches = (snap.data![0] as List).cast<Map<String,dynamic>>();
    final products = (snap.data![1] as List).cast<Map<String,dynamic>>();
    return ListView(padding: const EdgeInsets.all(22), children: [
      Row(children: [const Expanded(child: Text('Stok ve SKT kayıtları', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w900))), if (depot) PopupMenuButton<String>(onSelected: (v) { if (v == 'stock') addStock(products); if (v == 'product') addProduct(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'stock', child: Text('Stok girişi')), PopupMenuItem(value: 'product', child: Text('Ürün tanımla'))], child: const Chip(label: Text('+ Ekle')))]),
      const SizedBox(height: 8), const Text('Aynı ürün farklı SKT tarihleriyle ayrı ayrı izlenir.', style: TextStyle(color: _muted, fontSize: 12)),
      const SizedBox(height: 14), if (batches.isEmpty) note('Stok kaydı yok', 'Depo kullanıcısı ürün ve SKT bazında stok girişi yapabilir.'),
      ...batches.map((b) { final p = (b['products'] as Map<String,dynamic>?) ?? {}; final d = DateTime.tryParse(b['expiry_date'].toString()); final warning = d != null && d.difference(DateTime.now()).inDays <= 7; return Card(color: Colors.white, elevation: 0, child: ListTile(leading: const Icon(Icons.inventory_2, color: _navy), title: Text((p['name'] ?? 'Ürün').toString(), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('SKT: ' + b['expiry_date'].toString()), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(b['quantity'].toString() + ' ' + (p['unit'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w900)), Text(warning ? 'SKT yaklaşıyor' : 'Stokta', style: TextStyle(color: warning ? Colors.red : Colors.green, fontSize: 10))]))); }),
    ]);
  });

  Future<void> addStock(List<Map<String,dynamic>> products) async {
    if (products.isEmpty) { await addProduct(); return; }
    String productId = products.first['id'].toString();
    final qty = TextEditingController(text: '1');
    DateTime expiry = DateTime.now().add(const Duration(days: 30));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, modal) => AlertDialog(title: const Text('Stok girişi'), content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(value: productId, isExpanded: true, items: products.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'].toString()))).toList(), onChanged: (v) { if (v != null) modal(() => productId = v); }, decoration: const InputDecoration(labelText: 'Ürün')),
      TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Miktar')),
      TextButton.icon(onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: expiry, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) modal(() => expiry = d); }, icon: const Icon(Icons.calendar_month), label: Text('SKT: ' + expiry.day.toString().padLeft(2,'0') + '.' + expiry.month.toString().padLeft(2,'0') + '.' + expiry.year.toString())),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet'))])));
    if (ok == true) {
      try { final amount = double.tryParse(qty.text.replaceAll(',', '.')) ?? 0; if (amount <= 0) throw Exception('Miktar geçersiz'); await db.rpc('receive_stock', params: {'p_product_id': productId, 'p_quantity': amount, 'p_expiry_date': expiry.year.toString() + '-' + expiry.month.toString().padLeft(2,'0') + '-' + expiry.day.toString().padLeft(2,'0'), 'p_note': ''}); refresh(); toast('Stok kaydedildi.'); }
      catch (e) { toast('Stok kaydedilemedi: ' + e.toString(), error: true); }
    }
    qty.dispose();
  }

  Future<void> addProduct() async {
    final name = TextEditingController(), unit = TextEditingController(text: 'adet'), minimum = TextEditingController(text: '0');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Ürün tanımla'), content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Ürün adı')),
      TextField(controller: unit, decoration: const InputDecoration(labelText: 'Birim')),
      TextField(controller: minimum, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum stok')),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet'))]));
    if (ok == true) { try { if (name.text.trim().isEmpty) throw Exception('Ürün adı gerekli'); await db.from('products').insert({'name': name.text.trim(), 'unit': unit.text.trim().isEmpty ? 'adet' : unit.text.trim(), 'minimum_quantity': double.tryParse(minimum.text) ?? 0}); refresh(); toast('Ürün eklendi.'); } catch (e) { toast('Ürün eklenemedi: ' + e.toString(), error: true); } }
    name.dispose(); unit.dispose(); minimum.dispose();
  }

  Widget ordersPage() => FutureBuilder<List<dynamic>>(key: ValueKey('orders$revision'), future: db.from('orders').select('id,order_number,status,note,created_at,branch_id,branches(name),order_lines(id,product_id,requested_quantity,dispatched_quantity,products(name,unit))').order('created_at', ascending: false).limit(100), builder: (context, snap) {
    if (snap.hasError) return errorWidget(snap.error.toString());
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final rows = (snap.data! as List).cast<Map<String,dynamic>>();
    return ListView(padding: const EdgeInsets.all(22), children: [
      Row(children: [const Expanded(child: Text('Şube siparişleri', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w900))), if (profile?['role'] == 'sube') FilledButton.icon(onPressed: createOrder, icon: const Icon(Icons.add), label: const Text('Sipariş oluştur'))]),
      const SizedBox(height: 14), if (rows.isEmpty) note('Sipariş yok', 'Şube siparişleri burada anlık olarak görünür.'),
      ...rows.map((o) { final branch = (o['branches'] as Map<String,dynamic>?)?['name'] ?? 'Şube'; final lines = (o['order_lines'] as List? ?? []).cast<Map<String,dynamic>>(); final status = o['status'].toString(); final products = lines.map((l) => ((l['products'] as Map<String,dynamic>?)?['name'] ?? 'Ürün').toString() + ': ' + l['requested_quantity'].toString()).join(' · '); return Card(color: Colors.white, elevation: 0, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(branch.toString() + ' · SV-' + o['order_number'].toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: _navy)),
        const SizedBox(height: 6), Text(products, style: const TextStyle(color: _muted, fontSize: 12)), const SizedBox(height: 8),
        Row(children: [Expanded(child: Text(status.replaceAll('_',' '), style: const TextStyle(fontWeight: FontWeight.w800))), if (depot && (status == 'bekliyor' || status == 'hazirlaniyor')) TextButton(onPressed: () => dispatchOrder(o, lines), child: const Text('SKT seç ve sevk et')), if (profile?['role'] == 'sube' && status == 'sevk_edildi') TextButton(onPressed: () => acceptDispatch(o['id'].toString()), child: const Text('Teslim aldım'))]),
      ]))); }),
    ]);
  });


  Future<void> createOrder() async {
    final branchName = profile?['branch_name']?.toString();
    if (branchName == null || branchName.isEmpty) { toast('Hesabına şube atanmamış. Yönetici profilini güncellemeli.', error: true); return; }
    try {
      final branch = await db.from('branches').select('id').eq('name', branchName).maybeSingle();
      if (branch == null) throw Exception('Şube kaydı bulunamadı.');
      final products = (await db.from('products').select('id,name,unit').eq('active', true).order('name')).cast<Map<String,dynamic>>();
      if (products.isEmpty) throw Exception('Sipariş verilecek ürün bulunamadı.');
      String productId = products.first['id'].toString();
      final quantity = TextEditingController(text: '1');
      final noteText = TextEditingController();
      final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, modal) => AlertDialog(
        title: const Text('Yeni şube siparişi'),
        content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: productId, isExpanded: true, decoration: const InputDecoration(labelText: 'Ürün'), items: products.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'].toString() + ' (' + p['unit'].toString() + ')'))).toList(), onChanged: (v) { if (v != null) modal(() => productId = v); }),
          TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Miktar')),
          TextField(controller: noteText, decoration: const InputDecoration(labelText: 'Not (isteğe bağlı)')),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Siparişi gönder'))],
      )));
      if (ok == true) {
        final amount = double.tryParse(quantity.text.replaceAll(',', '.')) ?? 0;
        if (amount <= 0) throw Exception('Miktar sıfırdan büyük olmalı.');
        await db.rpc('create_branch_order', params: {'p_branch_id': branch['id'], 'p_lines': [{'product_id': productId, 'quantity': amount}], 'p_note': noteText.text});
        refresh(); toast('Sipariş depoya iletildi.');
      }
      quantity.dispose(); noteText.dispose();
    } catch (e) { toast('Sipariş oluşturulamadı: ' + e.toString(), error: true); }
  }

  Future<void> dispatchOrder(Map<String,dynamic> order, List<Map<String,dynamic>> lines) async {
    try {
      final allocations = <Map<String,dynamic>>[], preview = <String>[];
      for (final line in lines) {
        var remaining = (line['requested_quantity'] as num).toDouble();
        final product = ((line['products'] as Map<String,dynamic>?)?['name'] ?? 'Ürün').toString();
        final batches = (await db.from('stock_batches').select('id,expiry_date,quantity').eq('product_id', line['product_id']).eq('location_type','depo').gt('quantity',0).order('expiry_date')).cast<Map<String,dynamic>>();
        for (final b in batches) { if (remaining <= 0) break; final available = (b['quantity'] as num).toDouble(); final take = available < remaining ? available : remaining; allocations.add({'order_line_id':line['id'],'stock_batch_id':b['id'],'quantity':take}); preview.add(product + ' — ' + take.toString() + ' · SKT ' + b['expiry_date'].toString()); remaining -= take; }
        if (remaining > 0.0001) throw Exception(product + ' için stok yetersiz. Eksik: ' + remaining.toString());
      }
      if (!mounted) return;
      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Sevkiyatı onayla'), content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Önce SKT tarihi en yakın stoklar önerildi. Onayla veya iptal et.'), const SizedBox(height: 12), ...preview.map((p) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(p, style: const TextStyle(fontSize: 12))))])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Onayla'))]));
      if (ok != true) return;
      await db.rpc('dispatch_order', params: {'p_order_id':order['id'],'p_allocations':allocations,'p_note':'FEFO dağılımı depo kullanıcısı tarafından onaylandı'});
      refresh(); toast('Sevkiyat kaydedildi. Şube teslim aldığında şube stoğu güncellenecek.');
    } catch (e) { toast('Sevkiyat yapılamadı: ' + e.toString(), error: true); }
  }
  Future<void> acceptDispatch(String orderId) async {
    try { final d = await db.from('dispatches').select('id').eq('order_id', orderId).isFilter('received_at', null).maybeSingle(); if (d == null) throw Exception('Bekleyen sevkiyat bulunamadı'); await db.rpc('accept_dispatch', params: {'p_dispatch_id':d['id'],'p_note':'Şube teslim aldı'}); refresh(); toast('Teslim alındı, şube stoğu güncellendi.'); }
    catch (e) { toast('Teslim alınamadı: ' + e.toString(), error: true); }
  }

  Widget purchasePage() => FutureBuilder<List<dynamic>>(key: ValueKey('purchase$revision'), future: Future.wait([
    db.from('products').select('id,name,unit,minimum_quantity').eq('active', true),
    db.from('stock_batches').select('product_id,quantity').eq('location_type','depo').gt('quantity',0),
  ]), builder: (context, snap) {
    if (snap.hasError) return errorWidget(snap.error.toString());
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final products = (snap.data![0] as List).cast<Map<String,dynamic>>(), batches = (snap.data![1] as List).cast<Map<String,dynamic>>();
    return ListView(padding: const EdgeInsets.all(22), children: [
      const Text('Satın alma uyarıları', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12), ...products.map((p) { final total = batches.where((b) => b['product_id'] == p['id']).fold<double>(0, (s,b) => s + (b['quantity'] as num).toDouble()); final min = (p['minimum_quantity'] as num).toDouble(); if (total >= min) return const SizedBox.shrink(); return Card(color: Colors.white, elevation: 0, child: ListTile(leading: const Icon(Icons.shopping_cart_outlined, color: Colors.red), title: Text(p['name'].toString()), subtitle: Text('Mevcut: ' + total.toString() + ' ' + p['unit'].toString() + ' · Minimum: ' + min.toString()), trailing: Text('Al: ' + (min-total).toString(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800)))); }),
      if (depot) Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: addProduct, icon: const Icon(Icons.add), label: const Text('Ürün tanımla'))),
    ]);
  });

  Widget metric(String label, String value, IconData icon) => Container(width: 210, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7ECF3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _mint, size: 26), const SizedBox(height: 12), Text(value, style: const TextStyle(color: _navy, fontSize: 26, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: _muted, fontSize: 11))]));
  Widget note(String title, String body) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7ECF3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(body, style: const TextStyle(color: _muted, fontSize: 12, height: 1.5))]));
  Widget errorWidget(String e) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 40, color: Colors.red), const SizedBox(height: 10), const Text('Veri alınamadı'), const SizedBox(height: 8), Text(e, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _muted)), FilledButton(onPressed: refresh, child: const Text('Tekrar dene'))])));
}
