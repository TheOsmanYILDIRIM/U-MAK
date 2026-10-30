# Somut ikmal, su kaynakları ve sağlık — tasarım v0.2

## İlke
Su, erzak, yem ve mühimmat gerçek harita kaynakları/stoklarıdır. Genel 'susuzluk debuff' düğmesi yok: birlik seçili kaynaktan su alır, taşır, tüketir; ulaşamadığında susuzluk oluşur. Olaylar nedensel simülasyondan çıkar.

## Seçilebilir su kaynakları
- **Kuyu:** Haritada tekil kaynak, sınırlı çekim kapasitesi, stok/yüzey erişimi, nöbet, kontrol, bekleme/kuyruk ve bakım. Bir bölüğe 'şu kuyudan doldur' emri verilir. Kuşatma, erişim kesme ve kuyu kirlenmesi somut durumlar.
- **Nehir:** Akış yönü tanımlı bağlı segmentler, geçiş/kıyı erişimi, mevsimsel debi, su alma noktaları. Birlik bir nehir kıyısı noktasından doldurmayı seçer. Yukarı akışta kaynakla ilgili değişiklik aşağı akıştaki segmentleri etkileyebilir; yayılım ve seyreltme detayları henüz modellenmedi.
- **Pınar/göl/sarnıç:** Gelecekte eklenebilir harita kaynakları; özellikleri ayrı olacak.
- **Taşınan su:** Depo, kırba, araba/katır kapasitesi; daha çok taşıma daha fazla ağırlık, personel, yem veya düşük hız demek. Kaynak uzaksa ikmal hattı ve konvoy ihtiyacı doğar.

## Düşman eylemleri ve karşı hamle
- Oyuncu kuyu, nehir kıyısı, geçit ve su taşıyan konvoyu ele geçirebilir ya da koruyabilir.
- Casus/sabotajcı aracılığıyla kuyu güvenliği tehdit edilebilir. Ceset veya atıkla kirlenme, oyun içinde yalnızca kaynak bütünlüğü/güvenlik durumu olarak soyutlanır; gerçek dünyada zehir üretme veya yayma prosedürü yoktur.
- Nehrin **yukarı akışındaki** müdahaleler, aşağı akıştaki su erişimi/güvenilirliğini etkileyebilir. Barajlama/yatak değişikliği gibi mühendislik hamleleri, *haritadaki yapılabilirlik, ekipman, zaman, iş gücü, kontrol ve debi* şartlarına bağlıdır. Bir anda bütün nehri durdurma yok.
- Karşı seçenekler: alternatif kaynak seçmek, kuyu/nehir nöbeti, keşif, su taşıma, kaynak güvenliği kontrolü, geri çekilme veya akış yukarısını kontrol etmek.
- Kaynağın hangi tarafça kontrol edildiği, son görülen durum ve gerçek güvenliği ayrı tutulur. Bilgi savaşı geçerli.

## Sağlık
- Kaynağın güvenilirliği, yetersiz su, bozuk gıda, kamp hijyeni, yaralıların bakımı ve kalabalıklık birliğin riskini oluşturur; varsayılan keyfi hastalık zarları yok.
- Kirlenme her askerin otomatik veya anında hastalanması demek değildir; maruziyet ve zaman gerektirir. Sonuçlar deterministik eşik/akümülasyon veya sınırlandırılmış belirsizlikle test edilecek.
- Bölük düzeyinde hasta/yaralı sayısı, görev yapabilir mevcudu, tedavi kapasitesi ve tahliye yükü saklanır; bireysel sağlık kaydı tutulmaz.
- Sıhhiye ve tahliye birlikleri, malzeme ve personel kullanır; yaralılar hız ve ikmal maliyeti yaratır.

## Mobil tasarım
Nehir: segment/akış grafiği; kuyu: kaynak düğümü; bölük: su stoku ve ihtiyaç. Su hareketi ve sağlık sabit kare başına asker başına değil, olay veya seyrek zaman adımıyla güncellenir. Haritada kaynak seçimi ve emir arayüzü açıkça görünür.

## Açık kararlar
Debi ve iklim katsayıları, kirlenme modeli, su alma hızları, erişim/kapasite, inşaat süreleri, kaynak tespiti ve karşı tedbir maliyetleri; tarihsel doğrulama ve oynanış dengesi gerektirir.
