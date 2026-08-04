# Changelog

## v2.16.0
**Interactive Save Dialogs & macOS Update Fix / İnteraktif Dosya Kaydetme Penceresi ve macOS Güncelleme Düzeltmesi**
- PDF, JSON, CSV and Terminal Log exports now open an interactive Save File Dialog (`FilePicker.saveFile`) allowing users to choose the save location while retaining auto-suggested file names.
  - *PDF, JSON, CSV ve Terminal Log çıktıları artık kullanıcıya kaydedilecek dizini seçme imkanı tanıyan ve dosya adını otomatik öneren interaktif Dosya Kaydetme Penceresi (`FilePicker.saveFile`) açar.*
- Fixed macOS update installation where the progress modal remained stuck at 100%: added native macOS Archive Utility fallback extraction and updated the UI to show completion guidance.
  - *macOS güncelleme kurulumunda ilerleme modalının %100'de takılı kalma sorunu düzeltildi: yerel macOS Archive Utility yedek çıkarma desteği eklendi ve kullanıcıya yönlendirme gösteren arayüz mesajı güncellendi.*

## v2.15.0
**Auto-Detect Subnet, Hybrid ICMP Ping & Update Security Hardening / Otomatik Alt Ağ Tespiti, Hibrit ICMP Ping ve Güncelleme Güvenliği Sıkılaştırması**
- Added an auto-detect subnet dropdown that lists the machine's real network adapters (queried via OS interface info with a pure-Dart fallback) so users no longer have to guess their local CIDR range.
  - *Makinenin gerçek ağ adaptörlerini listeleyen (işletim sistemi arayüz bilgisiyle, saf Dart yedeğiyle) bir otomatik alt ağ tespit menüsü eklendi; kullanıcılar artık yerel CIDR aralığını tahmin etmek zorunda değil.*
- Host discovery now tries a real OS-level ICMP echo ping first, falling back to the existing TCP-connect probe only if ICMP is blocked or fails, improving detection accuracy on networks that filter the probed TCP ports.
  - *Cihaz keşfi artık önce gerçek bir işletim sistemi seviyesinde ICMP echo ping dener, yalnızca ICMP engellenirse veya başarısız olursa mevcut TCP-connect yöntemine döner; bu da denenen TCP portlarını filtreleyen ağlarda tespit doğruluğunu artırır.*
- Hardened the update installer against a theoretical remote-code-execution path: `downloadAndInstall` now validates the download URL against a strict allow-list (must be `https://github.com/<this repo>/releases/download/...` with the expected file extension) before downloading or executing anything.
  - *Güncelleme kurulumu, teorik bir uzaktan kod çalıştırma (RCE) yoluna karşı sıkılaştırıldı: `downloadAndInstall` artık herhangi bir şey indirmeden veya çalıştırmadan önce indirme URL'sini katı bir izin listesine (`https://github.com/<bu depo>/releases/download/...` ve beklenen dosya uzantısı) göre doğruluyor.*

## v2.14.0
**Clean Break: Legacy Identifiers Removed / Temiz Kesim: Eski Tanımlayıcılar Kaldırıldı**
- Removed the previous version's temporary migration and installer cleanup steps for the old internal identifier. This is a clean-slate release: no legacy references remain anywhere in the codebase, but pre-rename local data/shortcuts from very old installs are no longer auto-migrated.
  - *Önceki sürümdeki eski dahili tanımlayıcıya ait geçici göç ve kurulum temizleme adımları kaldırıldı. Bu sürüm temiz bir başlangıçtır: kod tabanında hiçbir yerde eski referans kalmadı, ancak çok eski kurulumların yerel verisi/kısayolları artık otomatik taşınmıyor.*

## v2.13.0
**Project & Internal Identifier Rename / Proje ve Dahili Tanımlayıcı Yeniden Adlandırma**
- Renamed the GitHub repository to `gnncyber-netscan` and updated every internal reference (update checker, installer URLs, README, About screen) to match, with no change to the app's display name.
  - *GitHub deposu `gnncyber-netscan` olarak yeniden adlandırıldı ve tüm dahili referanslar (güncelleme kontrolcüsü, kurulum linkleri, README, Hakkında ekranı) buna göre güncellendi; uygulamanın görünen adında bir değişiklik yok.*
- Renamed the app's internal legacy identifier across the Dart package, Windows/macOS/Linux build identifiers, and the JS↔Dart bridge.
  - *Uygulamanın dahili eski tanımlayıcısı; Dart paketi, Windows/macOS/Linux derleme kimlikleri ve JS↔Dart köprüsü genelinde yeniden adlandırıldı.*

## v2.12.0
**Light Theme / Açık Tema**
- Added a full light theme (cream/off-white background, indigo + moss-green accents) alongside the existing dark theme, with a SYSTEM / LIGHT / DARK selector in Settings > Appearance. Defaults to following the OS color scheme automatically.
  - *Mevcut koyu temanın yanına tam bir açık tema (krem/kirli-beyaz zemin, indigo + yosun yeşili vurgular) eklendi; Settings > Appearance altında SİSTEM / AÇIK / KOYU seçici ile. Varsayılan olarak işletim sisteminin renk şemasını otomatik takip eder.*

## v2.11.1
**About Screen / Hakkında Ekranı**
- Added a new "About" navigation item and view with developer info (BigDesigner, gnn.tr, github.com/BigDesigner), technical stack summary, MIT license text, and a legal disclaimer for authorized use only.
  - *Yeni bir "About" navigasyon öğesi ve görünümü eklendi: geliştirici bilgileri (BigDesigner, gnn.tr, github.com/BigDesigner), teknik yığın özeti, MIT lisans metni ve yalnızca yetkili kullanım için yasal sorumluluk reddi beyanı.*

