# Changelog

## v2.4.0
- **Yerel Ağda ARP Tabanlı Cihaz Keşfi:** TCP ping isteklerini engelleyen güvenlik duvarına sahip yerel cihazların tespiti için dinamik sistem ARP tablosu okuma özelliği eklendi.
- **Donanım (MAC) Adresi ve Üretici (Vendor) Bilgisi:** Keşfedilen tüm cihazların MAC adresleri ayıklanıp `macvendors.com` API'si üzerinden donanım üreticisi sorgulaması sorgulanarak arayüzde gösterilmesi sağlandı.
- **Web Arayüzü Tarayıcı Yönlendirmesi:** Açık portlarda HTTP/HTTPS web yayınları (80, 443, 5000, 8080 vb.) algılandığında yanına bir "tarayıcıda aç" butonu eklendi ve varsayılan tarayıcıda açılması sağlandı.
- **Linux Tarayıcı Desteği:** Dart tarafında Windows ve macOS'in yanı sıra Linux platformları için `xdg-open` entegrasyonu eklendi.
- **Dahili Hata Düzeltmeleri:** UI tasarımında sidebar başlığı ortalandı, font bütünlüğü Mono temayla uyumlu hale getirildi, real-time logs akış hızı optimize edildi.
