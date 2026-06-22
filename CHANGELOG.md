# Changelog

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