## v2.11.0
**Opt-in Update Checker & Official IEEE Vendor Database / Onaylı Güncelleme Kontrolü & Resmi IEEE Üretici Veritabanı**
- Added a manual "Check for Updates" control in Settings that queries GitHub Releases only on request, shows the available version, and downloads + launches the installer directly with no browser redirect.
  - *Settings ekranına, yalnızca kullanıcı talebiyle GitHub Releases'i sorgulayan, mevcut sürümü gösteren ve installer'ı doğrudan indirip başlatan (tarayıcıya yönlendirme olmadan) manuel bir "Check for Updates" kontrolü eklendi.*
- Replaced the bundled offline MAC vendor (OUI) database with a direct export of the official IEEE registry (~39,700 prefixes), fixing several vendor misattributions inherited from the previous crowd-sourced dataset.
  - *Gömülü offline MAC üretici (OUI) veritabanı, resmi IEEE kayıt sisteminden alınan doğrudan bir dışa aktarımla (~39.700 prefix) değiştirildi; önceki topluluk kaynaklı veri setinden kalan birkaç üretici yanlış eşleştirmesi düzeltildi.*
- Made the `macvendors.com` online vendor lookup fallback opt-in (default off) with an explicit in-app privacy warning, since it previously ran silently despite the app's offline/air-gapped positioning.
  - *`macvendors.com` çevrimiçi üretici sorgu yedeği, uygulamanın çevrimdışı/air-gapped konumlandırmasına rağmen daha önce sessizce çalıştığı için varsayılan olarak kapalı ve açık bir gizlilik uyarısıyla isteğe bağlı hale getirildi.*
- Renamed the "Advanced Configuration" navigation item to "Settings" to match the sibling navigation items and better reflect its now-broader scope.
  - *"Advanced Configuration" navigasyon öğesi, diğer menü öğeleriyle tutarlı olması ve artık genişleyen kapsamını daha iyi yansıtması için "Settings" olarak yeniden adlandırıldı.*

## v2.10.5
**Header Layout Refinement / Üst Bar Tasarım İyileştirmesi**
- Relocated the vertical separator (`|`) to sit correctly between the `BLUE_TEAM_TERMINAL` title and the version label.
  - *Dikey ayraç (`|`), `BLUE_TEAM_TERMINAL` başlığı ile versiyon etiketi arasına düzgün şekilde konumlandırıldı.*

## v2.10.4
**UI Refactoring & Version Repositioning / Arayüz Düzenlemesi & Versiyon Konumlandırması**
- Moved the version indicator from the sidebar to the header next to the terminal title.
  - *Versiyon göstergesi sol menüden alınarak üst barda terminal başlığının yanına taşındı.*
- Removed dual version labels from the sidebar to create a cleaner navigation layout.
  - *Daha temiz bir navigasyon düzeni oluşturmak için sol menüdeki çift versiyon etiketleri kaldırıldı.*

## v2.10.3
**Dependency Maintenance Update / Bağımlılık Bakım Güncellemesi**
- Upgraded all direct dependencies (pdf, sqflite_common_ffi, path_provider, flutter_inappwebview) to their latest stable versions.
  - *Tüm doğrudan bağımlılıklar (pdf, sqflite_common_ffi, path_provider, flutter_inappwebview) en güncel kararlı sürümlerine yükseltildi.*
- Resolved and updated transitive dependencies (xml 7.x, qr 4.x, image 4.9.x, sqflite_common 2.5.11 etc.) via pub upgrade.
  - *Transitif bağımlılıklar (xml 7.x, qr 4.x, image 4.9.x, sqflite_common 2.5.11 vb.) pub upgrade ile çözümlenip güncellendi.*

## v2.10.2
**Setup Installer UI and Dependency Checks Update / Kurulum Arayüzü ve Bağımlılık Denetimi Güncellemesi**
- **VCRedist Installation:** Windows installer (setup) program now checks if Visual C++ Redistributable (x64) is installed on the user's machine. If missing, it installs it automatically.
  - *VCRedist Kurulumu: Windows yükleyici (setup) programı artık kullanıcı makinesinde Visual C++ Redistributable (x64) kurulu olup olmadığını denetler. Eksikse otomatik kurar.*
- **Installer UX/UI Update:** Fixed the issue where silent background downloads of WebView2 and VCRedist via `setup.iss` made the installer appear frozen depending on internet speed. Progress bars and descriptive message windows are now visible during installation.
  - *Kurulum UX/UI Güncellemesi: `setup.iss` üzerinden sessiz (silent) indirilen ve kurulan (WebView2, VCRedist) yardımcı araçların, internet hızına bağlı olarak indirme sürecinde ekranı dondurmuş gibi göstermesi sorunu giderildi. Kurulum sırasında ilerleme çubukları ve açıklayıcı mesaj pencereleri görünür kılındı.*

## v2.10.1
**PDF/CSV Export Hostname Fix / PDF/CSV İhracat Hostname Düzeltmesi**
- **Export Fix:** Fixed an issue where newly added `hostname` values were not correctly reflected in PDF and CSV export reports (OS label was written instead). Export logic is updated to use `hostname` if available, otherwise fallback to the OS label.
  - *Dışa Aktarım Düzeltmesi: PDF ve CSV rapor çıktılarında yeni eklenen `hostname` değerlerinin doğru şekilde yansıtılmama sorunu (yerine işletim sistemi etiketinin yazılması) düzeltildi. `hostname` mevcutsa o, yoksa fallback etiketi kullanılacak şekilde ihracat logiği güncellendi.*

