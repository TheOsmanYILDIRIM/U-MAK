# Mobil simülasyon — Android başlangıç performans düzeltmesi v0.4.2

**Kullanıcı hatası (30.10.2026):** 0.4.1 Android cihazında “Talime başla” ile uygulama kilitleniyor. Linux ve CI simülasyon açılışı çalışıyordu; Android donmasının kök nedeni cihaz logu olmadan kesinleşmiş değil.

**Saptanan gerçek yük:** Menü ve muharebede her kare bütün dünya: ağaçlar, arazi çizgileri, nehir ve çok sayıda görsel asker tekrar çiziliyordu. Yazılımsal görüntüleme yüksek CPU tüketiyordu.

**Değişiklikler (c39bec0):** Statik arazi `ui/terrain_layer.gd` içinde SubViewport.UPDATE_ONCE ile bir kez dokuda hesaplanıp savaş tuvaline resim olarak çiziliyor. Birimler/işaretler hareketli kalıyor. Mobil LOD, 30 FPS hedefi, menüde gereksiz redraw azaltımı, 20Hz simülasyonda tur başına en fazla 6 yeni rota ve eğitim başlangıç logları eklendi. 0.4.2 Android versionCode=6. Oyun kuralları ve komuta sistemindeki önceki davranışlar korunuyor.

**GitHub Actions 41126336700 — başarılı:** 58 çekirdek, dört Godot/ENet bağlantısı, 96 UI, dört çözünürlükte 12'şer “Talime başla” testleri (=48). Dışa aktarılan Linux oyununda `SMOKE_TRAINING_PASS`; Android ARM64 APK v2/v3 imza doğrulandı. Snapshot görüntülerinde mobil düşük ayrıntı yolu test edildi. SHA dosya+APK arşiv bütünlüğü ve 0.4.1 ile aynı sertifika denetlendi.

**Açık / blocking acceptance:** Gerçek kullanıcı Android cihazında sahne geçişi ve 10 dakikalık oyun, FPS/frametime, GPU/termal, çentik, 2–4 fiziksel cihazlı ağ ve Android logcat. Bu testler olmadan kullanıcıdaki kilitlenme `fixed` değil `pending_device_verification`.

---
## Önceki v0.4.1 mimari ve kabul kayıtları

## Uygulanan mimari
Kullanıcının Godot kararıyla motor seçildi; doğrulanan sürüm **Godot 4.5.2**, 2D Compatibility renderer. Proje `game/godot/`, otomasyon `.github/workflows/godot.yml`. Üretim sürümü güncellemesi ayrıca CI/cihaz kabulü gerektirir.

- En küçük mantıksal birim bölük. 18 dost + 18 düşman; altı kanat, her kanatta dört ön bölük, menzilli destek ve yedek. Tekil asker AI/XP yok; görsel askerler bölük durumundan çizilir. 10.000 asker / 100 bölük hâlâ ölçek hedefidir, bu kapasite için telefon performansı kanıtlanmadı.
- `core/battle.gd`: 20 Hz sabit adım; emir kuyruğu, kalıcı hat/mevzi, görev koruma, yedek devri, AI, muharebe, moral, dinçlik, temel kaynaklar ve XP. `core/terrain.gd`: arazi ve geçit yönlendirmesi. Sık olmayan plan/ikmal güncellemeleri oynanışı olay kartına dönüştürmez.
- `core/session.gd`: ENet, ev sahibi otoritesi, 2–4 oyuncu; istemci yalnız niyet gönderir. Alan/yetki/sıra/konum doğrulaması, komut hız sınırı ve maç kimliği. İstemci konum, hasar veya stok belirleyemez.
- `core/wire.gd`: 10 Hz görünür durum snapshot'ları, MTU altı 900 bayt parçalar, sıra dışı parça toplama/eski snapshot reddi. Sağlanan görünür konumlar istemcide yumuşatılır; görünmez düşmanın planı/uzmanlığı gönderilmez. Bu testler tam güvenlik denetimi değildir.
- İki rakip ordu; 3./4. oyuncu müttefik sağ kanadı devralır. Bir istemci ayrılırsa kalan müttefik veya AI yönetir; ev sahibi ayrılırsa maç biter. Ayrı kamusal sunucu, eşleştirme, yeniden bağlanma ve ev sahibi göçü uygulanmadı.
- `ui/battlefield.gd`: tek parmak seçim/kamera veya açık hat aracında çizim; iki parmak daima kamera, taslak iptali. `ui/main.gd`: ordu/kanat/bölük emirleri, seçime göre komutlar, durumlar, rapor defteri, ayrıntı, lobi ve maç sonucu. Dar alanda komut paneli dikey kayar; yatay kırpma yok.

## Doğrulanan kabul
Oyun commit'i `a0ccdcf98d9818a9640fcd4cc0c0e439e4ce0703`; GitHub Actions run `41122483114`; release `ucmak-0.4.1-8`.
- 56 çekirdek kontrolü; görev koruma/yedek, formasyon aralığı, sahte komut alanları, gizli bilgi, kaynak geçerliliği, XP istismarı, aynı seed tekrarı, üç dakika AI muharebesi, maç sonucu.
- Gerçek dört Godot/ENet süreci, üç istemci, yetkili emir kabulü/yetkisiz emir reddi ve filtrelenmiş durum.
- 480×960 / 1200×800 / 360×640 / 844×390 için 24'er UI kontrolü. Kontrol düğmesi yüksekliği çıktı pikselinde küçük dikeyde yaklaşık 45, yatay telefonda 48.75. Bu değerler donanım DPI/DP ölçümü değildir.
- CI OpenGL yazılımsal çiziminde gerçek PNG üretimi ve görüntü incelemesi. Android ARM64 debug export ve imza doğrulaması, Linux release export ve headless başlangıç kontrolü.

## Açık kabul kapıları
Gerçek Android/iOS dokunma, güvenli ekran alanı/çentik, GPU/termal/batarya ve gerçek ağ gecikmesi test edilmedi; iOS paketi yoktur. Tam maç boyunca uzak ağ/yeniden bağlanma, 100 bölüklü ölçek, denge ve tarihsel kadro kabulü açıktır. CI başarısı bunların yerine geçmez.
