import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const navy=Color(0xFF12233F), deep=Color(0xFF0B172B), mint=Color(0xFF43D6B0), canvas=Color(0xFFF5F7FB), muted=Color(0xFF7B879B);
Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); runApp(const SevkTakipApp()); }

class SevkTakipApp extends StatelessWidget {
  const SevkTakipApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(title:'Sevktakip',debugShowCheckedModeBanner:false,
    theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:canvas,colorScheme:ColorScheme.fromSeed(seedColor:navy,primary:navy,secondary:mint),inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder())),
    home:const LocalHome());
}
class LocalHome extends StatefulWidget { const LocalHome({super.key}); @override State<LocalHome> createState()=>_LocalHomeState(); }
class _LocalHomeState extends State<LocalHome> {
  static const pk='sevktakip_products_v1', ok='sevktakip_orders_v1';
  List<Map<String,dynamic>> products=[], orders=[];
  String? role; bool loading=true; int tab=0; final search=TextEditingController();
  bool get depot=>role=='depo';
  @override void initState(){super.initState();_load();}
  @override void dispose(){search.dispose();super.dispose();}
  Future<void> _load() async {
    final prefs=await SharedPreferences.getInstance();
    try {
      final p=prefs.getString(pk),o=prefs.getString(ok);
      if(p!=null) products=(jsonDecode(p) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
      if(o!=null) orders=(jsonDecode(o) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
    } catch (_) {products=[];orders=[];}
    if(mounted)setState(()=>loading=false);
  }
  Future<void> _save() async {final p=await SharedPreferences.getInstance();await p.setString(pk,jsonEncode(products));await p.setString(ok,jsonEncode(orders));}
  void _toast(String s,{bool error=false}){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:error?Colors.red.shade700:navy));}

  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(role==null)return _rolePicker();
    final pages=depot?['Genel Bakış','Depo Stoku','Sipariş Talepleri','Hareketler']:['Genel Bakış','Ürünler','Siparişlerim'];
    if(tab>=pages.length)tab=0;
    return Scaffold(
      appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(pages[tab],style:const TextStyle(color:navy,fontSize:18,fontWeight:FontWeight.w900)),
        Text(depot?'Depocu çalışma alanı · Yerel kayıt':'Mağaza çalışma alanı · Yerel kayıt',style:const TextStyle(color:muted,fontSize:11)),
      ]),actions:[
        PopupMenuButton<String>(tooltip:'Çalışma alanı',onSelected:(v){setState((){role=v;tab=0;});},itemBuilder:(_)=>const[
          PopupMenuItem(value:'magaza',child:Text('Mağaza ekranı')),PopupMenuItem(value:'depo',child:Text('Depocu ekranı'))],icon:const Icon(Icons.swap_horiz)),
        const SizedBox(width:8)]),
      body:IndexedStack(index:tab,children:[_dashboard(),depot?_stockPage():_storeProducts(),depot?_requestsPage():_storeOrders(),if(depot)_movementsPage()]),
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:depot?const[
        NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'Özet'),NavigationDestination(icon:Icon(Icons.inventory_2_outlined),label:'Depo'),
        NavigationDestination(icon:Icon(Icons.assignment_outlined),label:'Talepler'),NavigationDestination(icon:Icon(Icons.history),label:'Hareketler')]:const[
        NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'Özet'),NavigationDestination(icon:Icon(Icons.inventory_2_outlined),label:'Ürünler'),NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'Siparişler')]),
      floatingActionButton:depot&&tab==1?FloatingActionButton.extended(onPressed:_addProduct,icon:const Icon(Icons.add),label:const Text('Ürün ekle')):
        (!depot&&tab==1&&products.isNotEmpty?FloatingActionButton.extended(onPressed:_createOrder,icon:const Icon(Icons.add_shopping_cart),label:const Text('Sipariş oluştur')):null));
  }
  Widget _rolePicker()=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Container(width:84,height:84,decoration:BoxDecoration(color:deep,borderRadius:BorderRadius.circular(25)),child:const Icon(Icons.warehouse_rounded,color:mint,size:44)),
    const SizedBox(height:22),const Text('SEVKTAKİP',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900,color:navy,letterSpacing:1.4)),
    const SizedBox(height:8),const Text('Depo ve mağaza malzeme takibi',style:TextStyle(color:muted)),const SizedBox(height:28),
    _roleCard('Mağaza','Depodan ürün iste ve taleplerini takip et.',Icons.storefront_rounded,()=>setState(()=>role='magaza')),
    const SizedBox(height:14),_roleCard('Depocu','Stokları yönet, talepleri onayla ve stok düşümünü yap.',Icons.inventory_2_rounded,()=>setState(()=>role='depo')),
    const SizedBox(height:22),const Text('Yerel sürüm: kayıtlar yalnızca bu cihazda saklanır. Başka telefonlarla paylaşılmaz.',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:12,height:1.5)),
  ]))))));
  Widget _roleCard(String title,String subtitle,IconData icon,VoidCallback onTap)=>Card(color:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:const BorderSide(color:Color(0xFFE5EAF1))),child:InkWell(borderRadius:BorderRadius.circular(18),onTap:onTap,child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
    Container(width:52,height:52,decoration:BoxDecoration(color:const Color(0xFFE3F8F1),borderRadius:BorderRadius.circular(15)),child:Icon(icon,color:const Color(0xFF168D71),size:27)),const SizedBox(width:15),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:navy,fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:muted,fontSize:12,height:1.4))])),
    const Icon(Icons.arrow_forward_ios,size:16,color:muted)]))));
  Widget _dashboard(){
    final pending=orders.where((o)=>o['status']=='Bekliyor').length, approved=orders.where((o)=>o['status']=='Onaylandı').length;
    final low=products.where((p)=>(p['stock'] as num)<=(p['minimum'] as num)).length;
    return ListView(padding:const EdgeInsets.all(18),children:[
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[navy,Color(0xFF234B68)]),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('DEPO OPERASYONLARI',style:TextStyle(color:mint,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.5)),const SizedBox(height:12),
        Text(depot?'Stok ve talepler kontrolünde.':'İhtiyacın olan malzemeyi iste.',style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),
        Text(depot?'Mağazadan gelen talepleri incele ve onayla.':'Ürünleri seç, miktarları gir ve talebini gönder.',style:const TextStyle(color:Colors.white70,fontSize:13))])),
      const SizedBox(height:16),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.4,children:[
        _metric('Ürün çeşidi','${products.length}',Icons.inventory_2,const Color(0xFFE6EDFF),const Color(0xFF4D69C8)),
        _metric(depot?'Bekleyen talep':'Siparişlerim',depot?'${pending}':'${orders.length}',Icons.receipt_long,const Color(0xFFFFEFD8),const Color(0xFFBD7A19)),
        _metric('Kritik stok','${low}',Icons.warning_amber_rounded,const Color(0xFFFFE4E4),const Color(0xFFD44B55)),
        _metric('Onaylanan','${approved}',Icons.check_circle_outline,const Color(0xFFDDF7EF),const Color(0xFF168D71)]),
      const SizedBox(height:20),_heading(depot?'Son talepler':'Son siparişler'),
      if(orders.isEmpty)_empty('Henüz sipariş yok',depot?'Mağazadan talep geldiğinde burada görünür.':'Ürünler bölümünden yeni bir talep oluştur.'),
      ...orders.reversed.take(5).map(_orderCard),
      if(depot)...[const SizedBox(height:16),_heading('Kritik stoklar'),...products.where((p)=>(p['stock'] as num)<=(p['minimum'] as num)).map(_productTile)]]);
  }
  Widget _stockPage()=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(16,14,16,8),child:TextField(controller:search,onChanged:(_)=>setState(()=>{}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Ürün ara',isDense:true))),
    Expanded(child:products.isEmpty?_empty('Henüz ürün eklenmedi','“Ürün ekle” düğmesiyle depo ürünlerini tanımla.'):ListView(padding:const EdgeInsets.fromLTRB(16,4,16,90),children:products.where(_matches).map((p)=>_productTile(p,editable:true)).toList()))]);
  Widget _storeProducts()=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(16,14,16,8),child:TextField(controller:search,onChanged:(_)=>setState(()=>{}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Ürün ara',isDense:true))),
    Expanded(child:products.isEmpty?_empty('Ürün listesi boş','Ürünler bu cihazda depocu tarafından eklendiğinde görünür. Yerel sürümde telefonlar arası paylaşım yoktur.'):ListView(padding:const EdgeInsets.fromLTRB(16,4,16,90),children:products.where(_matches).map(_productTile).toList()))]);
  bool _matches(Map<String,dynamic> p)=>p['name'].toString().toLowerCase().contains(search.text.toLowerCase())||p['code'].toString().toLowerCase().contains(search.text.toLowerCase());
  Widget _requestsPage(){
    final waiting=orders.where((o)=>o['status']=='Bekliyor').toList().reversed.toList(),done=orders.where((o)=>o['status']!='Bekliyor').toList().reversed.toList();
    return ListView(padding:const EdgeInsets.all(16),children:[_heading('Onay bekleyen talepler'),const SizedBox(height:8),if(waiting.isEmpty)_empty('Bekleyen talep yok','Mağazadan yeni talep geldiğinde burada görünür.'),...waiting.map((o)=>_orderCard(o,actions:true)),if(done.isNotEmpty)...[const SizedBox(height:18),_heading('İşlem geçmişi'),...done.map(_orderCard)]]);
  }
  Widget _storeOrders()=>ListView(padding:const EdgeInsets.all(16),children:[FilledButton.icon(onPressed:products.isEmpty?null:_createOrder,icon:const Icon(Icons.add),label:const Text('Yeni ürün talebi oluştur')),const SizedBox(height:14),if(orders.isEmpty)_empty('Henüz siparişin yok','Ürün talebi oluşturduğunda durumunu burada izleyebilirsin.'),...orders.reversed.map(_orderCard)]);
  Widget _movementsPage(){
    final done=orders.where((o)=>o['status']=='Onaylandı').toList().reversed.toList();
    return ListView(padding:const EdgeInsets.all(16),children:[_heading('Stok hareketleri'),if(done.isEmpty)_empty('Henüz stok hareketi yok','Onaylanan siparişler burada listelenir.'),...done.map((o)=>Card(color:Colors.white,elevation:0,child:ListTile(leading:const CircleAvatar(backgroundColor:Color(0xFFDDF7EF),child:Icon(Icons.outbox,color:Color(0xFF168D71))),title:Text('Talep #${o['id']} onaylandı'),subtitle:Text('${(o['items'] as List).length} ürün · stoktan düşüldü'),trailing:Text(_date(o['updatedAt']?.toString()),style:const TextStyle(fontSize:10,color:muted)))))]);
  }
  Widget _productTile(Map<String,dynamic> p,{bool editable=false}){
    final stock=(p['stock'] as num).toDouble(),min=(p['minimum'] as num).toDouble(),low=stock<=min;
    return Card(color:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15),side:const BorderSide(color:Color(0xFFE9EDF4))),child:ListTile(
      leading:Container(width:44,height:44,decoration:BoxDecoration(color:const Color(0xFFEAF2F6),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.inventory_2_outlined,color:navy)),
      title:Text(p['name'].toString(),style:const TextStyle(fontWeight:FontWeight.w800,color:navy)),
      subtitle:Text('${p['code']} · Minimum: ${_qty(min)} ${p['unit']}',style:const TextStyle(color:muted,fontSize:11)),
      trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text('${_qty(stock)} ${p['unit']}',style:const TextStyle(fontWeight:FontWeight.w900,color:navy)),Text(low?'Stok az':'Stokta',style:TextStyle(fontSize:10,color:low?Colors.red:Colors.green))]),
      onTap:editable?()=>_stockAdjustment(p):null));
  }
  Widget _orderCard(Map<String,dynamic> o,{bool actions=false}){
    final status=o['status'].toString(),items=(o['items'] as List).map((x)=>Map<String,dynamic>.from(x as Map)).toList();
    final color=status=='Onaylandı'?Colors.green:status=='Reddedildi'?Colors.red:navy;
    return Card(color:Colors.white,elevation:0,margin:const EdgeInsets.only(bottom:10),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:const BorderSide(color:Color(0xFFE9EDF4))),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text('Talep #${o['id']}',style:const TextStyle(fontWeight:FontWeight.w900,color:navy,fontSize:15))),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:color.withValues(alpha:.10),borderRadius:BorderRadius.circular(20)),child:Text(status,style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.w800)))]),
      const SizedBox(height:8),...items.map((i)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[Expanded(child:Text(i['name'].toString(),style:const TextStyle(fontSize:13))),Text('${_qty((i['quantity'] as num).toDouble())} ${i['unit']}',style:const TextStyle(fontWeight:FontWeight.w800))]))),
      if((o['note']??'').toString().isNotEmpty)Text('Not: ${o['note']}',style:const TextStyle(color:muted,fontSize:12)),
      const SizedBox(height:8),Text('Oluşturulma: ${_date(o['createdAt']?.toString())}',style:const TextStyle(color:muted,fontSize:10)),
      if(actions&&status=='Bekliyor')...[
        const SizedBox(height:12),Row(children:[
          Expanded(child:OutlinedButton.icon(onPressed:()=>_rejectOrder(o),icon:const Icon(Icons.close),label:const Text('Reddet'),style:OutlinedButton.styleFrom(foregroundColor:Colors.red))),
          const SizedBox(width:10),Expanded(child:FilledButton.icon(onPressed:()=>_approveOrder(o),icon:const Icon(Icons.check),label:const Text('Onayla')))])]])));
  }
  Widget _metric(String label,String value,IconData icon,Color bg,Color fg)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17),border:Border.all(color:const Color(0xFFE9EDF4))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:38,height:38,decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(11)),child:Icon(icon,color:fg)),const Spacer(),Text(value,style:const TextStyle(color:navy,fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(label,style:const TextStyle(color:muted,fontSize:11))]));
  Widget _heading(String s)=>Text(s,style:const TextStyle(color:navy,fontSize:17,fontWeight:FontWeight.w900));
  Widget _empty(String title,String detail)=>Container(margin:const EdgeInsets.symmetric(vertical:8),padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17),border:Border.all(color:const Color(0xFFE9EDF4))),child:Column(children:[const Icon(Icons.inventory_2_outlined,size:34,color:muted),const SizedBox(height:10),Text(title,style:const TextStyle(color:navy,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(detail,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:12,height:1.5))]));

  Future<void> _addProduct() async {
    final name=TextEditingController(),code=TextEditingController(),unit=TextEditingController(text:'adet'),stock=TextEditingController(text:'0'),minimum=TextEditingController(text:'0');final key=GlobalKey<FormState>();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Yeni ürün ekle'),content:SizedBox(width:420,child:Form(key:key,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextFormField(controller:name,autofocus:true,decoration:const InputDecoration(labelText:'Ürün adı *'),validator:(v)=>(v==null||v.trim().isEmpty)?'Ürün adı gerekli':null),
      const SizedBox(height:10),TextFormField(controller:code,decoration:const InputDecoration(labelText:'Ürün kodu (isteğe bağlı)')),
      const SizedBox(height:10),TextFormField(controller:unit,decoration:const InputDecoration(labelText:'Birim (adet, kg, koli...)'),validator:(v)=>(v==null||v.trim().isEmpty)?'Birim gerekli':null),
      const SizedBox(height:10),TextFormField(controller:stock,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Başlangıç stoğu'),validator:_validateNumber),
      const SizedBox(height:10),TextFormField(controller:minimum,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Minimum stok uyarısı'),validator:_validateNumber)]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('İptal')),FilledButton(onPressed:(){if(key.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('Kaydet'))]));
    if(ok==true){
      if(products.any((p)=>p['name'].toString().toLowerCase()==name.text.trim().toLowerCase())){_toast('Bu ürün zaten kayıtlı.',error:true);}
      else{products.add({'id':DateTime.now().microsecondsSinceEpoch,'name':name.text.trim(),'code':code.text.trim().isEmpty?'UR-${products.length+1}':code.text.trim(),'unit':unit.text.trim(),'stock':_number(stock.text),'minimum':_number(minimum.text)});await _save();if(mounted)setState(()=>{});_toast('Ürün kaydedildi.');}
    }
    name.dispose();code.dispose();unit.dispose();stock.dispose();minimum.dispose();
  }
  Future<void> _stockAdjustment(Map<String,dynamic> p) async {
    final qty=TextEditingController();final key=GlobalKey<FormState>();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text('${p['name']} · Stok girişi'),content:Form(key:key,child:TextFormField(controller:qty,autofocus:true,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'Eklenecek miktar (${p['unit']})'),validator:_validatePositive)),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('İptal')),FilledButton(onPressed:(){if(key.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('Stoğa ekle'))]));
    if(ok==true){p['stock']=(p['stock'] as num).toDouble()+_number(qty.text);await _save();if(mounted)setState(()=>{});_toast('Stok güncellendi.');}qty.dispose();
  }
  Future<void> _createOrder() async {
    if(products.isEmpty)return;
    final quantities=<int,TextEditingController>{for(final p in products)p['id'] as int:TextEditingController(text:'0')};final note=TextEditingController();final key=GlobalKey<FormState>();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Mağaza ürün talebi'),content:SizedBox(width:440,child:Form(key:key,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Align(alignment:Alignment.centerLeft,child:Text('İstenen miktarları gir. 0 olan ürünler eklenmez.',style:TextStyle(color:muted,fontSize:12))),const SizedBox(height:12),
      ...products.map((p)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p['name'].toString(),style:const TextStyle(fontWeight:FontWeight.w700)),Text('Kayıtlı stok: ${_qty((p['stock'] as num).toDouble())} ${p['unit']}',style:const TextStyle(color:muted,fontSize:11))])),
        SizedBox(width:94,child:TextFormField(controller:quantities[p['id'] as int],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Miktar',isDense:true),validator:(v)=>_number(v??'0')<0?'Geçersiz':null))]))),
      TextField(controller:note,decoration:const InputDecoration(labelText:'Not (isteğe bağlı)'))]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('İptal')),FilledButton(onPressed:(){if(key.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('Talep gönder'))]));
    if(ok==true){
      final items=<Map<String,dynamic>>[];for(final p in products){final q=_number(quantities[p['id'] as int]!.text);if(q>0)items.add({'productId':p['id'],'name':p['name'],'unit':p['unit'],'quantity':q});}
      if(items.isEmpty){_toast('En az bir ürün için miktar gir.',error:true);}
      else{orders.add({'id':DateTime.now().millisecondsSinceEpoch,'status':'Bekliyor','items':items,'note':note.text.trim(),'createdAt':DateTime.now().toIso8601String()});await _save();if(mounted)setState(()=>tab=2);_toast('Talep bu cihaza kaydedildi.');}
    }
    for(final c in quantities.values){c.dispose();}note.dispose();
  }
  Future<void> _approveOrder(Map<String,dynamic> o) async {
    if(o['status']!='Bekliyor')return;
    final items=(o['items'] as List).map((x)=>Map<String,dynamic>.from(x as Map)).toList();
    for(final item in items){final matches=products.where((p)=>p['id']==item['productId']);if(matches.isEmpty||(matches.first['stock'] as num).toDouble()<(item['quantity'] as num).toDouble()){_toast('Yetersiz stok: ${item['name']}. Stok girişinden sonra tekrar dene.',error:true);return;}}
    final confirm=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Siparişi onayla?'),content:const Text('Onaylandığında istenen miktarlar stoktan düşülecek. Aynı sipariş ikinci kez düşülmez.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Vazgeç')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Onayla ve stok düş'))]));
    if(confirm!=true)return;
    for(final item in items){final p=products.firstWhere((p)=>p['id']==item['productId']);p['stock']=(p['stock'] as num).toDouble()-(item['quantity'] as num).toDouble();}
    o['status']='Onaylandı';o['updatedAt']=DateTime.now().toIso8601String();await _save();if(mounted)setState(()=>{});_toast('Sipariş onaylandı, stok güncellendi.');
  }
  Future<void> _rejectOrder(Map<String,dynamic> o) async {
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Talep reddedilsin mi?'),content:const Text('Reddedilen talepte stok değişmez.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Vazgeç')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Talebi reddet'))]));
    if(yes==true){o['status']='Reddedildi';o['updatedAt']=DateTime.now().toIso8601String();await _save();if(mounted)setState(()=>{});_toast('Talep reddedildi.');}
  }
  String? _validateNumber(String? v)=>v==null||v.trim().isEmpty||_number(v)<0?'0 veya daha büyük sayı gir':null;
  String? _validatePositive(String? v)=>v==null||v.trim().isEmpty||_number(v)<=0?'0’dan büyük sayı gir':null;
  double _number(String s)=>double.tryParse(s.trim().replaceAll(',','.'))??-1;
  String _qty(double n)=>n==n.roundToDouble()?n.toInt().toString():n.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'),'').replaceFirst(RegExp(r'\.$'),'');
  String _date(String? s){if(s==null)return '';final d=DateTime.tryParse(s);if(d==null)return s;return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';}
}