## v2.10.0
**Discovery Enhancement: Hostname Resolution & Local MAC / Keşif Geliştirmesi: Hostname Çözümleme & Yerel MAC**
- **Hostname Resolution:** Performs DNS/mDNS reverse lookup for each active IP found during the scan to resolve real device names (e.g., `iPad.local`, `MSI-4060.home`), displaying them in both the host list and detail panel.
  - *Hostname Çözümleme: Tarama sırasında bulunan her aktif IP için DNS/mDNS reverse lookup yapılarak cihazların gerçek isimleri (ör. `iPad.local`, `MSI-4060.home`) çözümlenir ve hem host listesinde hem detay panelinde gösterilir.*
- **Local MAC Discovery:** The scanning machine's own MAC address is no longer displayed as `N/A`; the physical address is detected via `ipconfig /all` (Windows) / `ifconfig` (macOS).
  - *Yerel MAC Keşfi: Taramayı yapan makinenin kendi MAC adresi artık `N/A` gösterilmez; `ipconfig /all` (Windows) / `ifconfig` (macOS) üzerinden fiziksel adres tespit edilir.*

## v2.9.1
**UI Tweaks and Stealth Order Fix / Arayüz Düzenlemeleri ve Gizlilik Sıralaması Düzeltmesi**
- **Stealth Options Reordered:** Stealth scanning modes T1-T5 (Sneaky -> Insane) have been reordered sequentially to match their logical progression.
  - *Gizlilik Seçenekleri Yeniden Sıralandı: Tarama gizlilik (Stealth) modları T1-T5 (Sneaky -> Insane) sırasıyla, mantıksal sıralamaya uygun olarak listelenecek şekilde düzenlendi.*

## v2.9.0
**Offline Support, Structural Security Updates, and Styled Telemetry Fixes / Çevrimdışı Destek, Yapısal Güvenlik Güncellemeleri ve Telemetri Düzeltmeleri**

### Offline / Air-gap Support / Çevrimdışı (Air-gap) Desteği
- **Local Tailwind CSS & Icons:** Tailwind CSS CDN and Material Symbols Outlined font files are locally bundled into the project. Ensures full UI functionality without internet access.
  - *Yerel Tailwind CSS ve İkonlar: Tailwind CSS CDN ve Material Symbols Outlined font dosyaları projeye lokal olarak bundle edildi. İnternet olmayan ortamlarda da arayüzün bozulmadan tam fonksiyonel çalışması sağlandı.*
- **Local Web Server:** Added `.ttf` font support to the local HTTP server's MIME types.
  - *Yerel Web Sunucusu: Local HTTP sunucusunun MIME tiplerine `.ttf` font desteği eklendi.*

### Security & UI Fixes / Güvenlik & Arayüz Düzeltmeleri
- **XSS & ID Fix (C2/C7):** Completely removed inline `onclick` handlers in the history list and transitioned to DOM API and event delegation to eliminate XSS risks. Added microsecond-based unique `id` to history records to prevent collisions.
  - *XSS & ID Düzeltmesi (C2/C7): Geçmiş kayıtlar listesindeki inline `onclick` handler'ları tamamen kaldırılıp DOM API ve event delegation yapısına geçilerek XSS riski sıfırlandı. Çakışmaları önlemek için history kaydına mikro-saniye bazlı benzersiz `id` eklendi.*
- **Toast Instead of Alert (C1):** Replaced ugly browser `alert()` windows with modern, sleek animated Toast notifications fitting the Blue Team theme.
  - *Alert yerine Toast (C1): Eski ve çirkin tarayıcı `alert()` pencereleri yerine Blue Team temasına uygun, modern ve şık animasyonlu bildirim (Toast) arayüzü eklendi.*
- **Fake Telemetry Cleanup (C5):** Removed fake CPU/MEM progress bars generating random values. Updated fixed `1.2 THz` text to `LOCAL ENGINE`. Replaced the fake IP address (`127.0.0.1`) with dynamic display of the actual local IP address from the OS.
  - *Sahte Telemetri Temizliği (C5): Arayüzdeki rastgele değer üreten sahte CPU/MEM barları kaldırıldı. Sabit `1.2 THz` yazısı `LOCAL ENGINE` olarak güncellendi. Sahte IP adresi (`127.0.0.1`) yerine işletim sisteminden çekilen gerçek yerel IP adresinin dinamik gösterimi sağlandı.*
- **Platform-Specific ARP (A4):** Implemented `arp -an` flag configuration on macOS for much faster ARP table querying.
  - *Platform Uyumlu ARP (A4): macOS üzerinde ARP tablosunun çok daha hızlı sorgulanması amacıyla `arp -an` flag yapılandırması uygulandı.*
- **Shorthand IP Range Support (A5):** Added parsing support for shorthand last-octet scan ranges like `192.168.1.10-20`.
  - *Kısaltılmış IP Aralığı Desteği (A5): `192.168.1.10-20` gibi son oktet kısaltmalı tarama aralıkları için çözümleme desteği getirildi.*
- **Duplicate Normalization Cleanup (D1):** Removed unnecessary OpenSSH normalization duplications in `scan_engine.dart`.
  - *Mükerrer Normalizasyon Temizliği (D1): `scan_engine.dart` üzerindeki gereksiz OpenSSH normalizasyon tekrarları temizlendi.*
