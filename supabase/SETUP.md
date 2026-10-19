# Supabase kurulum rehberi

Bu belge canlı sistemi ilk kez kuracak depo/yönetici içindir.

## 1. Proje ve şema
1. Supabase'te yeni proje oluştur.
2. SQL Editor'da `migrations/0001_initial_schema.sql` dosyasının tamamını çalıştır.
3. Authentication > Providers > Email ayarlarında e-posta/şifre girişini yapılandır.
4. Database > Publications > `supabase_realtime` içinde `orders`, `order_lines`, `stock_batches` ve `products` tablolarını etkinleştir.

## 2. Uygulama bağlantısı
Flutter uygulamasını şu derleme değişkenleriyle başlat:

```sh
flutter run --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Yayınlanabilir/anon anahtarı uygulama içinde kullanılabilir; **service_role anahtarını asla uygulamaya veya GitHub'a koyma**. GitHub deposunda Settings > Secrets and variables > Actions altında `SUPABASE_URL` ve `SUPABASE_PUBLISHABLE_KEY` adlı repository secrets oluştur. Workflow bu iki değeri Android/Windows/iOS derlemelerine geçirir.

## 3. Şube ve ürünleri tanımla
İlk depo kullanıcısı kaydolduktan sonra Supabase SQL Editor'da gerçek şube adlarını ekle:

```sql
insert into public.branches(name) values ('GERÇEK ŞUBE ADI');
insert into public.products(name, category, unit, minimum_quantity)
values ('ÜRÜN ADI', 'Kategori', 'adet', 10);
```

Ürün ve şube örneklerini şirketin gerçek stok/şube listesine göre değiştir. Örnek ürünler otomatik yüklenmez.

## 4. İlk depo/yönetici hesabını yetkilendir
Kullanıcı uygulamada e-posta ile kayıt olduktan sonra Authentication > Users içinden kullanıcı UUID'sini bul. İlk yönetici için SQL Editor'da yalnızca kendi güvenilir hesabına uygula:

```sql
update public.profiles
set role = 'yonetici', active = true, branch_name = null
where id = 'AUTH_USER_UUID';
```

Depo çalışanı için `role='depo'`, şube kullanıcısı için `role='sube'` ve `branch_name='GERÇEK ŞUBE ADI'` kullan. Kullanıcının profiline gerçek şube adı birebir yazılmalı. Bu rol atamalarını herkese açık bir ekrandan yapma.

## 5. İşleyiş
- Şube siparişi `create_branch_order` RPC'siyle kaydedilir.
- Depo, FEFO (SKT'si en yakın) dağılımını gözden geçirip onaylar.
- `dispatch_order` tek veritabanı işlemi içinde stok satırlarını kilitler, miktarları kontrol eder, depo stoğunu düşürür ve hareket kaydı oluşturur.
- Şube teslim alınca `accept_dispatch` aynı SKT'lerle şube stoğunu artırır.
- Satın alma uyarısı, ürün minimum stok miktarı ile depodaki toplam kullanılabilir miktarı karşılaştırır.

## Yayına almadan önce
- Şirketin gerçek ürün/şube listesini yükle.
- Yetki senaryolarını iki ayrı şube hesabı ve bir depo hesabıyla test et.
- Supabase Auth e-posta doğrulaması, yedekleme ve proje erişimlerini kontrol et.
- Bu depo şeması ve UI başlangıç sürümüdür. Kurumsal kullanım öncesi SQL migration'ı test/staging projesinde dene ve yedek al.
