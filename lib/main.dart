import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ink = Color(0xFF172B4D);
const _green = Color(0xFF16856B);
const _paper = Color(0xFFF4F6FA);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SevkTakipApp());
}

class SevkTakipApp extends StatelessWidget {
  const SevkTakipApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SevkTakip',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: _paper,
          colorScheme: ColorScheme.fromSeed(seedColor: _ink),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            elevation: 0,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const WorkAreaScreen(),
      );
}

class StockItem {
  StockItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minimum,
  });

  final String id;
  final String name;
  final String unit;
  int quantity;
  final int minimum;

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'quantity': quantity,
        'minimum': minimum,
      };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        quantity: (json['quantity'] as num).toInt(),
        minimum: (json['minimum'] as num).toInt(),
      );
}

class OrderLine {
  const OrderLine({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, Object> toJson() => {
        'productId': productId,
        'quantity': quantity,
      };

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productId: json['productId'] as String,
        quantity: (json['quantity'] as num).toInt(),
      );
}

class StockOrder {
  StockOrder({
    required this.id,
    required this.createdAt,
    required this.note,
    required this.lines,
    this.status = 'Bekliyor',
  });

  final String id;
  final DateTime createdAt;
  final String note;
  final List<OrderLine> lines;
  String status;

  Map<String, Object> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'note': note,
        'status': status,
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  factory StockOrder.fromJson(Map<String, dynamic> json) => StockOrder(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        note: json['note'] as String? ?? '',
        status: json['status'] as String? ?? 'Bekliyor',
        lines: (json['lines'] as List<dynamic>)
            .map((line) => OrderLine.fromJson(
                Map<String, dynamic>.from(line as Map)))
            .toList(),
      );
}

class LocalInventory {
  static const _stockKey = 'sevktakip_clean_stock_v1';
  static const _orderKey = 'sevktakip_clean_orders_v1';

  Future<List<StockItem>> loadStock() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stockKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) =>
              StockItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StockOrder>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_orderKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) =>
              StockOrder.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<StockItem> stock, List<StockOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _stockKey, jsonEncode(stock.map((item) => item.toJson()).toList()));
    await prefs.setString(
        _orderKey, jsonEncode(orders.map((order) => order.toJson()).toList()));
  }
}

class WorkAreaScreen extends StatefulWidget {
  const WorkAreaScreen({super.key});

  @override
  State<WorkAreaScreen> createState() => _WorkAreaScreenState();
}

class _WorkAreaScreenState extends State<WorkAreaScreen> {
  final _storage = LocalInventory();
  final _searchController = TextEditingController();
  List<StockItem> _stock = [];
  List<StockOrder> _orders = [];
  String? _role;
  bool _loading = true;
  int _tab = 0;