- **M-04 and M-05 Fixes:** Relaxed hardcoded checks in asset presentation with dynamic file checks. Standardized PDF report color inconsistencies to the corporate `blueGrey800` color theme.
  - *M-04 ve M-05 Düzeltmeleri: Asset sunumundaki hardcoded kontrol mekanizmaları dinamik dosya kontrolüyle esnetildi. PDF raporlarındaki renk tutarsızlıkları `blueGrey800` kurumsal renk teması altında eşitlendi.*

### Infrastructure & CI/CD / Altyapı & CI/CD
- **Unnecessary SQLite Cleanup (A2):** Deleted the unused duplicate SQLite history table and all related functions. Consolidated to a single JSON-based `HistoryDb` source.
  - *Gereksiz SQLite Temizliği (A2): Geçmiş kaydı için kullanılmayan mükerrer SQLite geçmiş tablosu ve ilgili tüm fonksiyonlar silindi. Tek kaynak JSON-tabanlı `HistoryDb` olarak birleştirildi.*
- **Unnecessary SQLite Copying (A1):** Integrated a version file for version control of the CVE database. Ensured automatic database refresh on updates.
  - *Gereksiz SQLite Kopyalaması (A1): CVE veritabanının sürüm kontrolü için sürüm dosyası entegre edildi. Güncellemelerde veritabanının otomatik yenilenmesi sağlandı.*
- **CI/CD Action Versions (B1):** Replaced invalid/outdated major action versions in the `build.yml` workflow with stable versions like `@v4`/`@v2`. Added Python setup step. Optimized release notes generation.
  - *CI/CD Action Sürümleri (B1): `build.yml` iş akışındaki geçersiz/eski major action sürümleri `@v4`/`@v2` gibi kararlı sürümlerle değiştirildi. Python kurulum adımı eklendi. Sürüm notları üretimi optimize edildi.*
- **MIT License:** Added an MIT license document to the project and configured the installer accordingly.
  - *Projeye MIT lisans belgesi eklenerek kurulum aracı buna göre yapılandırıldı.*

## v2.8.0
**Full Codebase Security & Bug Audit — 18 Critical/High Bugs Fixed / Tam Kod Tabanı Güvenlik ve Hata Denetimi — 18 Kritik/Yüksek Hata Çözüldü**

### Security Fixes (XSS / Injection) / Güvenlik Düzeltmeleri (XSS / Enjeksiyon)
- **JS Bridge Injection:** Secured all string values sent from Dart to JS (onLog, onHostDiscovered, onPortDiscovered) using `jsonEncode()` instead of raw string interpolation. External data like banner grabs can no longer break JS execution.
  - *JS Bridge Enjeksiyonu: Dart'tan JS'e gönderilen tüm string değerler (onLog, onHostDiscovered, onPortDiscovered) ham string interpolasyonu yerine `jsonEncode()` ile güvence altına alındı. Banner grab gibi harici kaynaklı veriler artık JS kodunu bozamaz.*
- **XSS — addLog():** Switched to DOM API (`createElement` + `textContent`) to prevent injection via `innerHTML` in the log terminal.
  - *XSS — addLog(): Log terminalinde `innerHTML` ile yapılan enjeksiyona karşı DOM API (`createElement` + `textContent`) kullanımına geçildi.*
- **XSS — updateHostsTreeView():** Sanitizing IP, vendor, and label values in the host tree view using the `htmlEscape()` helper.
  - *XSS — updateHostsTreeView(): Host tree view'daki IP, vendor, label değerleri `htmlEscape()` yardımcısı ile temizleniyor.*
- **XSS — updatePortsTable():** Protecting service, version, and state values in the port table using `htmlEscape()`.
  - *XSS — updatePortsTable(): Port tablosundaki servis, versiyon, state değerleri `htmlEscape()` ile korunuyor.*
- Added a global `htmlEscape()` helper function to the project.
  - *Projeye global `htmlEscape()` yardımcı fonksiyonu eklendi.*

### Bug Fixes / Hata Düzeltmeleri
- **Abort State (M-03):** Aborted scans were always recorded as COMPLETED instead of ABORTED. Fixed via the `_scanWasAborted` flag mechanism.
  - *Abort Durumu (M-03): İptal edilen taramalar ABORTED yerine hep COMPLETED olarak kaydediliyordu. `_scanWasAborted` flag mekaniğmasıyla düzeltildi.*
- **Dispose (M-06):** Active scanning engines are now stopped and the HTTP server is force-closed (`force: true`) when the application window is closed.
  - *Dispose (M-06): Uygulama penceresi kapatılırken aktif tarama motor durduruluyor ve HTTP sunucusu zorla (`force: true`) kapatılıyor.*
- **Ping Timeout (SE-01):** `_pingHost()` now uses the user-configured `timeout` value instead of a hardcoded 500ms.
  - *Ping Timeout (SE-01): `_pingHost()` hardcoded 500ms yerine artık kullanıcının ayarladığı `timeout` değerini kullanıyor.*
- **CIDR < /24 Error (SE-03):** CIDR inputs smaller than `/24` no longer fail silently; a clear error message is shown to the user.
  - *CIDR < /24 Hatası (SE-03): `/24` den küçük CIDR girişleri artık sessizce başarısız olmuyor; kullanıcıya anlaşılır hata mesajı gösteriliyor.*
- **IP Range Exceeded (SE-04):** Ranges containing more than 256 hosts are now reported with a warning message.
  - *IP Range Aşımı (SE-04): 256'dan fazla host içeren aralıklar artık uyarı mesajıyla bildiriliyor.*
- **HttpClient Leak (SE-09):** The `HttpClient` in `_getMacVendor()` was not closed properly. Added `client.close()` in the `finally` block.
  - *HttpClient Sızıntısı (SE-09): `_getMacVendor()` fonksiyonunda `HttpClient` her çağrıda yaratılıp kapatılmıyordu. `finally` bloğunda `client.close()` çağrısı eklendi.*

