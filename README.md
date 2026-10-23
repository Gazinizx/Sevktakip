# SevkTakip

Flutter uygulaması: mağazanın depodan ürün ve miktar talep etmesi, depocunun talepleri inceleyip onaylaması ve onay sırasında stoktan düşüm yapılması.

## Kapsam
- Giriş/hesap ekranı olmadan Mağaza veya Depocu çalışma alanı seçimi.
- Depocu ürün ekler, başlangıç stokunu ve kritik stok seviyesini belirler.
- Mağaza ürün ve miktar seçerek talep oluşturur.
- Depocu talebi reddedebilir veya onaylayabilir.
- Onaydan önce tüm ürünlerin stoğu doğrulanır; yetersiz stokta talep onaylanmaz.
- Başarılı onayda stok miktarları bir kez düşürülür.
- Ürün ve talep verileri cihazda saklanır.

## Yerel sürüm sınırı
Bu sürüm internet sunucusu veya ortak veritabanı kullanmaz. Veriler yalnızca uygulamanın kurulu olduğu cihazda saklanır; farklı mağaza ve depo telefonları arasında senkronizasyon yapmaz. Çok cihazlı kullanım için daha sonra güvenli bir ortak backend gerekir.

## Derleme
```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

GitHub Actions, Android APK ve imzasız iOS uygulama çıktısını ayrı artifact olarak üretir. iOS'u TestFlight/App Store'a göndermek için Apple imzalama ve dağıtım adımları ayrıca gerekir.
