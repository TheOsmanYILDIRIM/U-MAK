# UÇMAK — kararlar ve açık konular

## Güncel durum — 2026-10-30 / Godot oynanabilir alfa 0.4.1
**Kullanıcı hedefi:** HTML komuta taslağını Godot'a geçirmek, build/testleri GitHub'da yapmak ve oynanabilir çıktıya ulaşmak. Motor artık Godot'tur; eski motor-kararsızlığı kayıtları tarihsel durumdur. Uzun vadeli tasarımın tamamı uygulanmış sayılmaz.

**Konum:** `TheOsmanYILDIRIM/U-MAK`, yetkili çalışma dalı `game/godot-playable-20261030`, kaynak `game/godot/`, CI `.github/workflows/godot.yml`. Main'e merge/force yapılmadı. Mevcut `README.md`, bu belge ve ilgili konu belgeleri kanoniktir; yeni TASKS/SESSION_HANDOFF veya mükerrer Beyin görevi oluşturulmadı.

### Son doğrulanan oyun ve teslim
- Oyun commit'i: `a0ccdcf98d9818a9640fcd4cc0c0e439e4ce0703`.
- CI: https://github.com/TheOsmanYILDIRIM/U-MAK/actions/runs/41122483114
- Release: https://github.com/TheOsmanYILDIRIM/U-MAK/releases/tag/ucmak-0.4.1-8
- Godot 4.5.2; Android ARM64 debug APK, native Linux release, source ZIP, dört ekran PNG'si, `acceptance.json` ve SHA256SUMS mevcut.
- APK 27,661,586 bayt; SHA-256 `618da48ac5fc847b0b19f5624bbe7df233df72370dca184a0eb4df1fe0a885be`.
- Linux ZIP SHA-256 `b9cb66c0ffc40b5b790fb4252cb4b3d0fb109df6f7a72d9fe872903ae98ddd44`.
- Kaynak ZIP SHA-256 `eb06b2deb21918cfbd66b225b028b195568c9dd14fc82b46f7fe1de184363bd7`.
- CI build artifact `13008862918` ve kabul artifact `13009181810` indirildi, açıldı, CRC ve SHA-256 denetlendi. APK içindeki native ARM64 kitaplıkları kontrol edildi; kaynak ZIP son dokunmatik düzeltmeyi içeriyor. Gizli anahtar/kullanıcı verisi kaynak pakete eklenmedi.

### Tamamlanan oynanabilir çekirdek
- 36 bölük, iki ordu, AI talimi, 10 dakikalık maç/zafer-beraberlik-sonuç ve yeniden oynama akışı.
- Kalıcı hat planı, otomatik dağıtım, fiziksel yedek devri, özel görevi koruma, geri çağırma; ordu seçimiyle kanat aralıklarını bozmadan ilerleme. Sıkı/dengeli/serbest inisiyatif ve üç komutan profili prototipi.
- Piyade/mızraklı/okçu/süvari prototip rolleri, menzilli ve yakın muharebe, moral/çözülme, dinçlik, kayıplar ve yaralılar. Bunlar henüz kaynaklı 1402 kadrosu değildir.
- Fiziksel kuyu/nehir kıyısı seçimi, su/erzak tüketimi, kampta basit bakım; geçit/köprüye rota, orman/tepe etkisi ve basit yağmur döngüsü. Tam akış/ikmal ağı değildir.
- Savaş sisiyle filtrelenmiş görünür bilgi, son görülen konum, kaynak/zaman gösteren rapor defteri ve rapordan konuma gitme.
- 10 uzmanlık alanı korunuyor. Muharebe, yeni keşif teması, gerçek ikmal ve bakım faaliyetleri XP üretir; bütün uzmanlıkların nihai eylem/denge kapsamı henüz tamamlanmadı.
- Doğrudan IP/ENet üzerinden 2–4 oyuncu; tek otorite, görev sahipliği, filtreli snapshot, istemci ayrılınca müttefik/AI devri. İki taraflı takım düzeni; serbest herkes-herkese modu yok.

