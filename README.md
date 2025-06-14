# Listemio

Flutter ile geliştirilen, modern ve sade tasarıma sahip çoklu alışveriş listesi uygulaması.

## 🚀 Özellikler
- **Material 3 (M3) teması** ve modern, sade, erişilebilir arayüz
- **Çoklu alışveriş listesi**: Her liste için başlık, oluşturulma tarihi, tamamlanma durumu
- **Açık ve tamamlanmış listeler** için sekmeli görünüm
- **Responsive** (mobil, tablet, web) ve erişilebilir tasarım
- **Yeni liste ekleme** (FAB ile hızlı erişim)
- **Liste detayında ürünler**: autocomplete ile öneri, ürün ekleme, checkbox ile tamamlama
- **Dashboard ekranı**: En çok alınan ürünler (bar chart), alışveriş günleri (timeline)
- **Paylaşım**: Listeyi metin veya .shopx dosyası olarak paylaşma
- **.shopx dosyasına tıklayarak içe aktarma**: Dosya yöneticisinden .shopx dosyasına tıklayın, Listemio ile açın, liste otomatik eklenir
- **Varsayılan uygulama**: .shopx dosyaları için Listemio'yu varsayılan uygulama olarak seçebilirsiniz
- **Yapay zeka ile ürün adı normalizasyonu** (isteğe bağlı, LLM API ile)
- **Local veritabanı**: Hive ile hızlı ve güvenli veri saklama
- **Tam Türkçe ve erişilebilirlik odaklı**

## 📱 Kullanım
- Uygulamayı açın, yeni alışveriş listeleri oluşturun.
- Her listeye ürün ekleyin, öneri sisteminden faydalanın.
- Listeleri tamamlayın veya geri alın.
- Dashboard ekranından istatistiklerinizi görüntüleyin.
- Listeyi paylaşmak için detay ekranında paylaş butonunu kullanın.
- **.shopx dosyasını içe aktarmak için:**
  - Dosya yöneticisinden .shopx dosyasına tıklayın.
  - "Listemio ile aç" seçeneğini kullanın.
  - Liste otomatik olarak uygulamaya eklenir ve ana ekranda görünür.

## 🛠️ Kullanılan Paketler
- [hive](https://pub.dev/packages/hive), [hive_flutter](https://pub.dev/packages/hive_flutter)
- [fl_chart](https://pub.dev/packages/fl_chart)
- [share_plus](https://pub.dev/packages/share_plus)
- [flutter_typeahead](https://pub.dev/packages/flutter_typeahead)
- [http](https://pub.dev/packages/http)
- [intl](https://pub.dev/packages/intl)
- [permission_handler](https://pub.dev/packages/permission_handler)
- [file_picker](https://pub.dev/packages/file_picker)

## ⚡ Kurulum
1. [Flutter](https://flutter.dev/) kurulu olmalı.
2. Gerekli paketleri yükleyin:
   ```sh
   flutter pub get
   ```
3. Uygulamayı başlatın:
   ```sh
   flutter run
   ```
4. **.shopx dosyası ile açmak için:**
   - Cihazınızda bir .shopx dosyasına tıklayın, Listemio'yu seçin.
   - Liste otomatik olarak uygulamaya eklenir.

## 💡 Geliştirici Notları
- Android 13+ için intent filter ve dosya erişim izinleri günceldir.
- .shopx dosyası JSON formatındadır, dışa aktarım ve içe aktarımda veri kaybı olmaz.
- Uygulama tamamen responsive ve erişilebilirlik standartlarına uygundur.
- Modern Material 3 teması ve sade arayüz ile kullanıcı dostudur.

## 🤝 Katkı
Katkıda bulunmak için pull request gönderebilir veya issue açabilirsiniz.

---

**Listemio** ile alışveriş listelerinizi kolayca yönetin, paylaşın ve istatistiklerinizi takip edin!
