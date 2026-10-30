# Mobil ve çok oyunculu simülasyon mimarisi
- 2–4+ gerçek oyuncu, gerçek zamanlı aynı dünya. Bölük (~100 kişi referans) mantıksal simülasyon birimi; ~10.000 asker ≈ 100 bölük örneği. Her asker için CPU mantığı yok. Bölüğü örn. 12–20 sprite gösterebilir; GPU instancing/batching, atlas, object pool aday.
- Simülasyon görüntü FPS'inden ayrı sabit tick (ilk prototipte 10–20 Hz araştırılabilir; henüz kabul değil). Hareket, çarpışma, görüş, ateş ve emirler süreklidir; ikmal/sağlık/XP daha seyrek hesaplanabilir. **Seyrek güncelleme = oyuncuya event-driven hikâye değil.**
- Multiplayer için öneri: sunucu otoriter durum, istemciler yalnız emir gönderir. Komutlar sıralı/kimlikli; doğrulama, tekrar bağlanma, gecikme ve hile dayanıklılığı ele alınır. Determinizm/snapshot/interpolasyon test edilir. PvP adil fog-of-war sunucuda tutulur.
- Mobil arayüz: hattı sürükle-çiz; kanat/grup/bölük seç; bağlamsal emirler; durum ikonları, dokununca detay, daraltılabilir bilgi akışı.
- Ön motor önerisi: **Godot 4.x** (Android export, headless/dedicated server, GitHub Actions ile build/test). Alternatif Defold düşük yük açısından değerlendirilebilir. Motor son kararı prototip benchmarkına bağlı.
- GitHub Actions: otomatik senaryo mantık testi, sunucu+çok istemci entegrasyonu, headless çalıştırma, Android APK derleme ve artifact. GPU'suz CI **telefon FPS doğrulaması değildir**; gerçek cihaz GPU/termal/ağ testleri ayrıca yapılmalıdır.
- Henüz gerçek repo kodu, CI workflow, APK, benchmark veya gerçek cihaz testleri yoktur.