### Doğrulama kanıtı
- GitHub çekirdek: **56 geçti / 0 başarısız**; aynı seed tekrarı, üç dakikalık AI muharebesi, fiziksel geçit rotası, kaynak ve görev regresyonları dahil.
- Ağ: **4 gerçek Godot/ENet süreci**, 3 istemci; kabul edilen 3 yetkili emir, reddedilen 3 yetkisiz emir; snapshot parçaları en çok 900 bayt.
- UI: **24 × 4 = 96 kontrol geçti**; 480×960, 1200×800, 360×640, 844×390. Pinch iptali, kamera, hat önizlemesi/onayı, ordu seçimi, raporlar, tek bölük panelinin kaydırılması ve 10 uzmanlığın ayrıntısı dahil.
- Önceki build 6 görüntüsünde yatay kontrol ölçeği küçük bulundu; kare taban viewport ve kaydırılabilir panel ile düzeltildi. Yeni CI'da ana kontrol yüksekliği küçük dikeyde ~45, yatay telefonda 48.75 çıktı pikseli. Gerçek telefon DPI ölçümü değildir.
- CI Godot PNG'leri açıldı; küçük dikey ve yatay telefon görünümü incelendi. Görseller yazılımsal OpenGL çıktısıdır, telefon ekran kaydı değildir.
- Android export tamamlandı; v2/v3 APK imzası doğrulandı. Linux export headless başlangıç kontrolü geçti. Geliştirme imzası önbellekle korunuyor; mağaza imzası değildir. Önbellek kaybında eski kurulumun verisini silmeden önce yedek gerekir.

### Açık işler / sonraki kabul
1. **Cihaz kabulü:** gerçek Android'de kurulum, açılış, pinch/hat/bölük seçimi, çentik/güvenli alan, 10 dakikalık oyun ve FPS/termal/batarya. Bu oturumda fiziksel cihaz erişimi yok; yapılmış sayma.
2. **Gerçek çok cihazlı ağ:** aynı Wi-Fi'da 2 ve 4 cihaz, bağlantı kaybı/geri dönüş, gecikme ve uzun maç. Dört masaüstü süreç testi bunun yerine geçmez. Eşleştirme, oda kodu, hesap, yeniden bağlanma ve ev sahibi göçü açık.
3. **Sefer döngüsü:** puanlı hazırlık/deneyimli asker sınırı, kalıcı birlik geçmişi/kayıt, takviye ve sonraki sefer. Kabul: kayıt geri açıldığında personel, donanım ve XP tutarlı olmalı.
4. **Tasarım kapsamı:** görünmeyen casus görevleri, tepkisel yerel AI, konvoy/ikmal ağı, tam sağlık/çevre/akış ve mevsim; her biri ayrı mekanik kabulüyle eklenmeli. Hiçbiri onaylı kapsamdan silinmedi.
5. **İçerik/denge/ölçek:** kaynaklı 1402 kadrosu, kalan komutan profilleri, bütün uzmanlıkların anlamlı görevleri, 100 bölüklü yük ve maç dengesi. Geçici rol/AI şablonlarını tarihsel kanıt veya nihai tasarım sayma.

**Devam kuralı:** tamamlanan komuta çekirdeğini yeniden yazma. Önce dal HEAD'i, açık PR, CI ve bu kayıt doğrulanır. Sonraki kod değişikliğinde regresyonlar korunur; build kaynak commit'i ile belge commit'i ayrı belirtilir. Geçici sohbet dosyaları yerine repo/release kullanılır.

---
# Tasarım kararları ve v0.3 geçmişi — tarihsel kayıt
Aşağıdaki v0.3 test/motor/CI ifadeleri o teslim tarihindeki durumu anlatır; güncel uygulama ve açık kapılar yukarıdadır.