  bool get _isDepot => _role == 'depo';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _storage.loadStock(),
      _storage.loadOrders(),
    ]);
    if (!mounted) return;
    setState(() {
      _stock = results[0] as List<StockItem>;
      _orders = results[1] as List<StockOrder>;
      _loading = false;
    });
  }

  Future<void> _persist() => _storage.save(_stock, _orders);

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : _ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: Text('SevkTakip açılıyor…')));
    }
    if (_role == null) return _roleSelection();

    final titles = _isDepot
        ? const ['Genel Bakış', 'Depo Stoku', 'Talepler', 'Hareketler']
        : const ['Genel Bakış', 'Ürünler', 'Siparişlerim'];
    if (_tab >= titles.length) _tab = 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titles[_tab],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(_isDepot ? 'Depocu alanı' : 'Mağaza alanı',
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Çalışma alanını değiştir',
            onSelected: (value) => setState(() {
              _role = value;
              _tab = 0;
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'magaza', child: Text('Mağaza ekranı')),
              PopupMenuItem(value: 'depo', child: Text('Depocu ekranı')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _dashboard(),
          _isDepot ? _stockPage() : _storeProducts(),
          _isDepot ? _requestsPage() : _storeOrders(),
          if (_isDepot) _historyPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: _isDepot
            ? const [
                NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined), label: 'Özet'),
                NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined), label: 'Stok'),
                NavigationDestination(
                    icon: Icon(Icons.assignment_outlined), label: 'Talepler'),
                NavigationDestination(
                    icon: Icon(Icons.history), label: 'Hareketler'),
              ]
            : const [
                NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined), label: 'Özet'),
                NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined), label: 'Ürünler'),
                NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    label: 'Siparişler'),
              ],
      ),
      floatingActionButton: _isDepot && _tab == 1
          ? FloatingActionButton.extended(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Ürün ekle'),
            )
          : !_isDepot && _tab == 1 && _stock.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: _createOrder,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Talep oluştur'),
                )
              : null,
    );
  }

  Widget _roleSelection() => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.warehouse_rounded, size: 72, color: _green),
                    const SizedBox(height: 18),
                    const Text('SEVKTAKİP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _ink,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    const Text('Depo ve mağaza stok yönetimi',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    _roleCard(
                      'Mağaza',
                      'Ürün ve miktar seçerek depoya talep gönder.',
                      Icons.storefront_rounded,
                      () => setState(() => _role = 'magaza'),
                    ),
                    const SizedBox(height: 14),
                    _roleCard(
                      'Depocu',
                      'Stokları yönet, talepleri kontrol et ve onayla.',
                      Icons.inventory_2_rounded,
                      () => setState(() => _role = 'depo'),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Yerel sürüm: kayıtlar yalnızca bu cihazda saklanır; diğer telefonlarla senkronize olmaz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _roleCard(
      String title, String subtitle, IconData icon, VoidCallback onTap) =>
      Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE2E7EF))),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, color: _green, size: 34),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );

  Widget _dashboard() {
    final pending = _orders.where((order) => order.status == 'Bekliyor').length;
    final approved =
        _orders.where((order) => order.status == 'Onaylandı').length;
    final low = _stock.where((item) => item.quantity <= item.minimum).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            _isDepot
                ? 'Depo taleplerini incele ve stok hareketlerini yönet.'
                : 'İhtiyacın olan ürünleri depodan kolayca talep et.',
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _metric('Ürün çeşidi', _stock.length.toString(),
                Icons.inventory_2_outlined),
            _metric(_isDepot ? 'Bekleyen talep' : 'Siparişlerim',
                _isDepot ? pending.toString() : _orders.length.toString(),
                Icons.receipt_long_outlined),
            _metric('Kritik stok', low.toString(), Icons.warning_amber_rounded),
            _metric('Onaylanan', approved.toString(), Icons.check_circle_outline),
          ],
        ),
        const SizedBox(height: 20),
        Text(_isDepot ? 'Son talepler' : 'Son siparişler',
            style: const TextStyle(
                color: _ink, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (_orders.isEmpty) _empty('Henüz talep yok'),
        ..._orders.reversed.take(4).map(_orderCard),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon) => Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: _green),
              Text(value,
                  style: const TextStyle(
                      color: _ink, fontSize: 25, fontWeight: FontWeight.w900)),
              Text(label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _stockPage() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_stock.isEmpty) _empty('Henüz ürün eklenmedi'),
          ..._stock.map((item) => Card(
                color: Colors.white,
                child: ListTile(
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Minimum: ${item.minimum} ${item.unit}  ·  ${item.quantity <= item.minimum ? 'Kritik stok' : 'Stok yeterli'}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${item.quantity}',
                          style: const TextStyle(
                              color: _ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      Text(item.unit,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 11)),
                    ],
                  ),
                  onTap: () => _addStock(item),
                ),
              )),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Stok miktarını artırmak için ürüne dokun.',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
          ),
        ],
      );

  Widget _storeProducts() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _stock
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Ürün ara'),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _empty('Gösterilecek ürün bulunamadı')
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: filtered
                      .map((item) => Card(
                            color: Colors.white,
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text('Birim: ${item.unit}'),
                              trailing: const Icon(Icons.add_shopping_cart),
                              onTap: _createOrder,
                            ),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _storeOrders() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_orders.isEmpty) _empty('Henüz sipariş oluşturulmadı'),
          ..._orders.reversed.map(_orderCard),
        ],
      );

  Widget _requestsPage() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_orders.where((order) => order.status == 'Bekliyor').isEmpty)
            _empty('Bekleyen talep yok'),
          ..._orders
              .where((order) => order.status == 'Bekliyor')
              .toList()
              .reversed
              .map((order) => _orderCard(order, actions: true)),
        ],
      );

  Widget _historyPage() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_orders.where((order) => order.status != 'Bekliyor').isEmpty)
            _empty('Henüz tamamlanmış hareket yok'),
          ..._orders
              .where((order) => order.status != 'Bekliyor')
              .toList()
              .reversed
              .map(_orderCard),
        ],
      );

  Widget _orderCard(StockOrder order, {bool actions = false}) {
    final details = order.lines.map((line) {
      final product = _findProduct(line.productId);
      return '${product?.name ?? 'Silinmiş ürün'} × ${line.quantity}';
    }).join(' · ');
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Talep #${order.id.substring(0, 6)}',
                      style: const TextStyle(
                          color: _ink, fontWeight: FontWeight.w800)),
                ),
                _statusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(details),
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Not: ${order.note}',
                  style: const TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 6),
            Text(_date(order.createdAt),
                style: const TextStyle(color: Colors.black45, fontSize: 11)),
            if (actions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(order),
                      child: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _approve(order),
                      child: const Text('Onayla ve stok düş'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'Onaylandı'
        ? _green
        : status == 'Reddedildi'
            ? Colors.red.shade700
            : Colors.orange.shade800;
    return Chip(
      label: Text(status,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 38, color: Colors.black38),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
      );

  StockItem? _findProduct(String id) {
    for (final item in _stock) {
      if (item.id == id) return item;
    }
    return null;
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> _addProduct() async {
    final name = TextEditingController();
    final unit = TextEditingController(text: 'adet');
    final quantity = TextEditingController(text: '0');
    final minimum = TextEditingController(text: '5');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni ürün'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(name, 'Ürün adı'),
                _textField(unit, 'Birim (adet, koli, kg)'),
                _textField(quantity, 'Başlangıç stoku', numeric: true),
                _textField(minimum, 'Minimum stok', numeric: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Kaydet')),
        ],
      ),
    );
    if (result == true && mounted) {
      final cleanName = name.text.trim();
      if (_stock.any((item) => item.name.toLowerCase() == cleanName.toLowerCase())) {
        _message('Bu ürün zaten kayıtlı.', error: true);
      } else {
        setState(() {
          _stock.add(StockItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: cleanName,
            unit: unit.text.trim().isEmpty ? 'adet' : unit.text.trim(),
            quantity: int.parse(quantity.text.trim()),
            minimum: int.parse(minimum.text.trim()),
          ));
        });
        await _persist();
        _message('Ürün kaydedildi.');
      }
    }
    name.dispose();
    unit.dispose();
    quantity.dispose();
    minimum.dispose();
  }

  Widget _textField(TextEditingController controller, String label,
          {bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Bu alan zorunludur';
            if (numeric && (int.tryParse(text) == null || int.parse(text) < 0)) {
              return 'Sıfır veya pozitif tam sayı girin';
            }
            return null;
          },
        ),
      );

  Future<void> _addStock(StockItem item) async {
    final controller = TextEditingController(text: '1');
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.name} stoğu'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Eklenecek miktar'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              Navigator.pop(context, value);
            },
            child: const Text('Stok ekle'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || !mounted) return;
    setState(() => item.quantity += amount);
    await _persist();
    _message('Stok güncellendi.');
  }

  Future<void> _createOrder() async {
    if (_stock.isEmpty) {
      _message('Önce depocu ürün eklemeli.', error: true);
      return;
    }
    final quantities = <String, TextEditingController>{
      for (final item in _stock)
        item.id: TextEditingController(text: '0'),
    };
    final note = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Depoya talep oluştur'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._stock.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(child: Text('${item.name} (${item.unit})')),
                            SizedBox(
                              width: 82,
                              child: TextFormField(
                                controller: quantities[item.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Miktar', isDense: true),
                                validator: (value) {
                                  final amount = int.tryParse(value ?? '');
                                  if (amount == null || amount < 0) {
                                    return 'Geçersiz';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      )),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(labelText: 'Açıklama (isteğe bağlı)'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final hasLine = quantities.values.any(
                      (controller) => (int.tryParse(controller.text) ?? 0) > 0);
                  if (hasLine) Navigator.pop(context, true);
                }
              },
              child: const Text('Talebi gönder')),
        ],
      ),
    );
    if (result == true && mounted) {
      final lines = quantities.entries
          .map((entry) => OrderLine(
              productId: entry.key,
              quantity: int.parse(entry.value.text.trim())))
          .where((line) => line.quantity > 0)
          .toList();
      setState(() {
        _orders.add(StockOrder(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          note: note.text.trim(),
          lines: lines,
        ));
        _tab = 2;
      });
      await _persist();
      _message('Talep depoya eklendi.');
    }
    for (final controller in quantities.values) {
      controller.dispose();
    }
    note.dispose();
  }

  Future<void> _approve(StockOrder order) async {
    if (order.status != 'Bekliyor') return;
    for (final line in order.lines) {
      final product = _findProduct(line.productId);
      if (product == null || product.quantity < line.quantity) {
        _message(
          'Stok yetersiz: ${product?.name ?? 'ürün bulunamadı'}. Talep onaylanmadı.',
          error: true,
        );
        return;
      }
    }
    setState(() {
      for (final line in order.lines) {
        _findProduct(line.productId)!.quantity -= line.quantity;
      }
      order.status = 'Onaylandı';
    });
    await _persist();
    _message('Talep onaylandı, stok düşüldü.');
  }

  Future<void> _reject(StockOrder order) async {
    if (order.status != 'Bekliyor') return;
    setState(() => order.status = 'Reddedildi');
    await _persist();
    _message('Talep reddedildi.');
  }
}
