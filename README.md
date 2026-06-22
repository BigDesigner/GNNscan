# GNNcyber - NETscan

GNNcyber - NETscan, Flutter ve modern web teknolojileri ile geliştirilmiş, asenkron ve çok iş parçacıklı (multi-threaded) bir yerel ağ tarama (IP/Port Scan) ve keşif aracıdır.

---

## 🚀 Temel Özellikler

- **Dinamik Hedef Çözümleme:** Tekil IP, IP aralıkları (örn. `192.168.1.10-50`), CIDR Subnet tanımları (örn. `192.168.1.0/24`) ve alan adlarını otomatik olarak çözümler.
- **Hızlı Asenkron Tarama:** Çoklu soket bağlantıları (varsayılan 64 thread) ile hedef sistemlerdeki açık portları saniyeler içinde tarar.
- **ARP Tabanlı Host Keşfi:** Güvenlik duvarı (firewall) nedeniyle TCP ping isteklerine kapalı olan cihazları tespit etmek amacıyla yerel sistemin ARP önbelleğini (`arp -a`) dinamik olarak stimüle eder ve okur.
- **MAC Adresi & Üretici (Vendor) Tespiti:** Aktif cihazların donanım (MAC) adreslerini ayıklar ve dinamik OUI sorgulaması ile üretici bilgilerini (örn. Synology, Apple, HP, Cisco) ekrana yansıtır.
- **Web Arayüzü Yönlendirmesi:** Açık portlarda bir web yayını (80, 443, 5000, 8080 vb.) tespit edildiğinde port numarasının yanında beliren ikon yardımıyla ilgili cihazın web arayüzünü (örn. NAS cihazı veya yazıcı) kullanıcının varsayılan tarayıcısında otomatik olarak açar.
- **Kalıcı Tarama Geçmişi:** Tarama ayarlarını ve geçmiş raporları yerel diskte JSON tabanlı bir veritabanında saklar.
- **Brutalist Terminal Log Akışı:** Arka planda gerçekleşen tarama adımlarını ve soket hareketlerini canlı terminal log penceresinde gösterir.

---

## 🛠️ Teknoloji Yığını

- **Core:** Flutter (Dart 3.x)
- **Arayüz:** HTML5, Modern CSS, Vanilla Javascript (SPA - Single Page Application yapısında birleştirilmiş Google Stitch tasarımı)
- **WebView:** `flutter_inappwebview` ile yerel HttpServer entegrasyonu
- **Veri Depolama:** `path_provider` ile yerel JSON belgeleri (Geçmiş ve Ayarlar)
- **Paketleyici:** Windows için Inno Setup kurulum sihirbazı (`setup.iss`)

---

## 📦 Kurulum ve Derleme

### Gereksinimler
- Flutter SDK
- Windows Developer Mode (Sembolik link desteği ve derleme için gereklidir)

### Geliştirici Modunda Çalıştırma
```bash
flutter pub get
flutter run
```

### Windows Kurulum Dosyası (Installer) Üretimi
Uygulama derlemesini alıp Inno Setup betiği ile paketlemek için:
```bash
flutter build windows
# setup.iss dosyasını Inno Setup derleyicisi ile açıp derleyerek GNNcyber_NETscan_Setup.exe dosyasını üretebilirsiniz.
```

---

## 🔒 Güvenlik ve Gizlilik

Bu proje yerel ağ analizleri için tasarlanmıştır. ARP taraması veya port sorgulama işlemleri tamamen yerel cihaz üzerinden asenkron olarak gerçekleştirilir ve dış ağlara veri sızdırmaz.