## Kesinleşen tasarım yönü
- Mobil öncelikli, gerçek zamanlı tarihi sefer ve cephe komutanlığı; tekil asker seçimi, şehir/teknoloji geliştirmesi ve devlet yönetimi yok.
- Bölük en küçük mantıksal birim: ~100 referans; 30–150 esnek aralık önerisi henüz nihai değil. Görsel sprite sayısı asker sayısı değildir. Başkomutan → kanat/kol → ara grup → yüzbaşı/bölük hiyerarşisi; 1402'de dönemsel unvanlar araştırılacak.
- Tarihi birlik kökü + donanım varyantı + görev uzmanlığı + güncel fiziksel/psikolojik durum + komutan ayrı. İlk dönem 1402, ilk içerik Osmanlı, sonra Timurlular; medeniyetler zamanla eklenen paketler.
- Alt uzmanlık ağaçları **yok**. Ana uzmanlıklar eylem XP'siyle gelişir; puanlar 2–3 ilgili ana uzmanlığa küçük paylarla dağıtılabilir, seviyeler arasında doğrudan etki ağı kurulmaz.
- Moral, cesaret, disiplin, yorgunluk, komutanın kişiliği/yeteneği, emir iletimi ve güven kritik. Komutan emri beceremeyebilir, reddetmeyip geciktirebilir veya yanlış yorumlayabilir.
- Hava, mevsim, gece ve arazi görüş, hareket, su, ikmal, ateş ve sağlıkla somut bağlantılıdır.
- Su **somut seçilebilir kaynak**: kuyu veya nehirden oyuncu su alma emri verir. Kuyu sınırlı erişimli düğüm; nehir akış yönü olan segment grafiği. Casusla kuyu güvenliğinin bozulması, nehrin yukarısındaki müdahale veya akışın mühendislikle kesilmesi yalnız şartları sağlanırsa mümkündür. Önlem: koruma, keşif, alternatif kaynak, taşıma. Gerçek zehirleme yöntemleri tanımlanmaz.
- Sağlık/hastalık nedensel olarak su güvenliği, hijyen, yaralanma, açlık ve müdahalelerden etkilenir; keyfi olay üretimi temel değil.
- Bilgi savaşı: keşif/ajan/ulak raporu, yanlış bilgi, sahte kuvvet, keşif gecikmesi, karşı istihbarat, sahte ricat ve pusu.
- Yerel aktörler sade: köy, göçer, eşkıya ve rehber; stratejik erzak, güvenlik ve istihbarat ilişkileri; geniş siyasi simülasyon yok.
- Hazırlık puanı ve deneyimli asker limiti; savaş sırasında ve sonrasında uzmanlık/komutan gelişimi, hayatta kalan personel ve takviye etkisi.
- Taktikler yeterli birlik, araç, arazi, zaman, istihbarat, komutan, disiplin gibi koşullara bağlıdır. Yüksek riskli komuta hedefi baskını başarısız olabilir; kesin sonuç yok.
## Tarihsel araştırma bekleyen
1402 Osmanlı: yeniçeri, azeb, yaya/müsellem, sipahi, cebelü, akıncı, kapıkulu atlıları, müttefik kuvvetler gibi **adaylar**. Yatağanlı yeniçeri ve deli süvarisini bu tarih için doğrulanmış kabul etme. Alt görev varyantlarını bağımsız tarihsel ocak gibi sunma. Kaynaklı katalog henüz tamamlanmadı.
## Açık iş ve doğrulama
- Tarihsel birlik/kadro/silah ve dönemin teşkilat kaynak taraması.
- Uzmanlık alanlarının son listesi, XP payları, komutan davranışları ve sağlık modeli.
- Su ve akış simülasyonu, çevre/maliyet/lojistik dengesi; şehir/nehir ilişkileri.
- Savaş öncesi maliyetler, savaş sonrası ilerleme, yerel aktör davranışları.
- Üretim motoru seçimi, GitHub build/test hattı ve gerçek mobil cihaz doğrulaması **açık**. Yerel HTML komuta prototipinin sınırlı kabul kanıtları aşağıdadır; bunlar tam oyun veya multiplayer kabulü değildir.
## Belge indeksi
README.md üzerindeki docs/01–11 listesi kanoniktir. Kararları ilgili belgeye işle; burada yalnız kısa genel görünüm tut. Yeni mükerrer kayıt oluşturma.

