# U-MAK (UÇMAK)

Mobil öncelikli gerçek zamanlı tarihsel cephe komutanlığı oyunu.

## Güncel Android deneme sürümü — Godot v0.4.2 (2026-10-30)
**Öncelikli Android hata:** Kullanıcı 0.4.1'de “Talime başla” sonrasında kilitlenme bildirdi. Bu hata gerçek Android cihazda henüz tekrar oluşturulmadı; çözülmüş kabul edilmemelidir. Linux/Xvfb üzerinde savaş çalışırken yüksek CPU çizim yükü görüldü. 0.4.2'de statik arazi bir SubViewport dokusuna önceden çiziliyor; hareketli askerler ve emirler ayrı çiziliyor. Mobilde 30 FPS sınırı, düşük ayrıntı ve sınırlandırılmış yol arama hesapları var. Görev, hat ve multiplayer simülasyonu korunmuştur.

- [Android ARM64 APK, Linux ve kaynak paketi — ucmak-0.4.2-12](https://github.com/TheOsmanYILDIRIM/U-MAK/releases/tag/ucmak-0.4.2-12)
- [GitHub Actions tam kabul/build](https://github.com/TheOsmanYILDIRIM/U-MAK/actions/runs/41126336700)
- Kod/build commit: `c39bec0bc47bed20485511b736d4f8c4d2ee83fd`, dal: `game/godot-playable-20261030`; main'e merge yapılmadı.
- 58 çekirdek testi, 4 ENet süreci, 4×24 UI ve 4×12 gerçek buton üzerinden başlangıç kontrolü geçti. Dışa aktarılmış Linux binary'sinde başlangıç ve 12 saniyelik manuel devam kontrolü yapıldı. Android APK v2/v3 imzalandı; SHA256 `af13c94596e64d1640221d1c9f5b263294f3698ce10eec167778adbeefcd994e`, 27.665.833 bayt.
- Eski v0.4.1 ile **aynı geliştirme imza sertifikası** doğrulandı; uygulamayı kaldırmadan sürüm 6 güncellemesi uygulanabilir. Kullanıcı veri ve kayıtları yedeklemeden silme.
- **Gerçek Android kurulum / dokunmatik / GPU FPS / ısınma / cihazdaki donmanın çözülmesi henüz doğrulanmadı.** Özellikle Talime başla ile giriş ve birkaç dakika komuta kullanımının cihazda denenmesi kabul kapısıdır.

### Oynama
“Talime başla” ile çevrimdışı AI savaşı. Ordu/kanat/bölük seç, Hat çiz ve Onayla; özel bölük görevi ve yedek devri. İki parmak kamerayı kontrol eder. ENet üzerinden 2–4 kişi aynı Wi-Fi/erişilebilir IP (UDP 24642) ile oynayabilir; genel internet eşleştirmesi henüz yok.

### Geliştirme
Godot 4.5.2 kaynağı `game/godot/`, test otomasyonu `.github/workflows/godot.yml`. Testler gerçek cihaz doğrulaması değildir; sonuçları ayrı kaydet. Güncel açık işler `docs/11-decisions-open.md` içinde.

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
