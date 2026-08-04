# GNNcyber - NETscan Mimari ve Veri Akış Diyagramı (v2.15.0)

Bu belgede GNNcyber - NETscan uygulamasının **Ön Yüz (Webview)**, **Dart Köprüsü (Bridge)** ve **Tarama Motoru (Core Scan Engine)** bileşenleri arasındaki veri akışları ile mimari katmanları görselleştirilmiştir.

---

## 📊 Mimari Blok Diyagramı

```mermaid
graph TD
    subgraph Frontend [Ön Yüz Katmanı - InAppWebView - HTML/CSS/JS]
        UI["Arayüz (Geist & JetBrains Mono)"]
        ExportMod["Rapor Dışa Aktarma (JSON, CSV, PDF)"]
        XSS["XSS Filtresi (htmlEscape)"]
        Console["Konsol Log Ekranı"]
    end

    subgraph DartBridge [Uygulama Köprü Katmanı - Dart & SQLite]
        Bridge["WebView JS Handler Köprüsü"]
        HistoryDB["Yerel Tarihçe Veritabanı (JSON)"]
        DBHelper["Database Helper (CVE Eşleştirme)"]
        SQLite["cve_db.sqlite (Zafiyet Veritabanı)"]
    end

    subgraph Engine [Tarama Motoru - Dart Core]
        Parser["Hedef Giriş Çözümleyici (Tekil/CIDR/Aralık)"]
        Ping["Cihaz Keşif Modülü (Socket Ping)"]
        OUICache["MAC OUI Çözümleyici"]
        LocalCache{"Lokal Önbellekte (localOuis) Var mı?"}
        MacVendors["macvendors.com API (Fallback Dış İstek)"]
        PortScan["Port Tarayıcı (TCP Sockets)"]
        Banner["Banner Yakalayıcı (Servis Sürüm Tespiti)"]
    end

    %% Akışlar ve Tetikleyiciler
    UI -->|"Taramayı Başlat (Girdi Parametreleri)"| Bridge
    Bridge -->|"Hedef Ayrıştırma"| Parser
    Parser -->|"IP Listesi"| Ping
    Ping -->|"Aktif Cihazlar (mac/ip)"| OUICache
    OUICache -->|"1. Önek Çıkar (İlk 6 Karakter)"| LocalCache
    LocalCache -->|"Evet (Lokal Çözümleme)"| Bridge
    LocalCache -->|"Hayır"| MacVendors
    MacVendors -->|"2. HTTP Sorgusu"| Bridge
    DBHelper -->|"Zafiyet CVE Sorgusu"| SQLite
    Ping -->|"Aktif Port Taraması"| PortScan
    PortScan -->|"Açık Portlar"| Banner
    Banner -->|"Sürüm Banner Bilgisi"| DBHelper
    
    %% Geri Bildirim Akışı (Callbacks)
    Engine -->|"onLog / onHostDiscovered / onPortDiscovered"| Bridge
    Bridge -->|"Köprü Yanıtı (JSON)"| XSS
    XSS -->|"Sanitize Edilmiş Veri"| UI
    UI -->|"Çıktıları Ekle"| Console
    
    %% Raporlama Akışı
    UI -->|"Raporlama Talebi"| ExportMod
    ExportMod -->|"Tarihçe Kaydını Oku"| HistoryDB
```

---

## 🔒 Kritik Güvenlik ve Akış Kontrol Noktaları

1.  **XSS Sanitize Geçidi (XSS):** Tarama motorundan veya veri tabanından gelen her türlü dinamik string (IP, Hostname, Port Versiyonu) ön yüze aktarıldıktan sonra DOM'a yazılmadan önce `htmlEscape()` filtresinden geçer.
2.  **Lokal MAC OUI Önbelleği (OUICache):** Keşfedilen cihazların MAC adresleri dış servislere gönderilmeden önce yerel önbellek haritasında (`localOuis`) aranır. Bu sayede tarama trafiğinin dış ağlara sızması engellenir ve %100 çevrimdışı çalışma sağlanır.
3.  **CVE Sürüm Kontrolü (DBHelper):** Uygulama her güncellendiğinde `cve_db_version.txt` dosyası diskteki sürümle kıyaslanır ve gerekirse güncel SQLite veri tabanı otomatik olarak kopyalanır.
