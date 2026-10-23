# SevkTakip

Flutter uygulaması: mağazanın depodan ürün ve miktar talep etmesi, depocunun talepleri inceleyip onaylaması ve onay sırasında stoktan düşüm yapılması.

## Cihazlar arası ortak veri

- Android ve iOS aynı Supabase projesini ve aynı bulut tablolarını kullanır.
- Uygulamada hesap açma veya giriş ekranı yoktur.
- Açılışta **Mağaza** veya **Depo** rolü seçilir.
- Ürünler, stoklar ve talepler Supabase'den yüklenir; diğer cihazda **yenile** düğmesine basarak son veriyi çekebilirsin.
- Depo rolü talep onaylama/reddetme, ürün ekleme ve stok artırma işlemlerini yapar.
- Mağaza rolü ürünleri görüntüler ve depoya talepler gönderir.
- Talep onayı sunucu tarafındaki `handle_order` fonksiyonuyla yürütülür; stok yetersizse onay reddedilir.

## Önemli test/güvenlik notu

Bu test sürümünde anonim erişim açıktır ve uygulama içinde kimlik doğrulama yoktur. Bu nedenle internet erişimi olan kişiler verileri okuyabilir veya izin verilen tablolarda değişiklik yapabilir. Gerçek kullanım öncesinde mağaza/depo yetkilendirmesi eklenmelidir. Uygulamaya yalnızca publishable API anahtarı konur; secret/service-role anahtarı konmamalıdır.

## Derleme

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

GitHub Actions Android APK ve imzasız iOS uygulama çıktısı üretmek için yapılandırılabilir. TestFlight/App Store için ayrıca Apple imzalama gerekir.
