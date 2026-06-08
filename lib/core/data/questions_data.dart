import '../models/quiz_question.dart';

/// ─────────────────────────────────────────────────────────────
/// MEDENİ USUL HUKUKU – FİNAL SORU BANKASI
///
/// Kendi sorunu eklemek çok kolay: aşağıdaki listeye yeni bir
/// QuizQuestion(...) bloğu ekle. Alanlar:
///   id            : benzersiz kısa kod (örn. 'ispat_09')
///   category      : QuizCategory.* (renk ve etiket otomatik gelir)
///   question      : soru metni
///   options       : 4 şık (liste)
///   correctIndex  : doğru şıkkın sırası (0 = ilk şık, 3 = son şık)
///   explanation   : cevaptan sonra çıkan açıklama / madde atfı
///
/// NOT: Parasal sınırlar (senetle ispat, istinaf/temyiz kesinlik
/// sınırı) her takvim yılı başında "yeniden değerleme oranında"
/// artar. Sorular bu nedenle ilkeye dayalı yazıldı; güncel TL
/// rakamını kendi müfredatından/föyünden teyit et.
/// ─────────────────────────────────────────────────────────────
const List<QuizQuestion> kQuestions = [
  // ══════════════════════════════════════════════════════════
  //  1) İSPAT VE DELİLLER
  // ══════════════════════════════════════════════════════════
  QuizQuestion(
    id: 'ispat_01',
    category: QuizCategory.ispatDeliller,
    question:
        'Senetle ispat zorunluluğu (HMK m. 200) bakımından aşağıdakilerden hangisi doğrudur?',
    options: [
      'Tüm hukuki işlemler, miktarı ne olursa olsun senetle ispatlanmalıdır.',
      'Belirli bir parasal sınırı aşan hukuki işlemler kural olarak senetle ispatlanmalıdır.',
      'Hukuki işlemler her zaman tanıkla ispatlanabilir.',
      'Senetle ispat yalnızca ticari işlerde zorunludur.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 200: Bir hakkın doğumu, düşürülmesi vb. amacıyla yapılan ve belirli bir parasal sınırı aşan hukuki işlemlerin senetle ispatı zorunludur; bu sınırın altındaki işlemler tanıkla da ispatlanabilir.',
  ),
  QuizQuestion(
    id: 'ispat_02',
    category: QuizCategory.ispatDeliller,
    question:
        'Senetle ispat zorunluluğundaki parasal sınır nasıl belirlenir?',
    options: [
      'Sabittir, yalnızca kanun değişikliğiyle artar.',
      'Her takvim yılı başında yeniden değerleme oranında artırılır.',
      'Hâkim her dava için ayrıca takdir eder.',
      'Taraflar sözleşmeyle serbestçe belirler.',
    ],
    correctIndex: 1,
    explanation:
        'Sınır her takvim yılı başından geçerli olmak üzere önceki yıla ilişkin yeniden değerleme oranında artırılır. Güncel TL tutarını ilgili yılın oranına göre teyit et.',
  ),
  QuizQuestion(
    id: 'ispat_03',
    category: QuizCategory.ispatDeliller,
    question:
        'Senede bağlı bir iddiaya karşı ileri sürülen "senede aykırı" bir savunma, sınırın altında kalsa bile nasıl ispatlanır?',
    options: [
      'Her hâlde tanıkla ispatlanabilir.',
      'Miktarına bakılmaksızın senetle ispatlanması gerekir; tanık dinlenemez.',
      'Yalnızca yeminle ispatlanır.',
      'Hiçbir şekilde ispatlanamaz.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 201 (senede karşı tanıkla ispat yasağı): Senede bağlı her tür iddiaya karşı ileri sürülen ve senedin hüküm ve kuvvetini ortadan kaldıracak/azaltacak iddialar, miktar ne olursa olsun tanıkla ispatlanamaz.',
  ),
  QuizQuestion(
    id: 'ispat_04',
    category: QuizCategory.ispatDeliller,
    question:
        'Senetle ispat zorunluluğu bulunan bir hâlde "delil başlangıcı" varsa sonuç ne olur?',
    options: [
      'Hiçbir delil kabul edilmez.',
      'Tanık dinlenebilir.',
      'Dava reddedilir.',
      'Yalnızca bilirkişi incelemesi yapılır.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 202: Delil başlangıcı varsa tanık dinlenebilir. Delil başlangıcı; iddia edilen işlemi tamamen ispata yetmemekle birlikte onu muhtemel gösteren ve aleyhine ileri sürülen kişi (veya temsilcisi) tarafından verilmiş yazılı belgedir.',
  ),
  QuizQuestion(
    id: 'ispat_05',
    category: QuizCategory.ispatDeliller,
    question:
        'Aşağıdakilerden hangisinde senetle ispat zorunluluğuna rağmen tanık dinlenebilir?',
    options: [
      'İki tacir arasındaki yazılı sözleşmede',
      'Altsoy–üstsoy, eşler ve kardeşler arasındaki işlemlerde',
      'Resmî senede dayanan alacaklarda',
      'Noterde düzenlenen işlemlerde',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 203: Altsoy-üstsoy, eşler, kardeşler arasındaki işlemler; hukuki işlemlerde irade fesadı (hata, hile, ikrah) iddiaları; haksız fiil ve sebepsiz zenginleşme; senedin elde tutulamamasında haklı sebep gibi hâllerde tanık dinlenebilir.',
  ),
  QuizQuestion(
    id: 'ispat_06',
    category: QuizCategory.ispatDeliller,
    question:
        'Senetle ispat kuralının kamu düzeniyle ilişkisi bakımından aşağıdakilerden hangisi doğrudur?',
    options: [
      'Kamu düzenindendir; hâkim resen gözetir ve taraf vazgeçemez.',
      'Kamu düzeninden değildir; karşı taraf açıkça muvafakat ederse tanık dinlenebilir.',
      'Yalnızca davalı lehine getirilmiş bir kuraldır.',
      'Sadece istinaf aşamasında ileri sürülebilir.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 200/2: Senetle ispat zorunluluğu kamu düzeninden değildir. Karşı taraf açık muvafakat verirse (tanık dinlenmesine itiraz etmezse) sınırın üzerindeki işlemde dahi tanık dinlenebilir.',
  ),
  QuizQuestion(
    id: 'ispat_07',
    category: QuizCategory.ispatDeliller,
    question:
        'Tanıklıktan çekinme hakkı bakımından aşağıdakilerden hangisi söylenebilir?',
    options: [
      'Hiç kimse tanıklıktan çekinemez.',
      'Taraflardan birinin nişanlısı veya belirli derecedeki hısımları tanıklıktan çekinebilir.',
      'Tanıklıktan yalnızca kamu görevlileri çekinebilir.',
      'Tanıklıktan çekinme yalnızca ceza davalarında mümkündür.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 248: İki taraftan birinin nişanlısı; evlilik bağı kalmasa da eşi; belirli derecedeki kan ve kayın hısımları ile evlatlık bağı bulunanlar kişisel sebeplerle tanıklıktan çekinebilir (m. 249–250: sır ve menfaat ihlali sebepleri ayrıca düzenlenmiştir).',
  ),
  QuizQuestion(
    id: 'ispat_08',
    category: QuizCategory.ispatDeliller,
    question: 'Bilirkişiye hangi durumda başvurulamaz?',
    options: [
      'Teknik bir konunun aydınlatılması gerektiğinde',
      'Çözümü hâkimlik mesleğinin gerektirdiği genel ve hukuki bilgiyle mümkün olan konularda',
      'Hesap ve muhasebe incelemesi gerektiğinde',
      'Tıbbi bir değerlendirme gerektiğinde',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 266: Çözümü özel/teknik bilgiyi gerektiren hâllerde bilirkişiye başvurulur; ancak genel bilgi veya hukuki bilgiyle çözülebilecek konularda (hukukun uygulanması hâkime ait olduğundan) bilirkişiye başvurulamaz.',
  ),
  QuizQuestion(
    id: 'ispat_09',
    category: QuizCategory.ispatDeliller,
    question:
        'Bilirkişi raporuna karşı, raporun tebliğinden itibaren itiraz süresi ne kadardır?',
    options: [
      'Bir hafta',
      'İki hafta',
      'Bir ay',
      'On gün',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 281: Taraflar, raporun kendilerine tebliğinden itibaren iki hafta içinde itiraz edebilir; eksikliklerin tamamlanmasını, belirsizliklerin giderilmesini veya yeni bilirkişi atanmasını isteyebilirler.',
  ),
  QuizQuestion(
    id: 'ispat_10',
    category: QuizCategory.ispatDeliller,
    question: 'Hâkimin bilirkişi raporu karşısındaki durumu nedir?',
    options: [
      'Rapor kesin delildir; hâkim aynen uymak zorundadır.',
      'Rapor takdiri delildir; hâkim raporla bağlı değildir, serbestçe değerlendirir.',
      'Hâkim raporu hiç dikkate alamaz.',
      'Hâkim ancak Yargıtay onayıyla rapordan ayrılabilir.',
    ],
    correctIndex: 1,
    explanation:
        'Bilirkişi raporu takdiri delildir. Hâkim raporu serbestçe değerlendirir ve gerekçesini göstererek rapordan ayrılabilir; ayrıca bilirkişi hukuki nitelendirme yapamaz, hukukun uygulanması hâkime aittir.',
  ),

  // ══════════════════════════════════════════════════════════
  //  2) GEÇİCİ HUKUKİ KORUMALAR
  // ══════════════════════════════════════════════════════════
  QuizQuestion(
    id: 'gecici_01',
    category: QuizCategory.geciciKoruma,
    question: 'İhtiyati tedbirin konusu aşağıdakilerden hangisidir?',
    options: [
      'Para alacaklarının tahsilinin güvence altına alınması',
      'Uyuşmazlık konusu (çekişmeli) şey veya hak hakkında koruma sağlanması',
      'Borçlunun hapsen tazyiki',
      'Kesinleşmiş bir kararın icrası',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 389: İhtiyati tedbir, uyuşmazlık konusu şey/hak hakkında; mevcut durumdaki değişme nedeniyle hakka kavuşmanın zorlaşacağı/imkânsızlaşacağı ya da gecikme yüzünden ciddi zarar doğacağı hâllerde verilir. Para alacaklarının güvencesi ise ihtiyati hacizdir.',
  ),
  QuizQuestion(
    id: 'gecici_02',
    category: QuizCategory.geciciKoruma,
    question: 'İhtiyati haciz hangi tür alacaklar için istenir ve dayanağı hangi kanundur?',
    options: [
      'Çekişmeli şey için; HMK',
      'Rehinle temin edilmemiş bir para alacağı için; İcra ve İflas Kanunu',
      'Manevi tazminat için; TBK',
      'Nafaka için; TMK',
    ],
    correctIndex: 1,
    explanation:
        'İİK m. 257: İhtiyati haciz, rehinle temin edilmemiş ve vadesi gelmiş bir para borcunun alacaklısı tarafından istenir (kanunda sayılan hâllerde vadesi gelmemiş alacaklar için de mümkündür). Dayanağı İcra ve İflas Kanunu’dur.',
  ),
  QuizQuestion(
    id: 'gecici_03',
    category: QuizCategory.geciciKoruma,
    question:
        'İhtiyati tedbir ile ihtiyati haciz arasındaki temel fark aşağıdakilerden hangisidir?',
    options: [
      'İkisi de yalnızca para alacakları içindir.',
      'İhtiyati tedbir çekişmeli şey/hak için (HMK), ihtiyati haciz para alacağı için (İİK) öngörülmüştür.',
      'İhtiyati haciz dava açılmadan hiç istenemez.',
      'İhtiyati tedbir yalnızca icra dairesinden istenir.',
    ],
    correctIndex: 1,
    explanation:
        'Temel ayrım konularındadır: İhtiyati tedbir para dışındaki çekişmeli şey/hakkın korunmasına (HMK m. 389 vd.), ihtiyati haciz ise para alacağının güvenceye alınmasına (İİK m. 257 vd.) hizmet eder.',
  ),
  QuizQuestion(
    id: 'gecici_04',
    category: QuizCategory.geciciKoruma,
    question:
        'İhtiyati tedbir talep eden, talebinin haklılığı bakımından neyi yerine getirmelidir?',
    options: [
      'Haklılığını tam (kesin) olarak ispatlamalıdır.',
      'Haklılığını yaklaşık olarak ispat etmelidir.',
      'Hiçbir ispat yükü yoktur.',
      'Yalnızca yemin etmesi yeterlidir.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 390/3: İhtiyati tedbir isteyen, davanın esası yönünden kendisinin haklı olduğunu yaklaşık olarak ispat etmek zorundadır (tam ispat aranmaz).',
  ),
  QuizQuestion(
    id: 'gecici_05',
    category: QuizCategory.geciciKoruma,
    question:
        'Karşı taraf dinlenmeden verilen ihtiyati tedbir kararına itiraz süresi ne kadardır?',
    options: [
      'Bir hafta',
      'İki hafta',
      'Yedi iş günü',
      'Bir ay',
    ],
    correctIndex: 0,
    explanation:
        'HMK m. 394: Tedbir kararı yüzüne karşı verilenler tefhim/tebliğden, yokluğunda verilenler ise tedbirin uygulanmasından veya öğrenmeden itibaren bir hafta içinde itiraz edebilir.',
  ),
  QuizQuestion(
    id: 'gecici_06',
    category: QuizCategory.geciciKoruma,
    question:
        'Dava açılmadan önce ihtiyati tedbir kararı alınmışsa, esas hakkında dava ne kadar sürede açılmalıdır?',
    options: [
      'Bir hafta içinde',
      'İki hafta içinde',
      'Bir ay içinde',
      'Süre yoktur, istenildiği zaman açılabilir.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 397/1: Dava açılmadan önce verilen ihtiyati tedbirde, tedbir kararının uygulanmasını isteme tarihinden itibaren iki hafta içinde esas hakkında dava açılmazsa tedbir kendiliğinden kalkar.',
  ),
  QuizQuestion(
    id: 'gecici_07',
    category: QuizCategory.geciciKoruma,
    question:
        'İhtiyati haciz kararının uygulanmasından (infazından) sonra alacaklı, kural olarak hangi süre içinde takip talebinde bulunmalı veya dava açmalıdır?',
    options: [
      'Yedi gün içinde',
      'İki hafta içinde',
      'Bir ay içinde',
      'Üç ay içinde',
    ],
    correctIndex: 0,
    explanation:
        'İİK m. 264: İhtiyati haciz kararının infazından itibaren yedi gün içinde takip talebinde bulunulmalı (veya dava açılmalıdır); aksi hâlde ihtiyati haciz hükümsüz kalır. Ayrıca İİK m. 265’e göre borçlu da yedi gün içinde itiraz edebilir.',
  ),

  // ══════════════════════════════════════════════════════════
  //  3) KANUN YOLLARI
  // ══════════════════════════════════════════════════════════
  QuizQuestion(
    id: 'kanun_01',
    category: QuizCategory.kanunYollari,
    question:
        'İlk derece mahkemesi kararına karşı istinaf başvuru süresi, kural olarak ne kadardır?',
    options: [
      'Kararın tefhiminden itibaren bir hafta',
      'Kararın tebliğinden itibaren iki hafta',
      'Kararın tebliğinden itibaren bir ay',
      'Kararın verilmesinden itibaren on beş gün',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 345: İstinaf yoluna başvuru süresi, kararın tebliğinden (ilamın taraflara tebliği) itibaren iki haftadır.',
  ),
  QuizQuestion(
    id: 'kanun_02',
    category: QuizCategory.kanunYollari,
    question:
        'İstinaf ve temyiz mercileri bakımından aşağıdakilerden hangisi doğrudur?',
    options: [
      'İstinaf mercii Yargıtay, temyiz mercii bölge adliye mahkemesidir.',
      'İstinaf mercii bölge adliye mahkemesi (BAM), temyiz mercii Yargıtay’dır.',
      'Her iki kanun yolu da doğrudan Yargıtay’da incelenir.',
      'Her iki kanun yolu da ilk derece mahkemesinde incelenir.',
    ],
    correctIndex: 1,
    explanation:
        'İlk derece kararları bölge adliye mahkemesinde (istinaf) incelenir; BAM hukuk dairelerinin kararlarına karşı ise Yargıtay’a temyiz yoluna gidilir.',
  ),
  QuizQuestion(
    id: 'kanun_03',
    category: QuizCategory.kanunYollari,
    question: 'Temyiz başvuru süresi kural olarak ne kadardır?',
    options: [
      'Kararın tebliğinden itibaren bir hafta',
      'Kararın tebliğinden itibaren iki hafta',
      'Kararın tebliğinden itibaren bir ay',
      'Kararın tefhiminden itibaren on gün',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 361: Temyiz süresi, BAM kararının tebliğinden itibaren iki haftadır.',
  ),
  QuizQuestion(
    id: 'kanun_04',
    category: QuizCategory.kanunYollari,
    question:
        'Malvarlığına ilişkin davalarda istinaf "kesinlik sınırı" ne anlama gelir?',
    options: [
      'Bu sınırın altındaki kararlar kesindir; istinafa götürülemez.',
      'Bu sınırın altındaki kararlar doğrudan Yargıtay’da temyiz edilir.',
      'Sınır yalnızca ceza davalarında uygulanır.',
      'Sınırın üzerindeki kararlar kesindir.',
    ],
    correctIndex: 0,
    explanation:
        'HMK m. 341: Miktar veya değeri belirli bir tutarı geçmeyen malvarlığı davalarına ilişkin kararlar kesindir (istinaf edilemez). Bu sınır her yıl yeniden değerleme oranında artar; güncel tutarı teyit et.',
  ),
  QuizQuestion(
    id: 'kanun_05',
    category: QuizCategory.kanunYollari,
    question:
        'Manevi tazminat davalarında verilen kararlar bakımından istinaf yolu nasıldır?',
    options: [
      'Kesinlik sınırının altında kalırsa istinafa götürülemez.',
      'Miktarına bakılmaksızın istinaf yolu açıktır.',
      'Manevi tazminat kararları hiçbir şekilde istinaf edilemez.',
      'Yalnızca davacı istinafa başvurabilir.',
    ],
    correctIndex: 1,
    explanation:
        'Manevi tazminat davalarında dava değeri/hükmedilen miktar düşük olsa dahi, miktar gözetilmeksizin istinaf yolu açık kabul edilir (kesinlik sınırı manevi tazminat istemine uygulanmaz).',
  ),
  QuizQuestion(
    id: 'kanun_06',
    category: QuizCategory.kanunYollari,
    question:
        'Süresinde kanun yoluna başvurulmayan bir karar bakımından sonuç nedir?',
    options: [
      'Karar geçersiz olur.',
      'Karar şeklî/maddi anlamda kesinleşir ve icra edilebilir hâle gelir.',
      'Dava yeniden ilk derece mahkemesinde görülür.',
      'Karar resen Yargıtay’a gönderilir.',
    ],
    correctIndex: 1,
    explanation:
        'Kanun yolu süresi içinde başvurulmazsa veya kanun yolu kapalıysa karar kesinleşir; kesinleşen karar icra edilebilir ve kesin hüküm (res judicata) etkisi doğurur.',
  ),
  QuizQuestion(
    id: 'kanun_07',
    category: QuizCategory.kanunYollari,
    question:
        'Bölge adliye mahkemesi kararlarının temyiz edilebilirliği bakımından aşağıdakilerden hangisi doğrudur?',
    options: [
      'BAM’ın tüm kararları istisnasız temyiz edilebilir.',
      'Kanunda sayılan bazı kararlar (ör. temyiz kesinlik sınırının altında kalanlar) temyiz edilemez.',
      'BAM kararları yalnızca Anayasa Mahkemesi’nde incelenir.',
      'BAM kararları hiçbir şekilde temyiz edilemez.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 362: Miktar/değeri belirli sınırı geçmeyen davalara ilişkin kararlar ile maddede sayılan diğer kararlar temyiz edilemez (kesindir). Bu sınır da yıllık olarak yeniden değerleme oranında artar.',
  ),

  // ══════════════════════════════════════════════════════════
  //  4) DAVAYA SON VEREN TARAF İŞLEMLERİ
  // ══════════════════════════════════════════════════════════
  QuizQuestion(
    id: 'taraf_01',
    category: QuizCategory.tarafIslemleri,
    question: 'Feragat nedir?',
    options: [
      'Davalının, davacının talep sonucunu kabul etmesidir.',
      'Davacının, talep sonucundan (netice-i talepten) kısmen veya tamamen vazgeçmesidir.',
      'Tarafların karşılıklı anlaşmasıdır.',
      'Hâkimin davayı reddetmesidir.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 307: Feragat, davacının talep sonucundan kısmen veya tamamen vazgeçmesidir.',
  ),
  QuizQuestion(
    id: 'taraf_02',
    category: QuizCategory.tarafIslemleri,
    question: 'Kabul nedir?',
    options: [
      'Davacının davasından vazgeçmesidir.',
      'Davalının, davacının talep sonucuna kısmen veya tamamen muvafakat etmesidir.',
      'Tarafların uzlaşmasıdır.',
      'Mahkemenin davayı kabul etmesidir.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 308: Kabul, davacının talep sonucuna davalının kısmen veya tamamen muvafakat etmesidir.',
  ),
  QuizQuestion(
    id: 'taraf_03',
    category: QuizCategory.tarafIslemleri,
    question:
        'Feragat ve kabulün geçerliliği için karşı tarafın veya mahkemenin onayı gerekir mi?',
    options: [
      'Evet, her ikisi de karşı tarafın kabulüne bağlıdır.',
      'Hayır; feragat ve kabul tek taraflı irade beyanıyla sonuç doğurur, karşı tarafın veya mahkemenin muvafakatine gerek yoktur.',
      'Yalnızca hâkimin onayıyla geçerli olur.',
      'Yalnızca noter huzurunda yapılırsa geçerlidir.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 309/1: Feragat ve kabul, dilekçeyle veya yargılama sırasında sözlü olarak yapılır; karşı tarafın ya da mahkemenin muvafakatine bağlı değildir (tek taraflı işlemlerdir).',
  ),
  QuizQuestion(
    id: 'taraf_04',
    category: QuizCategory.tarafIslemleri,
    question: 'Feragat, kabul ve (mahkeme içi) sulhun davaya etkisi nedir?',
    options: [
      'Davayı durdurur ama sona erdirmez.',
      'Kesin hüküm gibi sonuç doğurur ve davayı sona erdirir.',
      'Yalnızca delil değeri taşır.',
      'Davanın istinafa taşınmasını sağlar.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 311: Feragat ve kabul, kesin hüküm gibi hukuki sonuç doğurur. Mahkeme içi sulh de aynı şekilde davayı sona erdirir ve kesin hüküm gibi sonuç doğurur.',
  ),
  QuizQuestion(
    id: 'taraf_05',
    category: QuizCategory.tarafIslemleri,
    question:
        'Davadan feragat eden davacının yargılama giderleri bakımından durumu nedir?',
    options: [
      'Hiçbir gider ödemez.',
      'Davayı kaybetmiş gibi yargılama giderlerini ödemekle yükümlü olur.',
      'Giderlerin tamamı davalıya yükletilir.',
      'Giderler devlet hazinesinden karşılanır.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 312: Feragat veya kabul hâlinde, feragat eden davacı ya da kabul eden davalı, davada aleyhine hüküm verilmiş gibi yargılama giderlerini ödemeye mahkûm edilir.',
  ),
  QuizQuestion(
    id: 'taraf_06',
    category: QuizCategory.tarafIslemleri,
    question:
        'Davalı, davanın açılmasına kendi davranışıyla sebep olmamış ve davacının talebini ilk duruşmada kabul etmişse yargılama giderleri bakımından sonuç nedir?',
    options: [
      'Yine de tüm giderleri öder.',
      'Yargılama giderlerini ödemeye mahkûm edilmez.',
      'Giderlerin yarısını öder.',
      'Dava reddedilir.',
    ],
    correctIndex: 1,
    explanation:
        'HMK m. 312/2: Davalı, davanın açılmasına kendi hâl ve davranışıyla sebebiyet vermemiş ve davacının iddialarını ilk duruşmada kabul etmişse yargılama giderlerini ödemeye mahkûm edilmez.',
  ),
  QuizQuestion(
    id: 'taraf_07',
    category: QuizCategory.tarafIslemleri,
    question:
        'Sulhun feragat ve kabulden ayrılan en belirgin özelliği nedir?',
    options: [
      'Sulh tek taraflı bir işlemdir.',
      'Sulh iki taraflı (karşılıklı) bir işlemdir; tarafların anlaşmasıyla kurulur.',
      'Sulh yalnızca istinaf aşamasında yapılabilir.',
      'Sulh hiçbir zaman kesin hüküm doğurmaz.',
    ],
    correctIndex: 1,
    explanation:
        'Feragat ve kabul tek taraflı işlemlerken sulh, tarafların karşılıklı anlaşmasına dayanan iki taraflı bir işlemdir (HMK m. 313 vd.). Yargılama giderleri kural olarak tarafların anlaşmasına göre; anlaşma yoksa eşit olarak paylaştırılır.',
  ),

  // ══════════════════════════════════════════════════════════
  //  5) ALTERNATİF UYUŞMAZLIK ÇÖZÜMLERİ (Dava şartı arabuluculuk)
  // ══════════════════════════════════════════════════════════
  QuizQuestion(
    id: 'arabulucu_01',
    category: QuizCategory.arabuluculuk,
    question:
        'İşçi-işveren arasındaki kanuna/sözleşmeye dayanan işçilik alacağı ve işe iade davalarında arabuluculuğun rolü nedir?',
    options: [
      'Tamamen ihtiyaridir, hiçbir zorunluluk yoktur.',
      'Arabulucuya başvurulmuş olması bir dava şartıdır.',
      'Yalnızca taraflar isterse uygulanır ve dava açmaya engel değildir.',
      'Sadece toplu iş uyuşmazlıklarında zorunludur.',
    ],
    correctIndex: 1,
    explanation:
        '7036 sayılı İş Mahkemeleri Kanunu m. 3: Kanuna, bireysel veya toplu iş sözleşmesine dayanan işçi/işveren alacağı, tazminatı ve işe iade taleplerinde arabulucuya başvurulmuş olması dava şartıdır.',
  ),
  QuizQuestion(
    id: 'arabulucu_02',
    category: QuizCategory.arabuluculuk,
    question:
        'Ticari davalarda dava şartı olan arabuluculuk hangi tür talepleri kapsar?',
    options: [
      'Tüm ticari davaları istisnasız kapsar.',
      'Konusu bir miktar paranın ödenmesi olan alacak ve tazminat taleplerini kapsar.',
      'Yalnızca şirketler hukukundan doğan davaları kapsar.',
      'Yalnızca kambiyo senetlerine ilişkin davaları kapsar.',
    ],
    correctIndex: 1,
    explanation:
        'TTK m. 5/A: Konusu bir miktar paranın ödenmesi olan alacak ve tazminat talepleri hakkında ticari davalarda, dava açılmadan önce arabulucuya başvurulmuş olması dava şartıdır.',
  ),
  QuizQuestion(
    id: 'arabulucu_03',
    category: QuizCategory.arabuluculuk,
    question:
        'Dava şartı olan arabuluculuğa hiç başvurulmadan doğrudan dava açılırsa mahkeme ne yapar?',
    options: [
      'Davayı esastan inceleyip karar verir.',
      'Herhangi bir işlem yapmaksızın, dava şartı yokluğundan davanın usulden reddine karar verir.',
      'Tarafları uzlaşmaya zorlar ve davayı bekletir.',
      'Davayı görevsizlikten reddeder.',
    ],
    correctIndex: 1,
    explanation:
        '7036 m. 3/2 (ve TTK m. 5/A atfı): Arabulucuya başvurulmadan dava açıldığının anlaşılması hâlinde, herhangi bir işlem yapılmaksızın dava, dava şartı yokluğu sebebiyle usulden reddedilir. Bu, konunun en kritik final bilgisidir.',
  ),
  QuizQuestion(
    id: 'arabulucu_04',
    category: QuizCategory.arabuluculuk,
    question:
        'Arabuluculuk dava şartı olan bir davada, anlaşmaya varılamadığına ilişkin son tutanak dava dilekçesine eklenmemişse mahkeme önce ne yapar?',
    options: [
      'Doğrudan davayı esastan reddeder.',
      'Davacıya, son tutanağın bir haftalık kesin süre içinde sunulması için ihtarda bulunur; sunulmazsa dava usulden reddedilir.',
      'Tutanağı resen arabuluculuk bürosundan ister.',
      'Davayı hiçbir uyarı yapmadan görevsizlikle reddeder.',
    ],
    correctIndex: 1,
    explanation:
        '7036 m. 3/2: Arabulucuya başvurulmuş ancak son tutanak eklenmemişse, mahkeme davacıya bir haftalık kesin süre verir; bu süre içinde sunulmazsa dava dilekçesi karşı tarafa tebliğe çıkarılmadan dava usulden reddedilir. (Hiç başvurulmamışsa süre verilmeden doğrudan reddedilir.)',
  ),
  QuizQuestion(
    id: 'arabulucu_05',
    category: QuizCategory.arabuluculuk,
    question:
        'Aşağıdakilerden hangisi iş hukukunda dava şartı arabuluculuğun kapsamı DIŞINDADIR?',
    options: [
      'Kıdem tazminatı talebi',
      'Fazla mesai ücreti alacağı',
      'İş kazası veya meslek hastalığından kaynaklanan maddi-manevi tazminat davaları',
      'İhbar tazminatı talebi',
    ],
    correctIndex: 2,
    explanation:
        '7036 m. 3: İş kazası veya meslek hastalığından kaynaklanan maddi-manevi tazminat davaları ile bunlarla ilgili tespit, itiraz ve rücu davaları dava şartı arabuluculuğun kapsamı dışındadır.',
  ),
  QuizQuestion(
    id: 'arabulucu_06',
    category: QuizCategory.arabuluculuk,
    question:
        'Dava şartı arabuluculukta arabulucu, başvuru tarihinden itibaren süreci kural olarak ne kadar sürede tamamlamalıdır?',
    options: [
      'Üç hafta içinde; zorunlu hâllerde en fazla bir hafta uzatılabilir.',
      'İki ay içinde; uzatma mümkün değildir.',
      'Bir yıl içinde.',
      'Süre öngörülmemiştir.',
    ],
    correctIndex: 0,
    explanation:
        'İş ve ticari uyuşmazlıklarda arabulucu, görevlendirildiği tarihten itibaren süreci üç hafta içinde sonuçlandırır; bu süre zorunlu hâllerde arabulucu tarafından en fazla bir hafta uzatılabilir.',
  ),
];
