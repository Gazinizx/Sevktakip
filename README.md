# SevkTakip

Flutter uygulaması: mağazanın depodan ürün ve miktar talep etmesi, depocunun talepleri inceleyip onaylaması ve onay sırasında stoktan düşüm yapılması.

## Ortak veritabanı
- Supabase projesi: `SevkTakip`
- Bölge: Frankfurt, Avrupa (eu-central-1)
- Android ve iOS aynı Supabase veritabanını kullanır.
- Hesap oluşturma/giriş e-posta ve şifre ile yapılır.
- Ürünler, stoklar, talepler ve stok hareketleri bulutta saklanır.
- Talep onayı sunucu tarafında tek bir işlem olarak yürütülür; stok yetersizse onay reddedilir.
- Tablolarda Row Level Security (RLS) açıktır. Uygulamada yalnızca publishable API anahtarı kullanılır; secret/service-role anahtarı uygulamaya eklenmez.

## Depocu hesabı
Yeni kayıtlar güvenlik amacıyla varsayılan olarak mağaza rolü alır. Depocu rolü, ilgili kullanıcı hesabı oluşturulduktan sonra Supabase SQL Editor üzerinden yetkili yönetici tarafından atanmalıdır. E-posta adresini doğruladıktan sonra şu SQL'deki e-posta değerini değiştirerek çalıştır:
```sql
update public.profiles
set role = 'depo'
where id = (
  select id from auth.users
  where lower(email) = lower('DEPO_HESABI_EPOSTASI')
);
```
Bu işlem yapılana kadar o kullanıcı mağaza ekranını görür; yetkisiz kullanıcıların kendilerini depocu yapmasına izin verilmez.

## Geliştirme ve derleme
```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
``

GitHub Actions Android APK ve imzasız iOS uygulama çıktısı üretir. TestFlight/App Store için ayrıca Apple imzalama gerekir.