## 2026-10-30 — Kullanıcı onaylı sekiz sadeleştirme kararı
1. **10 ana uzmanlık korunuyor:** keşif, hücum, savunma, manevra, baskın, gizlilik, menzilli savaş, kuşatma, ikmal, sağlık. Alt uzmanlık yok.
2. **Komutan kişilik çeşitliliği korunuyor:** mevcut karakter profilleri sadeleştirilerek kaldırılmayacak.
3. **Sağlık/sıhhiye sadeleştiriliyor:** ayrı asker başına tedavi yok; bölük düzeyinde hasta, yaralı, kapasite; sağlık XP kalır.
4. **Casuslar sadeleştiriliyor ve ekranda görünmüyor:** görev/rapor/karşı istihbarat var, görünür casus sprite veya bireysel AI yok. Görünür keşif birlikleri ayrı.
5. **Yerel gruplar sadeleştiriliyor:** köy, göçer, eşkıya başlangıçta rastgele/seed kontrollü olabilir ve çevredeki ordulara AI ile tepki verir; statik etkileşim penceresine indirgenmez.
6. **Görsel asker çeşitliliği korunuyor:** tekil AI olmadan sprite/görsel durum farklılaşır.
7. **Somut kuyu, nehir, akış ve çevre simülasyonu korunuyor.**
8. **Oyuncu sayısı sadeleştiriliyor:** ilk kapsam 2–4 gerçek oyuncu, daha fazlası ayrı sonraki hedef.

## Önceki önerilerle çelişkiler ve çözümler
- '10 uzmanlığı 6–8'e indir' önerisi reddedildi; 10 kalıyor.
- 'Komutan karakterlerini 3–4 eğilime indir' önerisi reddedildi; özgün karakter çeşitliliği kalıyor.
- Sıhhiye sadeleştirme ile sağlık uzmanlığı korunması farklı katmanlardır, çelişmez.
- Casusların görünmeyen görev modeli ile ana haritada görünür keşif birlikleri ayrıdır.
- Başlangıçtaki rastgele yerel aktör dağılımı, karşılaşmadan sonraki nedensel AI tepkilerinin rastgele olmasını gerektirmez.
- İlk 2–4 oyuncu ile gelecekte 4+ oyuncu hedefi farklı aşamalardır.

## Prototip öncesi ana oynanış tasarımı
1. Dokunmatik seçim: dokun=bölük; üst komutan simgesi=kanat; uzun bas/sürükle=çoklu seçim önerisi. v0.3'te serbest sürükleme kamera içindir, çoklu serbest seçim uygulanmadı.
2. Hat aracı: kanat seç, savunma/taarruz çizgisini iki uçtan çiz, yönü/hattın önünü göster; alt bölükler otomatik paylaştırılır. Hattın arazide geçerliliği doğrulanır.
3. Hedef aracı: tek bölük seç, haritadaki düşman hattına/konuma dokun, 'hat yar/hücum/koru/geri çekil'; üst planı ezdiğinde bilgi ver. Emrin alındı/yolda/uygulandı/başarısız durumu açık.
4. Sürekli HUD: haritada moral, dinçlik, ikmal, iletişim ikonları; dokununca nedenler ve ayrıntılı bilgi. Sağda keşif/casus/ulak/söylenti mesajları, oyuncu yorumlar.
5. Hedef kabul sahnesi: iki oyuncu, iki kanat, bir nehir, bir kuyu, geçit ve keşif raporu; biri kanat hattı çizerken tek bölüğe gedik açtırır. Aynı simülasyonda gerçek zamanlı emir ve karşı emirler. v0.3 bunun çevrimdışı komuta alt kümesidir, bu multiplayer sahnesinin tamamlandığı anlamına gelmez.
6. Kabul hedefleri: tekil asker seçimi olmadan kanat ve bölük emirleri; kısa dokunmatik işlem; perspektife bağlı raporlar; düşman saklı bilgisinin sızmaması; istemciler arasında tutarlılık. Son iki ağ/bilgi güvenliği kabulü henüz test edilmedi.

## 2026-10-30 — Cephe Laboratuvarı v0.3 / yerel prototip kanıtı
**Kapsam:** Kullanıcının mobil HTML demoyu yeniden tasarlama isteği üzerine 18 dost + 18 düşman bölüklü çevrimdışı komuta prototipi üretildi. Önceki v0.2 dosyası korunuyor. Bu kayıt üretim oyun motoru kararı veya sekiz onaylı mekanik kararında değişiklik değildir.

