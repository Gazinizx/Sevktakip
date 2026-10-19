# SevkTakip

**Depo ve şube siparişleri için SKT odaklı sevkiyat yönetimi.**

Flutter ile Android, iOS ve Windows için ortak kod tabanı hedeflenir. Türkçe ve responsive arayüz, depo operasyonları için tasarlanmıştır.

## İlk kurulum
- Flutter stable SDK kurun.
- Platform dosyalarını oluşturun: `flutter create . --platforms=android,ios,windows`
- `flutter pub get`
- `flutter run`

GitHub Actions, Android APK ve Windows derlemesini üretip artifact olarak yükleyecek şekilde yapılandırılmıştır; iOS için imzasız uygulama çıktısı hazırlanır. iOS'un TestFlight/App Store dağıtımı için Apple imzalama ve dağıtım adımları ayrıca yapılandırılmalıdır.

Supabase ayarları girilmediğinde uygulama demo verileriyle açılır. Canlı sistem için `supabase/migrations/0001_initial_schema.sql` dosyasını Supabase SQL Editor'da uygulayın; ardından RLS politikaları ve atomik stok/sevkiyat RPC'si tamamlanmalıdır.

## Derleme
- Android: `flutter build apk --release`
- Windows: `flutter build windows --release`
- iOS: macOS/Xcode üzerinde `flutter build ipa --release`

Supabase anahtarlarını GitHub'a koymayın. Örnek ürünler demo verileridir; gerçek Doyuyo stok listesi değildir. Bu ilk sürüm arayüz prototipi ve veri modeli başlangıcıdır; gerçek kullanıcı girişi, canlı senkronizasyon, stok transaction'ları ve üretim testleri tamamlanmadan canlı operasyonda kullanılmamalıdır.
