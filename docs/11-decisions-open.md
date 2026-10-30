# UÇMAK — kararlar ve açık konular (2026-10-30)
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
- Teknik motor seçimi, prototip, gerçek mobil performans ve görsel doğrulama **yapılmadı**.
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

## Sonraki ana oynanış tasarımı (kod yok)
1. Dokunmatik seçim: dokun=bölük; üst komutan simgesi=kanat; uzun bas/sürükle=çoklu seçim.
2. Hat aracı: kanat seç, savunma/taarruz çizgisini iki uçtan çiz, yönü/hattın önünü göster; alt bölükler otomatik paylaştırılır. Hattın arazide geçerliliği doğrulanır.
3. Hedef aracı: tek bölük seç, haritadaki düşman hattına/konuma dokun, 'hat yar/hücum/koru/geri çekil'; üst planı ezdiğinde bilgi ver. Emrin alındı/yolda/uygulandı/başarısız durumu açık.
4. Sürekli HUD: haritada moral, dinçlik, ikmal, iletişim ikonları; dokununca nedenler ve ayrıntılı bilgi. Sağda keşif/casus/ulak/söylenti mesajları, oyuncu yorumlar.
5. İlk tasarım test sahnesi: iki oyuncu, iki kanat, bir nehir, bir kuyu, geçit ve keşif raporu; biri kanat hattı çizerken tek bölüğe gedik açtırır. Aynı simülasyonda gerçek zamanlı emir ve karşı emirler.
6. Kabul hedefleri (henüz test değil): tekil asker seçimi olmadan kanat ve bölük emirleri verilebilir; dokunmatik işlem kısa; raporlar seçili perspektife bağlı; düşman saklı bilgisi sızmaz; aynı dünya durumu bütün istemcilere tutarlı ulaşır.