### Architecture Cleanup / Mimari Temizlik
- **Dead Code (D-03/D-04):** Removed duplicate SQLite write that read nothing after writing history records to SQLite. Single source of truth is now the JSON-based `HistoryDb`.
  - *Ölü Kod (D-03/D-04): Geçmiş kaydı SQLite'a yazdıktan sonra hiç okumayan duplicate SQLite write kaldırıldı. Tek kaynak JSON-tabanlı `HistoryDb`.*
- **Unused Dependency (P-01):** The `csv: ^8.0.0` dependency was entirely unused and has been removed.
  - *Kullanılmayan Bağımlılık (P-01): `csv: ^8.0.0` bağımlılığı hiç kullanılmıyordu, kaldırıldı.*

### Version / Copyright / Versiyon & Telif Hakkı
- **Runner.rc Fallback (R-01/R-02):** Updated `#define VERSION_AS_NUMBER` and `VERSION_AS_STRING` macros from `2.6.13` to `2.8.0`.
  - *Runner.rc Fallback (R-01/R-02): `#define VERSION_AS_NUMBER` ve `VERSION_AS_STRING` macros `2.6.13`'te kalmıştı, güncellendi.*
- **LegalCopyright (R-03):** Replaced `com.example` placeholder with the real company name: `BigDesigner`.
  - *LegalCopyright (R-03): `com.example` placeholderı gerçek firma adıyla değiştirildi: `BigDesigner`.*

## v2.7.5
- **PDF Optimization:** Improved the design of tables (column widths, font sizes, and paddings) in the PDF export tool. Detailed scan reports are now generated in A4 Landscape format to provide wider space, preventing text truncation or line wraps.
  - *PDF Optimizasyonu: PDF dışa aktarma (export) aracındaki tabloların tasarımı (sütun genişlikleri, font boyutları ve dolgular) iyileştirildi. Detaylı tarama raporları artık daha geniş alan sağlaması için A4 Yatay (Landscape) formatında çıkarılıyor; böylece yazılarda satır kaymaları veya daralmalar yaşanmıyor.*

## v2.7.4
- **UI Version Synchronization:** Cleaned up a forgotten hardcoded version number in the UI and synchronized it with the current release. Ensured autonomous version management continues flawlessly.
  - *Arayüz Versiyon Senkronizasyonu: Arayüzde (UI) unutulmuş olan sabit (hardcoded) versiyon numarası temizlenip güncel sürümle senkronize edildi. Versiyon yönetiminin eksiksiz otonom devam etmesi güvence altına alındı.*

## v2.7.3
- **UI Reordering:** Corrected the ordering of scanning modules on the main screen to a logical sequence (MOD_00 - MOD_04).
  - *Arayüz Düzenlemesi: Ana ekrandaki tarama modüllerinin sıralaması mantıksal (MOD_00 - MOD_04) olarak düzeltildi.*
- **Installer Improvement:** Resolved an issue where the installation wizard appeared frozen due to the WebView2 component downloading in the background; the process is now completely transparent.
  - *Kurulum İyileştirmesi: Yükleme işlemi sırasında arka planda indirilen WebView2 bileşeninden dolayı kurulum sihirbazının donmuş gibi bekleme yapması sorunu giderildi; işlem tamamen şeffaf hale getirildi.*

## v2.7.2
- **Professional PDF Reporting:** The PDF generation engine has been completely revamped. Global scan history and individual scan details can now be exported to PDF in a professional corporate format (featuring tables, colored headers, and detailed device analysis).
  - *Profesyonel PDF Raporlama: PDF oluşturma motoru tamamen yenilendi. Global tarama geçmişi ve tekil tarama detayları, artık profesyonel kurumsal formatta (tablolar, renkli başlıklar ve detaylı cihaz analiziyle) PDF'e aktarılabiliyor.*
- **CVE Matching Improvement:** Added partial match (LIKE) support to offline database queries, increasing service/version detection capabilities.
  - *Zafiyet Eşleştirme (CVE) İyileştirmesi: Çevrimdışı veritabanı aramalarında kısmi eşleşme (LIKE) desteği eklenerek servis/versiyon tespit yeteneği artırıldı.*
- **OS Fingerprint (UI Fix):** Fixed a Bridge library error that prevented background-detected OS info (Windows, Linux, Router, etc.) from reflecting on the UI icons.
  - *OS Fingerprint (Arayüz Fix): Arka planda tespit edilen işletim sistemi bilgilerinin (Windows, Linux, Router vb.) UI üzerindeki ikonlara yansımamasına sebep olan Bridge (Köprü) kütüphanesi hatası giderildi.*

## v2.7.1
- **Installer Screen Improvement:** Condensed the lengthy informational text on the installer screen into a concise 5-point summary for faster and easier reading.
  - *Kurulum Ekranı İyileştirmesi: Yükleyici (installer) ekranındaki uzun bilgilendirme metni, daha hızlı ve kolay okunabilmesi için 5 maddelik sade bir özete dönüştürüldü.*

## v2.7.0
- **Stealth / Rate Limiting (Evasion):** Added scan speed/delay options ranging from T1 (Sneaky) to T5 (Insane) to bypass IDS/IPS and Firewalls. Connection attempts are now shuffled randomly rather than sequentially to hinder firewall detection.
  - *Gizlilik / Hız Sınırlandırma (Evasion): IDS/IPS ve Firewall atlatma amacıyla T1 (Sneaky) ile T5 (Insane) arası tarama hızı/gecikme seçenekleri eklendi. Bağlantı denemeleri port sırasında değil rastgele (shuffle) yapılarak güvenlik duvarlarının tespiti zorlaştırıldı.*
