# Changelog

## v2.6.6
- **Zorunlu Tarama Modu (Nmap -Pn Benzeri):** Tekil ve statik harici IP adresleri veya alan adları girildiğinde, hedefin standart TCP Ping (Host Discovery) testini geçememesi durumunda taramanın iptal olması sorunu giderildi. Artık tekil hedefler Ping testinden düşse dahi (Güvenlik duvarı engellemesi vb.) "Up" (Açık) kabul edilerek port taramasına zorunlu olarak sokuluyor.
- **Ağ Zaman Aşımı İyileştirmesi:** TCP Ping discovery zaman aşımı toleransı dış ağ taramaları için 300ms'den 500ms'ye çıkarıldı.
## v2.6.5
- **Arayüz (UI) Geliştirmesi:** Sol paneldeki GNN Ecosystem logosu 150px genişliğinde, yüksekliği otomatik ayarlanacak şekilde orantısal olarak büyütüldü. Logoya tıklandığında uygulamanın resmi web sitesi (`https://gnn.tr`) varsayılan web tarayıcısında açılacak şekilde harici bağlantı özelliği eklendi.
- **Sürüm Güncellemesi:** Uygulama genelinde sürüm değerleri 2.6.5 olarak senkronize edildi.
## v2.6.4
- **Arayüz (UI) Güncellemesi:** Sol menüdeki logo bölümü tamamen sadeleştirildi. İkon ve metin kaldırılarak yalnızca "GNN Ecosystem" logosu merkezde konumlandırıldı ve altına 2.6.4 sürüm numarası eklendi.
- **macOS Uyumluluk Doğrulaması:** Evrensel (Universal) yapıların sorunsuz çalışması teyit edildi ve sürüm değerleri `2.6.4` olarak senkronize edildi.
## v2.6.3
- **CI/CD İyileştirmesi:** GitHub Actions üzerindeki Node.js 20 kullanımından kaynaklanan deprecation (kullanımdan kaldırma) uyarıları, tüm ilgili aksiyon eklentilerinin (checkout, setup-node, upload-artifact vb.) en güncel ana sürümlerine yükseltilmesiyle giderildi. Artık tüm süreçler sorunsuz bir şekilde doğrudan Node.js 24 üzerinde çalışmaktadır.
- **Sürüm Güncellemesi:** Tüm ortam, derleme ayarları ve kod referansları 2.6.3 sürümüne yükseltildi.

## v2.6.2
- **Hata Çözümü (Arayüz):** Javascript köprü değişkenindeki syntax (sözdizimi) hatası giderilerek arayüzdeki donma/tıklanamama sorunu çözüldü.
- **Hata Çözümü (Kurulum Sihirbazı):** `README.md` lisans dosyasının UTF-8 BOM (Byte Order Mark) kodlaması onarıldı; böylece Windows Kurulum Sihirbazı'ndaki Türkçe karakter sorunu (örn. geliÅŸtirilmiÅŸ) giderildi.

## v2.6.1
- **Yeniden Markalaşma:** Uygulama ismi "GNNcyber - NETscan" olarak güncellendi.
- **Sürüm Güncellemesi:** Tüm sistem ve CI/CD ayarlarında sürüm 2.6.1 olarak ayarlandı.
## v2.6.0
- **macOS Siyah Ekran Hata Çözümü:** macOS App Sandbox yetkilendirmelerine yerel istemci (network.client) ve sunucu (network.server) izinleri eklenerek, WebView'in yerel HTTP sunucusuna bağlanamaması sonucu oluşan siyah ekran problemi giderildi.
- **Platform Temizliği (iOS & Android Kaldırıldı):** Mobil platform (iOS ve Android) kodları, derleme gereksinimleri ve GitHub Actions mobil derleme işleri (build-ios) projeden tamamen temizlendi. Uygulama artık sadece Windows ve macOS masaüstü platformlarına odaklanmaktadır.

## v2.5.0
- **Sol Cihaz Listesinde Üretici (Vendor) Bilgisi:** Keşfedilen tüm IP adreslerinin hemen altına cihazların marka/üretici isimleri (örn. Apple, Synology, HP, Zyxel) eklenerek arayüzde gezinirken hızlıca görülmesi sağlandı.
- **Otomatik CI/CD Sürüm Yönetimi:** Sürüm yayınlama ve etiketleme işlemleri tamamen `CHANGELOG.md` tabanlı otomatikleştirildi, böylece her push'ta çift aksiyon çalışması önlendi.
- **Bireysel Tarama Detaylarını Dışa Aktarma (JSON & CSV):** Hedef Geçmişi (Target History) tablosuna her tarama satırı için bağımsız JSON ve CSV aktarım butonları eklendi. Bu sayede taranan IP adresleri, donanım MAC/Vendor bilgileri, açık portlar, servisler, versiyonlar ve zafiyet dereceleri detaylı olarak dışa aktarılabilmektedir.
- **Dinamik HOSTNAME ve Operatör Damgası:** Sol alt köşedeki profil alanı, taramayı gerçekleştiren makinenin yerel bilgisayar adıyla (`Platform.localHostname`) dinamik olarak güncellendi. Başlatılan tarama loglarına ve kaydedilen geçmiş verilerine bu HOSTNAME bilgisi basılarak Blue Team analizleri için tam izlenebilirlik sağlandı.

## v2.4.0
- **Yerel Ağda ARP Tabanlı Cihaz Keşfi:** TCP ping isteklerini engelleyen güvenlik duvarına sahip yerel cihazların tespiti için dinamik sistem ARP tablosu okuma özelliği eklendi.
- **Donanım (MAC) Adresi ve Üretici (Vendor) Bilgisi:** Keşfedilen tüm cihazların MAC adresleri ayıklanıp `macvendors.com` API'si üzerinden donanım üreticisi sorgulaması sorgulanarak arayüzde gösterilmesi sağlandı.
- **Web Arayüzü Tarayıcı Yönlendirmesi:** Açık portlarda HTTP/HTTPS web yayınları (80, 443, 5000, 8080 vb.) algılandığında yanına bir "tarayıcıda aç" butonu eklendi ve varsayılan tarayıcıda açılması sağlandı.
- **Linux Tarayıcı Desteği:** Dart tarafında Windows ve macOS'in yanı sıra Linux platformları için `xdg-open` entegrasyonu eklendi.
- **Dahili Hata Düzeltmeleri:** UI tasarımında sidebar başlığı ortalandı, font bütünlüğü Mono temayla uyumlu hale getirildi, real-time logs akış hızı optimize edildi.