### Çalışan komuta modeli
- Kalıcı kanat hattı, bağımsız bölük görevi ve fiziksel yedek ayrı durumlar. Hat değiştirmek veya kanadı durdurmak özel bölük görevini silmez.
- Sabit mevzi kimlikleri gereksiz yer değişimini önler. Ayrılan veya morali çözülen bölüğün mevzisini hazır yedek devralır; yer değişimi gerçek hareketle olur. Geri çağrılan bölük uygun boş yere/yedeğe katılır, doldurulmuş mevziyi zorla geri almaz.
- Hat çizimi ve kulpla düzenleme önce önizlenir, sonra onaylanır. Çok kısa, aşırı uzun, nehir yatağında veya kendi üzerinden geçen hatlar reddedilir. İlerle emri hattı bütün destek düzeniyle taşır; geride kalma ve temas ilerleyişi etkiler.
- Emir sıra numarası ve ayrı plan/inisiyatif/yön kanalları, geciken eski planın yeni emri ezmesini engeller. Cephe yönü çevrilebilir. Kişilik ve yetki düzeyi yerel temas mesafesini etkiler.
- Düşman AI zayıf kanadı yeniden değerlendirir, süvariyle açılır, moral durumuna göre geri mevzi arar. Birlikler nehirden keyfi geçmez; köprü ve sığ geçitlere rota bulur. Menzilli/yakın muharebe, kayıp, moral, dinçlik ve çözülme çalışır.
- Tek parmak normalde kamera, açık hat aracında çizim. İki parmak her zaman kamera; yarım çizimi iptal eder. Yakınlaştırma odağı korunur; pointercancel ve parmakları ayrı kaldırma yanlış emir üretmez.

### Kanıt ve açık kapılar
- Node üzerinde 20 çekirdek testi geçti; görev koruma, yedek devri, geri çağırma, emir sırası, deterministik simülasyon, üç dakikalık kararlılık ve geçiş rotaları dahil.
- Masaüstü Chromium dokunma emülasyonunda 21 kabul kontrolü geçti; 390×844, 844×390, 360×640, 1280×800. JS çalışma hatası ve dış ağ isteği gözlenmedi. Üretilen ekran görüntüleri açılıp incelendi.
- Bu ortamda file:// gezinmesi tarayıcı politikası tarafından engellendi; doğrulama, aynı HTML baytlarının set_content ile işlenmesiyle yapıldı. Gerçek Android/iOS dosya açma, GPU/termal performans veya Safari doğrulaması değildir.
- ES Modules kaynakları tek HTML'ye paketlendi; yeniden build aynı baytları üretti. Kaynak ZIP açıldı, CRC ve dosya hashleri doğrulandı; ZIP'ten çıkarılan kaynak yeniden aynı HTML'yi üretti.
- **GitHub Actions çalıştırılmadı.** İncelenen repo HEAD'inde workflow yoktu; yeni kod/CI klasörü oluşturulmadı. HTML ve kaynaklar sohbet teslimidir, repoda uygulama kodu varmış gibi değerlendirilmemeli.
- Multiplayer, savaş sisi, tam ikmal/sağlık, hava/mevsim ve kaynaklı 1402 kadrosu bu demoda uygulanmadı. Bunlar onaylı oyun kapsamından çıkarılmadı.

### Teslim kimlikleri ve devam
- HTML: `Ucmak_Cephe_Laboratuvari_v0.3.html` — 86332 bayt; SHA-256 `b1477a409ea0246829172e8826aff387d121cc2594c643f8578ae6b1b36262eb`.
- Kaynak/test paketi: `Ucmak_Cephe_Laboratuvari_v0.3_Kaynak.zip` — SHA-256 `227af4766e29196761dd545afc6df9a03fec3113188c1fbb7d557d67e53be11e`.
- Sonraki hedef: gerçek telefonda hat çizme/iki parmak/kanat taşıma/özel görev-yedek davranışını kullanıcıyla değerlendirmek; ardından kaynak yerleşimi ve GitHub CI kabulünü tamamlamak. Yeni sohbette geçici container dosyalarını varsayma; kaynak ZIP veya kalıcılaştırılmış kaynak gerçekten açılmalı.