- **Offline CVE Database:** Explored services' version numbers are now matched with known vulnerabilities (CVEs) using an internal SQLite database (cve_db.sqlite) and reported on the UI (CRITICAL, HIGH, etc.).
  - *Çevrimdışı CVE Veritabanı: Dahili bir SQLite veritabanı (cve_db.sqlite) ile keşfedilen servislerin versiyon numaraları bilinen güvenlik açıkları (CVE) ile eşleştirilip arayüzde (CRITICAL, HIGH, vb.) raporlanmaktadır.*
- **OS Fingerprinting:** The target system's OS (Windows, Linux, Network Device) is analyzed via ICMP Ping TTL (Time-To-Live) values and displayed on the UI with device-specific icons.
  - *İşletim Sistemi Tespiti: Hedef sistemin işletim sistemi (Windows, Linux, Ağ Cihazı) ICMP Ping TTL (Time-To-Live) değerleri üzerinden analiz edilerek arayüzde cihaz türüne göre özel ikonlarla gösterilmesi sağlandı.*
- **PDF Export:** Added the ability to export scan history as a professional PDF report in addition to CSV and JSON formats.
  - *PDF İhracatı: Tarama geçmişini CSV ve JSON formatlarının yanı sıra artık profesyonel bir PDF Raporu olarak dışa aktarma özelliği eklendi.*

## v2.6.13
- **CI/CD Optimization:** Updated the GitHub Actions workflow. The `build-windows` and `build-macos` jobs now run conditionally only when a new version number is added to the CHANGELOG (`release_needed == 'true'`), preventing unnecessary builds on every commit and saving quota.
  - *CI/CD Optimizasyonu: GitHub Actions iş akışı güncellendi. Artık gereksiz yere her kod gönderiminde derleme yapılmaması için `build-windows` ve `build-macos` işleri yalnızca CHANGELOG'a yeni bir versiyon numarası eklendiğinde (`release_needed == 'true'`) çalışacak şekilde koşullandırıldı.*

## v2.6.12
- **Custom Scan Module:** Added a new "Custom Scan" module to the UI. Selecting this module reveals a text box where custom ports (like `80` or `80,3389,5000`) can be entered to scan only those specific targets.
  - *Custom Scan Modülü: Arayüze "Custom Scan" adlı yeni bir tarama modülü eklendi. Bu modül seçildiğinde ortaya çıkan metin kutusuna `80` veya `80,3389,5000` gibi özel portlar girilerek sadece bu hedeflerin taranması sağlanabiliyor.*
- **Port Count Display:** The "Discovered Targets" list now instantly displays the number of active ports found on each IP address on the right side.
  - *Port Sayısı Gösterimi: "Discovered Targets" listesinde artık her bir IP adresinde kaç adet aktif port bulunduğu anlık olarak sağ tarafta görüntülenmektedir.*
- **Logo Removed:** The logo in the left menu has been completely removed for a cleaner look.
  - *Logo Kaldırıldı: Sol menüdeki logo, daha sade bir görünüm için tamamen kaldırıldı.*

