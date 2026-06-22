# GNNcyber - NETscan

GNNcyber - NETscan, Flutter ve modern web teknolojileri ile geliÅŸtirilmiÅŸ, asenkron ve Ã§ok iÅŸ parÃ§acÄ±klÄ± (multi-threaded) bir yerel aÄŸ tarama (IP/Port Scan) ve keÅŸif aracÄ±dÄ±r.

---

## ğŸš€ Temel Ã–zellikler

- **Dinamik Hedef Ã‡Ã¶zÃ¼mleme:** Tekil IP, IP aralÄ±klarÄ± (Ã¶rn. `192.168.1.10-50`), CIDR Subnet tanÄ±mlarÄ± (Ã¶rn. `192.168.1.0/24`) ve alan adlarÄ±nÄ± otomatik olarak Ã§Ã¶zÃ¼mler.
- **HÄ±zlÄ± Asenkron Tarama:** Ã‡oklu soket baÄŸlantÄ±larÄ± (varsayÄ±lan 64 thread) ile hedef sistemlerdeki aÃ§Ä±k portlarÄ± saniyeler iÃ§inde tarar.
- **ARP TabanlÄ± Host KeÅŸfi:** GÃ¼venlik duvarÄ± (firewall) nedeniyle TCP ping isteklerine kapalÄ± olan cihazlarÄ± tespit etmek amacÄ±yla yerel sistemin ARP Ã¶nbelleÄŸini (`arp -a`) dinamik olarak stimÃ¼le eder ve okur.
- **MAC Adresi & Ãœretici (Vendor) Tespiti:** Aktif cihazlarÄ±n donanÄ±m (MAC) adreslerini ayÄ±klar ve dinamik OUI sorgulamasÄ± ile Ã¼retici bilgilerini (Ã¶rn. Synology, Apple, HP, Cisco) ekrana yansÄ±tÄ±r.
- **Web ArayÃ¼zÃ¼ YÃ¶nlendirmesi:** AÃ§Ä±k portlarda bir web yayÄ±nÄ± (80, 443, 5000, 8080 vb.) tespit edildiÄŸinde port numarasÄ±nÄ±n yanÄ±nda beliren ikon yardÄ±mÄ±yla ilgili cihazÄ±n web arayÃ¼zÃ¼nÃ¼ (Ã¶rn. NAS cihazÄ± veya yazÄ±cÄ±) kullanÄ±cÄ±nÄ±n varsayÄ±lan tarayÄ±cÄ±sÄ±nda otomatik olarak aÃ§ar.
- **KalÄ±cÄ± Tarama GeÃ§miÅŸi:** Tarama ayarlarÄ±nÄ± ve geÃ§miÅŸ raporlarÄ± yerel diskte JSON tabanlÄ± bir veritabanÄ±nda saklar.
- **Brutalist Terminal Log AkÄ±ÅŸÄ±:** Arka planda gerÃ§ekleÅŸen tarama adÄ±mlarÄ±nÄ± ve soket hareketlerini canlÄ± terminal log penceresinde gÃ¶sterir.

---

## ğŸ› ï¸ Teknoloji YÄ±ÄŸÄ±nÄ±

- **Core:** Flutter (Dart 3.x)
- **ArayÃ¼z:** HTML5, Modern CSS, Vanilla Javascript (SPA - Single Page Application yapÄ±sÄ±nda birleÅŸtirilmiÅŸ Google Stitch tasarÄ±mÄ±)
- **WebView:** `flutter_inappwebview` ile yerel HttpServer entegrasyonu
- **Veri Depolama:** `path_provider` ile yerel JSON belgeleri (GeÃ§miÅŸ ve Ayarlar)
- **Paketleyici:** Windows iÃ§in Inno Setup kurulum sihirbazÄ± (`setup.iss`)

---

## ğŸ“¦ Kurulum ve Derleme

### Gereksinimler
- Flutter SDK
- Windows Developer Mode (Sembolik link desteÄŸi ve derleme iÃ§in gereklidir)

### GeliÅŸtirici Modunda Ã‡alÄ±ÅŸtÄ±rma
```bash
flutter pub get
flutter run
```

### Windows Kurulum DosyasÄ± (Installer) Ãœretimi
Uygulama derlemesini alÄ±p Inno Setup betiÄŸi ile paketlemek iÃ§in:
```bash
flutter build windows
# setup.iss dosyasÄ±nÄ± Inno Setup derleyicisi ile aÃ§Ä±p derleyerek GNNcyber - NETscan_Setup.exe dosyasÄ±nÄ± Ã¼retebilirsiniz.
```

---

## ğŸ”’ GÃ¼venlik ve Gizlilik

Bu proje yerel aÄŸ analizleri iÃ§in tasarlanmÄ±ÅŸtÄ±r. ARP taramasÄ± veya port sorgulama iÅŸlemleri tamamen yerel cihaz Ã¼zerinden asenkron olarak gerÃ§ekleÅŸtirilir ve dÄ±ÅŸ aÄŸlara veri sÄ±zdÄ±rmaz.
