# U-MAK (UÇMAK)

Mobil öncelikli, gerçek zamanlı tarihsel sefer ve cephe komutanlığı strateji oyunu.

## Güncel çalışan sürüm — Godot 0.4.1 alfa

**Godot 4.5.2 tabanlı yerel oyun** `game/godot/` altında; HTML sarmalayıcı değildir. Çalışma dalı `game/godot-playable-20261030`. Main'e otomatik birleştirme yapılmadı.

- [Android ARM64 APK, Linux, kaynak ve ekran görüntüleri](https://github.com/TheOsmanYILDIRIM/U-MAK/releases/tag/ucmak-0.4.1-8)
- [GitHub Actions kabul / derleme koşusu](https://github.com/TheOsmanYILDIRIM/U-MAK/actions/runs/41122483114)
- Doğrulanan oyun commit'i: `a0ccdcf98d9818a9640fcd4cc0c0e439e4ce0703`.

### Oynama
Android APK'yi kurup **Talime başla** ile AI rakibe karşı oynayın. Kanadı seçip **Hat çiz** ile çizimi oluşturun ve onaylayın. **Ordu → İlerle** kanat aralıklarını koruyarak toplu hareket ettirir. Bölüğe dokunarak hücum, keşif, mevzi, su alma veya toparlanma görevi verin; **Geri çağır** ile kanada döndürün. İki parmak kamera yakınlaştırma/kaydırma içindir. R yedeği, altın nokta özel görevi gösterir.

Çok oyunculu: aynı build'i kullanan 2–4 oyuncu, aynı Wi-Fi veya erişilebilir sunucu IP'si üzerinden ENet/UDP 24642 ile bağlanır. Bir oyuncu **Oda kur**, diğerleri gösterilen IP ile **Odaya katıl** seçer. İlk iki oyuncu rakip orduları, üçüncü/dördüncü oyuncular müttefik sağ kanatları yönetir. İnternet eşleştirme/oda kodu, yeniden bağlanma ve ev sahibi göçü henüz yoktur.

### Doğrulama
GitHub üzerinde **56 çekirdek testi**, **4 gerçek ENet süreci**, **4 çözünürlükte 24'er arayüz kontrolü (96)** geçti. 480×960, 1200×800, 360×640, 844×390 gerçek Godot ekran görüntüleri üretildi; yatay telefon ve küçük dikey ekran açılarak incelendi. Android APK imzası doğrulandı, Linux çıktısı headless başlatıldı. İndirilen build/kabul ZIP'lerinin CRC ve SHA-256 değerleri ile APK/Linux/kaynak hashleri doğrulandı.

**Gerçek telefon kurulumu, GPU/termal FPS ve mobil ağ testi yapılmadı.** CI yazılımsal çizim ve masaüstü dokunma olaylarını sınar. APK geliştirme anahtarıyla imzalıdır; mağaza üretim imzası değildir. CI anahtar önbelleği kaybolursa önceki kurulumla imza farklılaşabilir; kullanıcı kaydını silmeden yedek alınmalıdır.

### Geliştirme
Godot 4.5.2 ile `game/godot/project.godot` açılır. GitHub kabul ve dışa aktarımı `.github/workflows/godot.yml` yürütür; çekirdek/ağ/UI test sürücüsü `game/godot/tests/ci.py` içindedir. Simülasyon, ağ ve arayüz ayrı modüllerdir.

Bu bir oynanabilir komuta/muharebe alfasıdır; bütün sefer oyunu tamamlanmış değildir. Tam ikmal ağı, casuslar, yerel AI toplulukları, savaş öncesi bütçe, kalıcı gelişim, tam mevsim/su akışı ve kaynaklı 1402 kadrosu açık kapsamdadır. Devam ve kabul kapıları `docs/11-decisions-open.md` içinde tutulur.

## Tasarım belgeleri
- `docs/01-vision.md` — oyun kapsamı ve döngü
- `docs/02-command-units.md` — birlik ve komuta modeli
- `docs/03-skills-progression.md` — uzmanlık ve tecrübe
- `docs/04-morale-commanders.md` — psikoloji ve komutanlar
- `docs/05-terrain-weather.md` — arazi, zaman ve mevsim
- `docs/06-supply-water-health.md` — somut ikmal ve su sistemi
- `docs/07-intelligence-tactics.md` — istihbarat ve koşullu taktikler
- `docs/08-historical-roster-1402.md` — tarihsel birlik adayları
- `docs/09-preparation-local-actors.md` — hazırlık, yerel aktörler
- `docs/10-mobile-simulation.md` — uygulanan mimari ve sınırları
- `docs/11-decisions-open.md` — kararlar, doğrulama kanıtları ve açık işler