## v2.6.11
- **UI Fix:** Removed a link redirection on the left menu logo (https://gnn.tr) that caused the page to open within the app's WebView instead of a new browser window. The logo now serves purely as a visual element.
  - *Arayüz Düzeltmesi: Sol menüdeki logoya tıklandığında (https://gnn.tr) sayfanın uygulamanın WebView'inde açılmasına sebep olan link yönlendirmesi tamamen kaldırıldı. Logo artık sadece görsel bir element.*

## v2.6.10
- **Quick Scan Scope Expanded:** Updated the Quick Scan module based on user request. Instead of only performing Host Discovery (MAC/Ping), it now additionally scans the **top 20 critical TCP ports** to quickly assess system status.
  - *Quick Scan Kapsamı Genişletildi: Kullanıcı talebi üzerine Quick Scan modülü güncellendi. Sadece Host Discovery (MAC/Ping) yapmak yerine artık sistemin durumunu hızlıca değerlendirebilmek için **en kritik ilk 20 TCP portunu** da ekstra olarak tarıyor.*

## v2.6.9
- **UI Freeze and Scan Abort Optimization:** Logging each scanned port to the UI during a Full Port Scan (65,535 ports) created a massive message bottleneck in the WebView bridge. This caused the UI to continue printing tens of thousands of queued messages (making it look like scanning was still ongoing) even after the "Abort Scan" button was pressed and the background engine stopped. The bottleneck was completely resolved by disabling the logging of closed or filtered ports to the terminal (reporting only open ports and general statuses, similar to Nmap's default behavior). Scans now abort instantly with clean logs.
  - *Arayüz Kilitlenme ve Tarama İptali İyileştirmesi: Full Port Scan (65.535 port) sırasında her bir portun taranmasıyla ilgili arayüze log gönderilmesi WebView köprüsünde büyük bir mesaj darboğazı oluşturuyordu. Kapalı veya filtrelenmiş portların terminale yazdırılması devre dışı bırakılarak bu darboğaz tamamen çözüldü. Artık tarama anında iptal ediliyor ve loglar temiz bir şekilde duruyor.*

## v2.6.8
- **New Scan Mode Added (Quick Scan):** Added "Quick Scan" as a 4th option to the UI based on user request. This mode skips TCP port scanning entirely and only checks if the target is up and retrieves MAC/Vendor info (via ARP/Ping) at extraordinary speeds, completing the process in seconds.
  - *Yeni Tarama Modu eklendi (Quick Scan): Kullanıcı talebi üzerine arayüze 4. bir seçenek olarak "Quick Scan" modülü eklendi. Bu mod hiçbir TCP port taraması yapmaz; sadece hedefin ayakta olup olmadığını ve MAC/Üretici bilgilerini olağanüstü bir hızla tespit ederek süreci saniyeler içerisinde tamamlar.*

## v2.6.7
- **Advanced Scan Scope (Blue Team Mode):** Port scanning modes have been upgraded to the level of a professional cybersecurity tool (like Nmap).
  - *Gelişmiş Tarama Kapsamı (Blue Team Modu): Uygulamanın port tarama modları profesyonel bir siber güvenlik aracına (Nmap vb.) yakışacak seviyeye getirildi.*
  - The `Common Scan` mode now scans all **first 1024 privileged ports** and popular high ports instead of just 20 ports.
    - *`Common Scan` modu artık sadece 20 port yerine ilk **1024 ayrıcalıklı portun tamamını** ve popüler yüksek portları tarıyor.*
  - The `Full Port Scan` mode now deeply scans **all 65,535 TCP ports** from start to finish, acting like a true Blue Team tool, instead of just 100 ports.
    - *`Full Port Scan` modu artık 100 port yerine **tüm 65,535 TCP portunu** sıfırdan sona derinlemesine tarayarak gerçek bir Blue Team aracı gibi çalışıyor.*

## v2.6.6
- **Forced Scan Mode (Nmap -Pn Alternative):** Fixed an issue where scanning single and static external IP addresses or domains would abort if the target failed the standard TCP Ping (Host Discovery) test. Now, even if single targets drop from the Ping test (e.g., firewall blocking), they are considered "Up" and forcibly subjected to port scanning.
  - *Zorunlu Tarama Modu (Nmap -Pn Benzeri): Tekil hedeflerin standart TCP Ping (Host Discovery) testini geçememesi durumunda taramanın iptal olması sorunu giderildi. Artık tekil hedefler Ping testinden düşse dahi (Güvenlik duvarı vb.) "Up" kabul edilerek port taramasına zorunlu olarak sokuluyor.*
- **Network Timeout Optimization:** TCP Ping discovery timeout tolerance for external network scans was increased from 300ms to 500ms.
  - *Ağ Zaman Aşımı İyileştirmesi: TCP Ping discovery zaman aşımı toleransı dış ağ taramaları için 300ms'den 500ms'ye çıkarıldı.*

## v2.6.5
- **UI Enhancement:** Proportionally enlarged the GNN Ecosystem logo in the left panel to 150px width with automatic height. Added an external link feature to open the official website (`https://gnn.tr`) in the default web browser when the logo is clicked.
  - *Arayüz Geliştirmesi: Sol paneldeki GNN Ecosystem logosu 150px genişliğinde orantısal olarak büyütüldü. Logoya tıklandığında uygulamanın resmi web sitesi varsayılan web tarayıcısında açılacak şekilde harici bağlantı özelliği eklendi.*
- **Version Update:** Synchronized version values as 2.6.5 across the application.
  - *Sürüm Güncellemesi: Uygulama genelinde sürüm değerleri 2.6.5 olarak senkronize edildi.*

## v2.6.4
- **UI Update:** Simplified the logo section in the left menu completely. Removed the icon and text, placing only the "GNN Ecosystem" logo centrally with the 2.6.4 version number beneath it.
  - *Arayüz Güncellemesi: Sol menüdeki logo bölümü tamamen sadeleştirildi. İkon ve metin kaldırılarak yalnızca "GNN Ecosystem" logosu merkezde konumlandırıldı ve altına sürüm numarası eklendi.*
- **macOS Compatibility Verification:** Verified flawless operation of Universal builds and synchronized version values to `2.6.4`.
  - *macOS Uyumluluk Doğrulaması: Evrensel (Universal) yapıların sorunsuz çalışması teyit edildi ve sürüm değerleri `2.6.4` olarak senkronize edildi.*

## v2.6.3
- **CI/CD Optimization:** Resolved Node.js 20 deprecation warnings on GitHub Actions by upgrading all relevant action plugins (checkout, setup-node, upload-artifact, etc.) to their latest major versions. All processes now run seamlessly directly on Node.js 24.
  - *CI/CD İyileştirmesi: GitHub Actions üzerindeki Node.js 20 kullanımından kaynaklanan deprecation uyarıları, tüm ilgili aksiyon eklentilerinin en güncel ana sürümlerine yükseltilmesiyle giderildi. Artık tüm süreçler doğrudan Node.js 24 üzerinde çalışmaktadır.*
- **Version Update:** Upgraded all environment, build settings, and code references to version 2.6.3.
  - *Sürüm Güncellemesi: Tüm ortam, derleme ayarları ve kod referansları 2.6.3 sürümüne yükseltildi.*

## v2.6.2
- **Bug Fix (UI):** Fixed a syntax error in the Javascript bridge variable that caused UI freezing/unclickability issues.
  - *Hata Çözümü (Arayüz): Javascript köprü değişkenindeki syntax hatası giderilerek arayüzdeki donma/tıklanamama sorunu çözüldü.*
- **Bug Fix (Installer Wizard):** Repaired the UTF-8 BOM (Byte Order Mark) encoding of the `README.md` license file, fixing Turkish character rendering issues in the Windows Setup Wizard.
  - *Hata Çözümü (Kurulum Sihirbazı): `README.md` lisans dosyasının UTF-8 BOM kodlaması onarıldı; böylece Windows Kurulum Sihirbazı'ndaki Türkçe karakter sorunu giderildi.*

## v2.6.1
- **Rebranding:** Updated application name to "GNNcyber - NETscan".
  - *Yeniden Markalaşma: Uygulama ismi "GNNcyber - NETscan" olarak güncellendi.*
- **Version Update:** Set version to 2.6.1 across all system and CI/CD settings.
  - *Sürüm Güncellemesi: Tüm sistem ve CI/CD ayarlarında sürüm 2.6.1 olarak ayarlandı.*

## v2.6.0
- **macOS Black Screen Bug Fix:** Added local client (`network.client`) and server (`network.server`) entitlements to macOS App Sandbox, resolving the black screen issue caused by the WebView failing to connect to the local HTTP server.
  - *macOS Siyah Ekran Hata Çözümü: macOS App Sandbox yetkilendirmelerine yerel istemci ve sunucu izinleri eklenerek, WebView'in yerel HTTP sunucusuna bağlanamaması sonucu oluşan siyah ekran problemi giderildi.*
- **Platform Cleanup (iOS & Android Removed):** Completely removed mobile platform (iOS and Android) code, build requirements, and GitHub Actions mobile build jobs (`build-ios`) from the project. The application now exclusively focuses on Windows and macOS desktop platforms.
  - *Platform Temizliği: Mobil platform kodları, derleme gereksinimleri ve GitHub Actions mobil derleme işleri projeden tamamen temizlendi. Uygulama artık sadece Windows ve macOS masaüstü platformlarına odaklanmaktadır.*

## v2.5.0
- **Vendor Info in Left Device List:** Added device brand/vendor names (e.g., Apple, Synology, HP, Zyxel) right below all discovered IP addresses for quick viewing while navigating the UI.
  - *Sol Cihaz Listesinde Üretici (Vendor) Bilgisi: Keşfedilen tüm IP adreslerinin hemen altına cihazların marka/üretici isimleri eklenerek arayüzde gezinirken hızlıca görülmesi sağlandı.*
- **Automated CI/CD Version Management:** Fully automated release publishing and tagging operations based on `CHANGELOG.md`, preventing duplicate action runs on every push.
  - *Otomatik CI/CD Sürüm Yönetimi: Sürüm yayınlama ve etiketleme işlemleri tamamen `CHANGELOG.md` tabanlı otomatikleştirildi, böylece her push'ta çift aksiyon çalışması önlendi.*
- **Export Individual Scan Details (JSON & CSV):** Added independent JSON and CSV export buttons to the Target History table for each scan row. Discovered IP addresses, hardware MAC/Vendor info, open ports, services, versions, and vulnerability severity can now be exported in detail.
  - *Bireysel Tarama Detaylarını Dışa Aktarma: Hedef Geçmişi tablosuna her tarama satırı için bağımsız JSON ve CSV aktarım butonları eklendi. IP adresleri, donanım bilgileri, açık portlar ve zafiyet dereceleri detaylı olarak dışa aktarılabilmektedir.*
- **Dynamic HOSTNAME and Operator Stamp:** The profile area in the bottom left corner dynamically updates with the scanning machine's local computer name (`Platform.localHostname`). This HOSTNAME is stamped onto initiated scan logs and saved history records to provide full traceability for Blue Team analysis.
  - *Dinamik HOSTNAME ve Operatör Damgası: Sol alt köşedeki profil alanı, taramayı gerçekleştiren makinenin yerel bilgisayar adıyla dinamik olarak güncellendi. Başlatılan tarama loglarına ve kaydedilen geçmiş verilerine bu HOSTNAME bilgisi basılarak tam izlenebilirlik sağlandı.*

## v2.4.0
- **ARP-Based Device Discovery on Local Network:** Added dynamic system ARP table reading to detect local devices hidden behind firewalls that block TCP ping requests.
  - *Yerel Ağda ARP Tabanlı Cihaz Keşfi: TCP ping isteklerini engelleyen güvenlik duvarına sahip yerel cihazların tespiti için dinamik sistem ARP tablosu okuma özelliği eklendi.*
- **Hardware (MAC) Address and Vendor Info:** Extracted MAC addresses for all discovered devices and queried the `macvendors.com` API to display hardware manufacturer information on the UI.
  - *Donanım (MAC) Adresi ve Üretici Bilgisi: Keşfedilen tüm cihazların MAC adresleri ayıklanıp `macvendors.com` API'si üzerinden donanım üreticisi sorgulaması yapılarak arayüzde gösterilmesi sağlandı.*
- **Web UI Browser Redirection:** Added an "open in browser" button next to detected HTTP/HTTPS web broadcasts (80, 443, 5000, 8080, etc.) on open ports, allowing them to be opened in the default browser.
  - *Web Arayüzü Tarayıcı Yönlendirmesi: Açık portlarda HTTP/HTTPS web yayınları algılandığında yanına bir "tarayıcıda aç" butonu eklendi ve varsayılan tarayıcıda açılması sağlandı.*
- **Linux Browser Support:** Added `xdg-open` integration to the Dart backend for Linux platforms alongside Windows and macOS.
  - *Linux Tarayıcı Desteği: Dart tarafında Windows ve macOS'in yanı sıra Linux platformları için `xdg-open` entegrasyonu eklendi.*
- **Internal Bug Fixes:** Centered the sidebar title in UI design, aligned font consistency with the Mono theme, and optimized real-time log streaming speed.
  - *Dahili Hata Düzeltmeleri: UI tasarımında sidebar başlığı ortalandı, font bütünlüğü Mono temayla uyumlu hale getirildi, real-time logs akış hızı optimize edildi.*
