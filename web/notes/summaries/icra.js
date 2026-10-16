'use strict';
/*
 * İcra Hukuku şema özeti. Sayfa genişliği sabittir (820 birim içerik sütunu);
 * bu dosyadaki metin değişirse sayfa yüksekliği değişir ve kullanıcının
 * notları kayabilir. Büyük değişikliklerde `version` artırılır.
 *
 * Renkler: .daire İcra Dairesi · .mah İcra Mahkemesi · .gen Genel Mahkeme
 *          .borclu borçlunun / ilgilinin işlemi · .q karar noktası
 */
window.hukukNotesRegister({
  id: 'icra',
  title: 'İcra Hukuku',
  version: 1,
  html: `
<div class="cover">
  <div class="kicker">Şema özet · 2004 sayılı İcra ve İflas Kanunu</div>
  <h1>İcra Hukuku</h1>
  <div class="sub">Borç ödenmediğinde alacaklının yürüteceği icra takibi:<br>başvurudan paraya çevirmeye, özel takip yollarından icra suçlarına</div>
  <div class="legend">
    <span><i class="daire"></i>İcra Dairesi</span>
    <span><i class="mah"></i>İcra Mahkemesi</span>
    <span><i class="gen"></i>Genel Mahkeme</span>
    <span><i class="borclu"></i>Borçlunun / ilgilinin işlemi</span>
    <span><i class="q"></i>Karar noktası</span>
    <span><b class="t">7 gün</b> Süre</span>
    <span><i class="m">62</i> İİK maddesi</span>
  </div>
</div>

<div class="part"><small>BİRİNCİ BÖLÜM</small><div>Genel esaslar ve genel haciz yolu</div></div>

<!-- 1 -->
<h2 class="sec" id="s-giris"><span class="no">1</span><span class="tt">Temel kavramlar ve kaynaklar</span></h2>
<div class="box def"><b>İcra hukuku:</b> Borcunu kendiliğinden ödemeyen borçluya karşı alacaklının, devletin zor kullanma yetkisinden yararlanarak alacağına kavuşmasını sağlayan kurallar bütünüdür. Alacaklı alacağını kendi gücüyle alamaz (<span class="hl">kendiliğinden hak alma yasağı</span>); devlet bu yasağın karşılığında cebri icra hizmeti sunar.</div>
<div class="grid2">
  <div class="card"><h5>Bireysel cebri icra = İcra</h5>Tek alacaklının, borçlunun alacağa <b>yetecek kadar</b> malına başvurması (haciz → satış → ödeme). <b>Bu dersin konusu.</b></div>
  <div class="card"><h5>Toplu cebri icra = İflas</h5>Borçlunun bütün mallarının bütün alacaklılar için tasfiyesi. Kural olarak tacirlere uygulanır.</div>
</div>
<h4>Kaynaklar</h4>
<ul>
  <li><b>Anayasa</b> — hak arama özgürlüğü, mülkiyet hakkı ve bunların sınırları</li>
  <li><b>2004 sayılı İcra ve İflas Kanunu (İİK)</b> — temel kaynak; son büyük değişiklikler 7343 sayılı Kanun (2021) ile</li>
  <li><b>İcra ve İflas Kanunu Yönetmeliği</b> — örnek formlar, uygulama ayrıntıları</li>
  <li><b>Yardımcı kanunlar:</b> HMK (yargılama usulü), TBK ve TMK (maddi hukuk), TTK (kambiyo senetleri), 492 sayılı Harçlar Kanunu</li>
  <li><b>Kamu alacakları</b> kural olarak İİK ile değil, 6183 sayılı Kanunla takip edilir</li>
  <li><b>Yargıtay içtihatları</b> — uygulamada yön gösterici</li>
</ul>
<h4>Takibin temel kavramları</h4>
<table class="tb">
  <tr><th>Kavram</th><th>Anlamı</th></tr>
  <tr><td>Takip talebi</td><td>Alacaklının icra dairesine başvurusu; takibi başlatır</td></tr>
  <tr><td>Ödeme emri</td><td>İlamsız takipte borçluya gönderilen, ödemeye ya da itiraza davet eden belge</td></tr>
  <tr><td>İcra emri</td><td>İlamlı takipte borçluya gönderilen, ilamın gereğini yerine getirme emri</td></tr>
  <tr><td>Kesinleşme</td><td>Süresinde itiraz edilmemesi veya itirazın kaldırılması/iptali ile takibin hacze hazır hale gelmesi</td></tr>
  <tr><td>Haciz</td><td>Borçlunun malına el konularak tasarruf yetkisinin sınırlandırılması</td></tr>
  <tr><td>Paraya çevirme</td><td>Haczedilen malın satılması (ihale)</td></tr>
  <tr><td>Paylaştırma</td><td>Satış bedelinin alacaklılara sıraya göre dağıtılması</td></tr>
</table>

<!-- 2 -->
<h2 class="sec" id="s-yollar"><span class="no">2</span><span class="tt">Takip yolları haritası</span></h2>
<ul class="tree">
  <li><span class="tn r">İcra takibi</span>
    <ul>
      <li><span class="tn a">İlamsız takip <span class="d">— elinde mahkeme kararı olmayan alacaklı</span></span>
        <ul>
          <li><span class="tn">Genel haciz yolu <i class="m">58 vd.</i> <span class="d">— para ve teminat alacakları; temel yol</span></span></li>
          <li><span class="tn">Kambiyo senetlerine mahsus haciz yolu <i class="m">167 vd.</i> <span class="d">— çek, bono, poliçe</span></span></li>
          <li><span class="tn">Kiralanan taşınmazların ilamsız tahliyesi <i class="m">269 vd.</i></span></li>
          <li><span class="tn">Rehnin paraya çevrilmesi yoluyla ilamsız takip <i class="m">145 vd.</i></span></li>
          <li><span class="tn">İflas yolu <span class="d">— bu dersin kapsamı dışında</span></span></li>
        </ul>
      </li>
      <li><span class="tn a">İlamlı takip <i class="m">24 vd.</i> <span class="d">— mahkeme kararı ya da ilam niteliğinde belge</span></span>
        <ul>
          <li><span class="tn">Para ve teminat <i class="m">32</i></span></li>
          <li><span class="tn">Taşınır teslimi <i class="m">24</i> · Taşınmaz tahliyesi ve teslimi <i class="m">26</i></span></li>
          <li><span class="tn">Çocuk teslimi ve kişisel ilişki <i class="m">25</i></span></li>
          <li><span class="tn">Bir işin yapılması veya yapılmaması <i class="m">30</i></span></li>
          <li><span class="tn">İlam niteliğindeki belgeler <i class="m">38</i> · ipotek akit tablosu <i class="m">149</i></span></li>
        </ul>
      </li>
    </ul>
  </li>
</ul>
<div class="flow">
  <div class="n q">Hangi yolu seçmeliyim?</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="cap">Mahkeme kararı var mı?</div><div class="n">Varsa <b>ilamlı takip</b></div></div>
    <div class="col"><div class="cap">Alacak rehinle güvenceli mi?</div><div class="n">Önce <b>rehnin paraya çevrilmesi</b> zorunlu <i class="m">45</i></div></div>
    <div class="col"><div class="cap">Kambiyo senedi var mı?</div><div class="n">Seçimlik: <b>kambiyo yolu</b> ya da genel haciz</div></div>
  </div>
</div>

<!-- 3 -->
<h2 class="sec" id="s-teskilat"><span class="no">3</span><span class="tt">İcra teşkilatı</span></h2>
<div class="grid2">
  <div class="card daire"><h5>İcra Dairesi <i class="m">1</i></h5>
    <ul><li>Takibi <b>yürüten</b> idari nitelikli organ</li><li>İcra müdürü, yardımcıları ve memurlar</li><li>Ödeme/icra emri gönderir, haciz yapar, satar, paylaştırır</li><li>Genel haciz yolunda <b>ödeme emrine itiraz buraya</b> yapılır</li></ul></div>
  <div class="card mah"><h5>İcra Mahkemesi <i class="m">4</i></h5>
    <ul><li>Tek hâkimli <b>yargı organı</b></li><li>Şikâyet, itirazın kaldırılması, ihalenin feshi, sıra cetveli itirazı, kambiyo itirazları</li><li>Kural: <b>basit yargılama</b>, belgelere dayalı sınırlı inceleme</li><li>Daireler icra mahkemesinin gözetim ve denetimindedir <i class="m">13</i></li></ul></div>
  <div class="card gen"><h5>Genel Mahkemeler</h5>
    <ul><li>Borcun <b>esası</b> hakkında tam yargılama</li><li>İtirazın iptali, menfi tespit, istirdat, istihkak, iptal davaları</li><li>İhtiyati haciz kararı</li></ul></div>
  <div class="card ceza"><h5>İcra Ceza Mahkemesi</h5>
    <ul><li>İcra ve iflas suçlarına bakar <i class="m">347 vd.</i></li><li>Bkz. 18. bölüm</li></ul></div>
</div>
<div class="box warn"><b>Devletin sorumluluğu <i class="m">5</i>:</b> İcra ve iflas dairesi görevlilerinin hukuka aykırı işlemlerinden doğan zarar için dava <b>görevliye değil Devlete</b> karşı açılır; Devlet kusurlu görevliye rücu eder.</div>
<h4>Yetki <i class="m">50</i></h4>
<ul>
  <li>Para ve teminat takiplerinde <b>HMK'nın yetki kuralları</b> kıyasen uygulanır: borçlunun yerleşim yeri, sözleşmenin ifa yeri vb.</li>
  <li>Yetki itirazı, ilamsız takipte <b>ödeme emrine itirazla birlikte</b> yapılır.</li>
  <li>İlamlı takip ise kural olarak <b>herhangi bir</b> icra dairesinde başlatılabilir.</li>
</ul>

<!-- 4 -->
<h2 class="sec" id="s-sikayet"><span class="no">4</span><span class="tt">Şikâyet</span><span class="m"><i class="m">16–18</i></span></h2>
<div class="flow">
  <div class="n start">İcra/iflas dairesinin hukuka veya olaya uygun olmayan işlemi<span class="d">ya da hakkın yerine getirilmemesi / sebepsiz sürüncemede bırakılması</span></div>
  <div class="n borclu"><span class="k">İlgili (alacaklı, borçlu, 3. kişi)</span>Şikâyet <b class="t">7 gün</b><span class="d">işlemi öğrenmeden itibaren · <b>icra mahkemesine</b></span></div>
  <div class="n mah"><span class="k">İcra Mahkemesi</span>Basit yargılama; gerekirse duruşmasız karar <i class="m">18</i><span class="d">Şikâyet takibi <b>kendiliğinden durdurmaz</b>; mahkeme geçici durdurma kararı verebilir.</span></div>
  <div class="split" style="--n:2">
    <div class="col"><div class="n end">Kabul: işlem <b>bozulur / düzeltilir</b> ya da yapılması emredilir <i class="m">17</i></div></div>
    <div class="col"><div class="n stop">Ret: işlem geçerli kalır</div></div>
  </div>
</div>
<div class="grid2">
  <div class="card"><h5>Süreli şikâyet — <b class="t">7 gün</b></h5>İşlemin usule, kanuna ya da olaya uygun olmaması (ör. yanlış kıymet takdiri, usulsüz tebligat).</div>
  <div class="card"><h5>Süresiz şikâyet <i class="m">16/2</i></h5>
    <ul><li>Hakkın yerine getirilmemesi</li><li>Sebepsiz sürüncemede bırakma</li><li>Kamu düzenine aykırı veya <b>yok hükmünde</b> işlemler</li></ul></div>
</div>
<table class="tb cmp">
  <tr><th></th><th>Şikâyet</th><th>İtiraz (ödeme emrine)</th></tr>
  <tr><td>Konu</td><td>İşlemin usule/hukuka aykırılığı</td><td>Borcun esası, imza, yetki</td></tr>
  <tr><td>Merci</td><td class="c-m">İcra Mahkemesi</td><td class="c-d">İcra Dairesi</td></tr>
  <tr><td>Süre</td><td>7 gün (bazen süresiz)</td><td>7 gün</td></tr>
  <tr><td>Takibe etkisi</td><td>Kendiliğinden durdurmaz</td><td>Takip durur <i class="m">66</i></td></tr>
</table>

<!-- 5 -->
<h2 class="sec" id="s-harc"><span class="no">5</span><span class="tt">İcra harç ve giderleri</span><span class="m"><i class="m">59</i></span></h2>
<div class="flow">
  <div class="n s daire"><span class="k">Takip talebi ile</span>Başvurma harcı ve peşin harç<span class="d">Harçlar Kanunu tarifesine göre</span></div>
  <div class="n s daire"><span class="k">Takip süresince</span>Tebligat, haciz, muhafaza, ilan, satış giderleri<span class="d">Alacaklı tarafından <b>peşin</b> ödenir</span></div>
  <div class="n s daire"><span class="k">Tahsil sırasında</span>Tahsil harcı<span class="d">Tahsil edilen paradan alınır</span></div>
  <div class="n end s">Sonuçta bütün takip giderleri <b>borçluya</b> yükletilir <i class="m">59</i></div>
</div>
<div class="box tip"><b>Akılda tut:</b> Gider avansı verilmezse istenen işlem yapılmaz. Adli yardımdan yararlanan alacaklı harç ve giderleri ödemeden takip yapabilir. Vekille takipte avukatlık ücreti de takip giderine dahildir.</div>

<!-- 6 -->
<h2 class="sec" id="s-taraflar"><span class="no">6</span><span class="tt">İcra takibinin tarafları</span></h2>
<div class="grid2">
  <div class="card"><h5>Alacaklı</h5>Takibi başlatan; alacağın sahibi ya da halefi (devralan, mirasçı).</div>
  <div class="card"><h5>Borçlu</h5>Aleyhine takip yapılan; ölmüşse mirasçıları.</div>
</div>
<table class="tb">
  <tr><th>Ehliyet</th><th>Kimde?</th><th>Yoksa?</th></tr>
  <tr><td>Takipte taraf ehliyeti</td><td>Hak ehliyeti olan herkes (gerçek ve tüzel kişiler)</td><td>Takip yapılamaz; işlemler yok hükmünde</td></tr>
  <tr><td>Takip ehliyeti</td><td>Fiil ehliyeti olanlar</td><td>Kanuni temsilci aracılığıyla takip</td></tr>
</table>
<ul>
  <li><b>Temsil:</b> kanuni temsilci (veli, vasi) ya da vekil (avukat). Tüzel kişiyi organı temsil eder.</li>
  <li><b>Takip arkadaşlığı:</b> birden çok alacaklı veya borçlu aynı takipte yer alabilir.</li>
  <li><b>Borçlunun ölümü <i class="m">53</i>:</b> takip mirasçılara karşı yürür; ancak mirası ret süresi (TMK m.606: 3 ay) dolmadan mirasçılara karşı takip yapılamaz.</li>
</ul>

<!-- 7 -->
<h2 class="sec" id="s-ilamsiz"><span class="no">7</span><span class="tt">Genel haciz yoluyla ilamsız takip</span><span class="m"><i class="m">58–76</i></span></h2>
<div class="flow">
  <div class="n start">Takip talebi <i class="m">58</i><span class="d">yazılı veya sözlü · tarafların kimliği · alacak tutarı ve faiz · senet ya da borcun sebebi · seçilen takip yolu</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Ödeme emri düzenlenir ve tebliğ edilir <i class="m">60</i><span class="d">Ödeme için <b class="t">7 gün</b> · itiraz için <b class="t">7 gün</b> · mal beyanı ihtarı</span></div>
  <div class="n q">Borçlu 7 gün içinde ne yapar?</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="cap">Öder</div><div class="n end">Takip sona erer</div></div>
    <div class="col"><div class="cap">Susar</div><div class="n daire">Takip <b>kesinleşir</b><span class="d">→ Haciz istenebilir (9. bölüm)</span></div></div>
    <div class="col"><div class="cap">İtiraz eder <i class="m">62</i></div><div class="n borclu">İcra dairesine, <b>yazılı veya sözlü</b><span class="d">borca · imzaya · yetkiye</span></div><div class="n stop">Takip <b>durur</b> <i class="m">66</i></div></div>
  </div>
  <div class="n q w">Alacaklı itirazı nasıl aşar? → 8. bölüm</div>
  <div class="split flat" style="--n:2">
    <div class="col"><div class="n mah"><span class="k">İcra Mahkemesi</span>İtirazın kaldırılması <i class="m">68</i><span class="d"><b class="t">6 ay</b> · belgeli alacaklar</span></div></div>
    <div class="col"><div class="n gen"><span class="k">Genel Mahkeme</span>İtirazın iptali davası <i class="m">67</i><span class="d"><b class="t">1 yıl</b> · her türlü delil</span></div></div>
  </div>
</div>
<h4>İtiraz ayrıntıları <i class="m">62</i></h4>
<ul>
  <li>Genel haciz yolunda itiraz için sebep göstermek zorunlu değildir; ama <b>imzaya itiraz açıkça</b> yapılmalıdır — aksi halde senetteki imza takip bakımından kabul edilmiş sayılır.</li>
  <li><b>Kısmi itiraz:</b> itiraz edilmeyen kısım için takip kesinleşir ve devam eder.</li>
  <li><b>Yetki itirazı</b> esasa ilişkin itirazla birlikte yapılır.</li>
  <li><b>Gecikmiş itiraz <i class="m">65</i>:</b> borçlu, elinde olmayan bir sebeple süreyi kaçırdıysa icra mahkemesine başvurur.</li>
</ul>
<h4>Mal beyanı <i class="m">74–76</i></h4>
<div class="box warn"><b>Mal beyanı yükümlülüğü:</b> Ödeme emrine itiraz etmeyen borçlu, ödeme süresi içinde mallarını, alacaklarını ve gelirlerini bildirmek zorundadır. Bildirmezse alacaklının şikâyetiyle <b>tazyik hapsi</b> uygulanır <i class="m">76</i> · <i class="m">337</i>.</div>

<!-- 8 -->
<h2 class="sec" id="s-itiraz"><span class="no">8</span><span class="tt">İtirazın iptali, itirazın kaldırılması ve borçlunun davaları</span></h2>
<table class="tb cmp">
  <tr><th></th><th>İtirazın kaldırılması <i class="m">68</i></th><th>İtirazın iptali <i class="m">67</i></th></tr>
  <tr><td>Merci</td><td class="c-m">İcra Mahkemesi</td><td class="c-g">Genel Mahkeme</td></tr>
  <tr><td>Süre</td><td><b class="t">6 ay</b> itirazın tebliğinden</td><td><b class="t">1 yıl</b> itirazın tebliğinden</td></tr>
  <tr><td>Belge</td><td>Yalnız m.68'de sayılanlar: imzası ikrar edilmiş ya da noterce onaylanmış borç ikrarı içeren belge, resmi daire veya yetkili makamın verdiği belge</td><td>Her türlü delil</td></tr>
  <tr><td>Yargılama</td><td>Basit yargılama, belgeyle sınırlı inceleme</td><td>Genel hükümler, tam yargılama</td></tr>
  <tr><td>Kararın niteliği</td><td>Yalnız takip hukuku bakımından sonuç doğurur; borcun varlığı hakkında <b>maddi anlamda kesin hüküm değildir</b></td><td>Borcun varlığı hakkında <b>kesin hüküm</b></td></tr>
  <tr><td>Kabulün sonucu</td><td colspan="2">Takip <b>kaldığı yerden devam eder</b>; alacaklı haciz isteyebilir</td></tr>
  <tr><td>Tazminat</td><td colspan="2">İtiraz haksız bulunursa borçlu, alacaklı da haksız ve kötü niyetli takip yaptıysa alacaklı, alacağın <b>%20'sinden aşağı olmamak</b> üzere tazminata mahkûm edilebilir</td></tr>
</table>
<div class="box tip"><b>Seçim:</b> Alacaklının elinde m.68 belgesi varsa icra mahkemesi daha hızlıdır. Belge yoksa ya da borcun esası tartışmalıysa itirazın iptali davası açılır. Süreler kaçarsa yeni takip veya alacak davası yoluna gidilir.</div>
<h3>Borçlunun açabileceği davalar <i class="m">72</i></h3>
<div class="flow">
  <div class="n q">Borçlu borçlu olmadığını nasıl ileri sürer?</div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">Henüz ödemediyse</div><div class="n gen"><span class="k">Genel Mahkeme</span>Menfi tespit davası<span class="d">Takipten önce veya sonra açılabilir. Takipten sonra açılması takibi <b>durdurmaz</b>; teminat karşılığında tedbirle paranın alacaklıya ödenmesi durdurulabilir.</span></div></div>
    <div class="col"><div class="cap">Ödemek zorunda kaldıysa</div><div class="n gen"><span class="k">Genel Mahkeme</span>İstirdat davası<span class="d">Paranın <b>tamamen ödendiği tarihten</b> itibaren <b class="t">1 yıl</b></span></div></div>
  </div>
</div>

<!-- 9 -->
<h2 class="sec" id="s-haciz"><span class="no">9</span><span class="tt">Haciz safhası</span><span class="m"><i class="m">78–105</i></span></h2>
<div class="flow">
  <div class="n start">Takip kesinleşti</div>
  <div class="n daire"><span class="k">Alacaklı → İcra Dairesi</span>Haciz talebi <i class="m">78</i><span class="d">Ödeme emri tebliğinden itibaren <b class="t">1 yıl</b> · itiraz ve davayla geçen süre hesaba katılmaz</span></div>
  <div class="n daire"><span class="k">İcra memuru</span>Haciz <i class="m">79–85</i><span class="d">Borçlunun alacağa, faize ve giderlere <b>yetecek kadar</b> malı haczedilir <i class="m">85</i></span></div>
  <div class="n q w">Mal kimin elinde? Üçüncü kişi hak iddia ediyor mu?</div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">Borçlunun elinde <i class="m">96–97</i></div>
      <div class="n daire">İstihkak iddiası alacaklıya ve borçluya bildirilir<span class="d">itiraz için <b class="t">3 gün</b>; itiraz edilmezse iddia kabul edilmiş sayılır</span></div>
      <div class="n mah"><span class="k">İcra Mahkemesi</span>Takibin devamına ya da ertelenmesine karar</div>
      <div class="n gen"><span class="k">3. kişi</span>İstihkak davası <b class="t">7 gün</b></div>
    </div>
    <div class="col"><div class="cap">3. kişinin elinde <i class="m">99</i></div>
      <div class="n daire">Alacaklıya süre verilir</div>
      <div class="n gen"><span class="k">Alacaklı</span>İstihkak davası <b class="t">7 gün</b><span class="d">açılmazsa 3. kişinin iddiası kabul edilmiş sayılır</span></div>
    </div>
  </div>
</div>
<h3>Haczedilemeyen mallar <i class="m">82–83</i></h3>
<div class="grid2">
  <div class="card"><h5>Haczedilemez <i class="m">82</i></h5><ul><li>Borçlu ve ailesi için lüzumlu ev eşyası</li><li>Mesleğin gerektirdiği araç ve gereçler</li><li>Devlet malları, belirli sosyal yardımlar vb.</li></ul></div>
  <div class="card"><h5>Kısmen haczedilebilir <i class="m">83</i></h5>Maaş ve ücretler, borçlu ile ailesinin geçimi için gerekli miktar indirildikten sonra haczedilir; haczedilecek miktar <b>dörtte birden az olamaz</b>. Nafaka alacakları bu sınıra tabi değildir.</div>
</div>
<div class="box warn"><b>Haczedilmezlik:</b> Bu kurala aykırı hacze karşı icra mahkemesine <b class="t">7 gün</b> içinde şikâyet edilir <i class="m">16</i>.</div>
<h3>Üçüncü kişideki alacağın haczi — haciz ihbarnamesi <i class="m">89</i></h3>
<div class="flow">
  <div class="n daire"><span class="k">89/1</span>Birinci haciz ihbarnamesi<span class="d">3. kişi borcu inkâr için <b class="t">7 gün</b></span></div>
  <div class="cap">itiraz etmezse</div>
  <div class="n daire"><span class="k">89/2</span>İkinci haciz ihbarnamesi<span class="d">yine <b class="t">7 gün</b></span></div>
  <div class="cap">yine itiraz etmezse</div>
  <div class="n stop"><span class="k">89/3</span>Borç 3. kişinin <b>zimmetinde sayılır</b>; ondan da tahsil edilir</div>
  <div class="n gen"><span class="k">3. kişi</span>Menfi tespit davası <b class="t">15 gün</b></div>
</div>
<h3>Haczin sonuçları</h3>
<ul>
  <li>Borçlu haczedilen mal üzerinde alacaklının zararına <b>tasarruf edemez</b>; bu tasarruflar alacaklıya karşı hüküm doğurmaz.</li>
  <li>Aynı mal birden çok kez haczedilebilir; belirli şartlarla diğer alacaklılar <b>hacze iştirak</b> edebilir <i class="m">100</i>.</li>
  <li>Haczedilecek mal bulunamazsa haciz tutanağı <b>geçici aciz belgesi</b> hükmündedir <i class="m">105</i>.</li>
</ul>

<!-- 10 -->
<h2 class="sec" id="s-satis"><span class="no">10</span><span class="tt">Paraya çevirme (satış)</span><span class="m"><i class="m">106–134</i></span></h2>
<div class="flow">
  <div class="n start">Mal haczedildi</div>
  <div class="n daire"><span class="k">Alacaklı → İcra Dairesi</span>Satış talebi <i class="m">106</i><span class="d">Taşınır ve taşınmazda hacizden itibaren <b class="t">1 yıl</b> (7343 sayılı Kanunla eşitlendi)</span></div>
  <div class="n stop">Süresinde satış istenmez ya da talep geri alınıp yenilenmezse <b>haciz kalkar</b> <i class="m">110</i></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Kıymet takdiri<span class="d">Taşınmazda takdire karşı tebliğden itibaren <b class="t">7 gün</b> içinde icra mahkemesine şikâyet <i class="m">128a</i></span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>İlan ve ihale<span class="d">Elektronik ve fiziki artırma · taşınmazda ihale için teklifin tahmin edilen değerin <b>%50'sini</b> bulması ve satış isteyen alacaklıya önce gelen alacakların toplamını aşması gerekir <i class="m">129</i></span></div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">Şartlar sağlanmazsa</div><div class="n stop">Satış talebi düşer<span class="d">alacaklı <b class="t">1 yıl</b> içinde yeniden satış isteyebilir</span></div></div>
    <div class="col"><div class="cap">İhale yapılırsa</div><div class="n end">Bedel ödenir · mal alıcıya geçer<span class="d">Bedel ödenmezse ihale kaldırılır; fark ve zarardan ilk alıcı sorumludur <i class="m">133</i></span></div></div>
  </div>
</div>
<h3>İhalenin feshi <i class="m">134</i></h3>
<div class="flow">
  <div class="n borclu"><span class="k">İlgililer</span>İhalenin feshi talebi → <b>icra mahkemesi</b><span class="d"><b class="t">7 gün</b> ihaleden; ihale tarihi tebliğ edilmeyen ya da sonradan öğrenen için öğrenmeden · her hâlde <b class="t">1 yıl</b></span></div>
  <div class="split" style="--n:2">
    <div class="col"><div class="n end">Kabul: ihale bozulur</div></div>
    <div class="col"><div class="n stop">Esastan ret: talep edene ihale bedelinin <b>%10'una kadar</b> para cezası</div></div>
  </div>
</div>

<!-- 11 -->
<h2 class="sec" id="s-paylastirma"><span class="no">11</span><span class="tt">Paraların paylaştırılması</span><span class="m"><i class="m">138–143</i></span></h2>
<div class="flow">
  <div class="n q">Satış bedeli bütün alacaklara yetiyor mu?</div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">Yetiyor</div><div class="n end">Alacaklılara ödenir; artan borçluya verilir</div></div>
    <div class="col"><div class="cap">Yetmiyor</div><div class="n daire"><span class="k">İcra Dairesi</span>Sıra cetveli düzenlenir <i class="m">140</i></div>
      <div class="n mah"><span class="k">İcra Mahkemesi</span>Sıra cetveline itiraz / şikâyet <b class="t">7 gün</b> <i class="m">142</i></div></div>
  </div>
</div>
<h4>Sıra</h4>
<ol>
  <li><b>Rehinli alacaklılar</b> rehin konusu malın bedelinden önce ödenir.</li>
  <li>Rehinle güvencelenmemiş alacaklar <b>m.206'daki 4 sıraya</b> göre ödenir: imtiyazlı sıralardan (ör. işçi alacakları, nafaka) başlanır, son sırada adi (imtiyazsız) alacaklar yer alır.</li>
  <li>Aynı sıradaki alacaklılar <b>garameten</b> (alacakları oranında) pay alır.</li>
</ol>
<div class="box def"><b>Kesin aciz belgesi <i class="m">143</i>:</b> Satış bedeli alacağı karşılamazsa alacaklıya verilir. Bağlı alacak <b class="t g">20 yıl</b> zamanaşımına tabidir. Aciz belgesi, iptal davası (17. bölüm) açabilmenin şartlarından biridir.</div>

<div class="part"><small>İKİNCİ BÖLÜM</small><div>Özel takip yolları, geçici koruma ve yaptırımlar</div></div>

<!-- 12 -->
<h2 class="sec" id="s-kambiyo"><span class="no">12</span><span class="tt">Kambiyo senetlerine mahsus haciz yolu</span><span class="m"><i class="m">167–170</i></span></h2>
<div class="flow">
  <div class="n start">Takip talebi + <b>senedin aslı</b> <i class="m">167</i><span class="d">çek · bono · poliçe</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Senedin kambiyo senedi niteliğini inceler<span class="d">nitelik yoksa takip talebini reddeder</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Ödeme emri <i class="m">168</i><span class="d">Ödeme <b class="t">10 gün</b> · itiraz ve şikâyet <b class="t">5 gün</b></span></div>
  <div class="n q w">Borçlu itiraz edecekse <b>icra dairesine değil, icra mahkemesine</b> başvurur</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="cap">Borca itiraz</div><div class="n mah">Borç ödendi / ertelendi vb.<span class="d">Belgeyle ispat; kabul edilirse takip geri bırakılır</span></div></div>
    <div class="col"><div class="cap">İmzaya itiraz <i class="m">170</i></div><div class="n mah">İmza borçluya ait değil<span class="d">Gerekirse bilirkişi incelemesi</span></div></div>
    <div class="col"><div class="cap">Şikâyet</div><div class="n mah">Senedin kambiyo niteliği, yetki, usul</div></div>
  </div>
  <div class="n stop w">İtiraz <b>takibi kendiliğinden durdurmaz</b>: haciz yapılabilir, satış yapılamaz; icra mahkemesi takibin durdurulmasına karar verebilir</div>
</div>
<div class="box warn"><b>İmza itirazının yaptırımı <i class="m">170</i>:</b> İmzaya itiraz reddedilirse borçlu, alacağın <b>%20'sinden az olmamak</b> üzere tazminat ve <b>%10</b> para cezası öder. İtiraz kabul edilir ve alacaklı kötü niyetliyse aynı yaptırımlar alacaklıya uygulanır.</div>
<table class="tb cmp">
  <tr><th></th><th>Genel haciz yolu</th><th>Kambiyo senetleri yolu</th></tr>
  <tr><td>Ödeme süresi</td><td>7 gün</td><td><b>10 gün</b></td></tr>
  <tr><td>İtiraz süresi</td><td>7 gün</td><td><b>5 gün</b></td></tr>
  <tr><td>İtiraz mercii</td><td class="c-d">İcra Dairesi</td><td class="c-m">İcra Mahkemesi</td></tr>
  <tr><td>İtirazın etkisi</td><td>Takip durur</td><td>Kendiliğinden durmaz</td></tr>
  <tr><td>Senet aslı</td><td>Gerekmez</td><td>Zorunlu</td></tr>
</table>

<!-- 13 -->
<h2 class="sec" id="s-tahliye"><span class="no">13</span><span class="tt">Kiralanan taşınmazın ilamsız tahliyesi</span><span class="m"><i class="m">269–276</i></span></h2>
<div class="row" style="--n:2">
  <div class="flow" style="margin:0">
    <div class="n start s">Kira bedeli ödenmedi<span class="d">temerrüt nedeniyle tahliye <i class="m">269</i></span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>Tahliye ihtarlı ödeme emri<span class="d">Ödeme: konut ve çatılı işyerinde <b class="t">30 gün</b>, diğerlerinde en az <b class="t">10 gün</b> (TBK 315) · itiraz <b class="t">7 gün</b></span></div>
    <div class="n q s">Süresinde ödenmedi ya da itiraz edildi</div>
    <div class="n mah s"><span class="k">İcra Mahkemesi</span>İtirazın kaldırılması ve tahliye</div>
  </div>
  <div class="flow" style="margin:0">
    <div class="n start s">Kira süresi bitti ya da tahliye taahhüdü var<span class="d"><i class="m">272</i> · TBK 352</span></div>
    <div class="n daire s"><span class="k">Kiraya veren</span>Takip talebi<span class="d">Süre bitiminden ya da taahhüt edilen tarihten itibaren <b class="t">1 ay</b> içinde</span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>Tahliye emri<span class="d">Tahliye için <b class="t">15 gün</b></span></div>
    <div class="n mah s"><span class="k">İcra Mahkemesi</span>İtiraz edilirse inceleme ve tahliye kararı</div>
  </div>
</div>
<div class="box tip"><b>Tahliye taahhüdü:</b> Yazılı olmalı ve kira sözleşmesinin kurulmasından <b>sonra</b> verilmiş olmalıdır (TBK 352); sözleşmeyle aynı anda alınan taahhüt geçersizdir.</div>

<!-- 14 -->
<h2 class="sec" id="s-ilamli"><span class="no">14</span><span class="tt">İlamlı icra</span><span class="m"><i class="m">24–41</i></span></h2>
<div class="flow">
  <div class="n start">İlam ya da ilam niteliğinde belge <i class="m">38</i><span class="d">mahkeme kararları · mahkemede yapılan sulh ve kabuller · noterce düzenlenen ve kayıtsız şartsız para borcu ikrarı içeren senetler · ipotek akit tabloları <i class="m">149</i></span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>İcra emri <i class="m">32</i><span class="d">Para ve teminat için <b class="t">7 gün</b></span></div>
  <div class="n q">Borçlunun savunma araçları</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="cap">İcranın geri bırakılması <i class="m">33</i></div><div class="n mah"><b class="t">7 gün</b><span class="d">İlamdan sonra borç ödendi (itfa) ya da ertelendi (imhal); resmi/noterce onaylı belge veya ikrarla ispat</span></div></div>
    <div class="col"><div class="cap">Zamanaşımı <i class="m">33a</i></div><div class="n mah">İlamdan sonra işleyen zamanaşımı<span class="d">İlamlı takipte süre 10 yıl <i class="m">39</i></span></div></div>
    <div class="col"><div class="cap">Kanun yolu + teminat <i class="m">36</i></div><div class="n borclu">İcranın ertelenmesi (tehiri icra)<span class="d">Teminat göstererek kararı beklemek · nafakada uygulanmaz</span></div></div>
  </div>
</div>
<div class="grid2">
  <div class="card"><h5>Kesinleşme şartı</h5>Kural olarak ilam <b>kesinleşmeden</b> icra edilebilir. İstisna (HMK 350): kişiler hukuku, aile hukuku ve taşınmaz üzerindeki ayni haklara ilişkin kararlar kesinleşmeden yerine getirilmez.</div>
  <div class="card"><h5>İlamın bozulması <i class="m">40</i></h5>İlam bozulursa icra durur; kaldırılırsa yapılan işlemler eski hâline getirilir, tahsil edilen <b>iade</b> edilir.</div>
</div>
<h4>Para dışındaki ilamlar</h4>
<table class="tb">
  <tr><th>Konu</th><th>Madde</th><th>Ana kural</th></tr>
  <tr><td>Taşınır teslimi</td><td><i class="m">24</i></td><td>İcra emri <b class="t">7 gün</b>; teslim edilmezse mal zorla alınır, bulunmazsa değeri tahsil edilir</td></tr>
  <tr><td>Taşınmaz tahliyesi / teslimi</td><td><i class="m">26</i></td><td>İcra emri <b class="t">7 gün</b>; sonra zorla tahliye</td></tr>
  <tr><td>Çocuk teslimi, kişisel ilişki</td><td><i class="m">25</i></td><td>7343 sayılı Kanunla <b>adli destek ve mağdur hizmetleri müdürlüklerine</b> aktarıldı (ÇKK m.41/A); henüz geçilmeyen yerlerde m.25 uygulanır</td></tr>
  <tr><td>Bir işin yapılması / yapılmaması</td><td><i class="m">30</i></td><td>İş borçlu yerine yaptırılıp gideri tahsil edilebilir</td></tr>
</table>

<!-- 15 -->
<h2 class="sec" id="s-rehin"><span class="no">15</span><span class="tt">Rehnin paraya çevrilmesi yolu</span><span class="m"><i class="m">45 · 145–153</i></span></h2>
<div class="box warn"><b>Önce rehin kuralı <i class="m">45</i>:</b> Alacağı rehinle güvenceli alacaklı, kanundaki istisnalar dışında <b>önce rehni paraya çevirmek</b> zorundadır; doğrudan haciz yoluna gidemez.</div>
<div class="row" style="--n:2">
  <div class="flow" style="margin:0">
    <div class="n start s">Taşınır rehni<span class="d"><i class="m">145 vd.</i></span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>Ödeme emri<span class="d">İtiraz icra dairesine; takip durur</span></div>
    <div class="n mah s"><span class="k">İcra Mahkemesi</span>İtirazın kaldırılması<span class="d">ya da genel mahkemede itirazın iptali</span></div>
  </div>
  <div class="flow" style="margin:0">
    <div class="n start s">Taşınmaz rehni (ipotek)<span class="d"><i class="m">148 vd.</i></span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>İlamsız: ödeme emri <i class="m">149b</i><span class="d">ödeme <b class="t">30 gün</b> · itiraz <b class="t">7 gün</b></span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>İlamlı: ipotek akit tablosu <i class="m">149</i><span class="d">kayıtsız şartsız borç ikrarı varsa <b class="t">30 gün</b> süreli icra emri · savunma: icranın geri bırakılması</span></div>
  </div>
</div>
<table class="tb">
  <tr><th>Satış isteme süresi <i class="m">150e</i></th><th>Süre</th></tr>
  <tr><td>Taşınır rehni</td><td><b class="t">6 ay</b></td></tr>
  <tr><td>Taşınmaz rehni</td><td><b class="t">1 yıl</b></td></tr>
</table>
<ul>
  <li>Satış bedeli yetmezse alacaklıya <b>rehin açığı belgesi</b> verilir <i class="m">152</i>; alacaklı kalan alacak için haciz ya da iflas yoluyla devam edebilir.</li>
  <li>Kredi kuruluşlarının ipotekli kredi alacakları için özel hükümler vardır <i class="m">150ı</i>.</li>
</ul>

<!-- 16 -->
<h2 class="sec" id="s-ihtiyati"><span class="no">16</span><span class="tt">İhtiyati haciz</span><span class="m"><i class="m">257–268</i></span></h2>
<div class="box def"><b>Amaç:</b> Alacaklının takip ya da dava sonuçlanıncaya kadar borçlunun mallarını kaçırmasını önlemek için verilen <b>geçici</b> hukuki koruma.</div>
<div class="grid2">
  <div class="card"><h5>Vadesi gelmiş alacak</h5>Rehinle güvencelenmemiş, muaccel <b>para</b> alacağı için istenebilir <i class="m">257/1</i>.</div>
  <div class="card"><h5>Vadesi gelmemiş alacak <i class="m">257/2</i></h5><ul><li>Borçlunun belli bir yerleşim yeri yoksa</li><li>Borçlu kaçıyor, mallarını kaçırıyor ya da hileli işlemler yapıyorsa</li></ul></div>
</div>
<div class="flow">
  <div class="n gen"><span class="k">Genel Mahkeme</span>İhtiyati haciz kararı<span class="d">Yaklaşık ispat yeterli · alacaklıdan <b>teminat</b> alınır; alacak ilama dayanıyorsa teminat aranmaz <i class="m">259</i></span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Kararın uygulanması<span class="d">Karardan itibaren <b class="t">10 gün</b> içinde istenmezse karar kalkar <i class="m">261</i></span></div>
  <div class="n borclu"><span class="k">Alacaklı</span>Takip ya da dava <i class="m">264</i><span class="d">Uygulamadan itibaren <b class="t">7 gün</b> içinde · ödeme emrine itiraz edilirse itirazın tebliğinden itibaren <b class="t">7 gün</b> içinde itirazın kaldırılması ya da iptali için başvurulur</span></div>
  <div class="n end">Takip kesinleşince ihtiyati haciz <b>kesin hacze</b> dönüşür</div>
</div>
<div class="grid2">
  <div class="card mah"><h5>İhtiyati hacze itiraz <i class="m">265</i></h5>Borçlu <b class="t">7 gün</b> içinde kararı veren mahkemeye: yetki, haciz sebepleri, teminat. Üçüncü kişiler de <b class="t">7 gün</b> içinde itiraz edebilir.</div>
  <div class="card"><h5>Teminatla kaldırma <i class="m">266</i></h5>Borçlu alacak, faiz ve giderleri karşılayan teminat gösterirse ihtiyati haciz kaldırılır.</div>
</div>
<div class="box warn"><b>Haksız ihtiyati haciz:</b> Alacaklı, haksız çıkan ihtiyati haciz nedeniyle borçlunun ve üçüncü kişilerin uğradığı zararı tazmin eder <i class="m">259</i>.</div>

<!-- 17 -->
<h2 class="sec" id="s-iptal"><span class="no">17</span><span class="tt">İptal davaları (tasarrufun iptali)</span><span class="m"><i class="m">277–284</i></span></h2>
<div class="box def"><b>Amaç:</b> Borçlunun alacaklılarını zarara uğratan tasarruflarını alacaklıya karşı <b>hükümsüz</b> kılmak. Dava kazanılırsa alacaklı, tasarruf konusu malı haczettirip sattırabilir; tasarruf diğer herkes için geçerli kalır (<b>nispi etki</b> <i class="m">283</i>).</div>
<div class="flow">
  <div class="n q w">Dava şartları</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="n">Takip <b>kesinleşmiş</b> olmalı</div></div>
    <div class="col"><div class="n">Alacaklının elinde <b>kesin ya da geçici aciz belgesi</b> olmalı <i class="m">105 · 143</i></div></div>
    <div class="col"><div class="n">Tasarruf, <b>borç doğduktan sonra</b> yapılmış olmalı</div></div>
  </div>
</div>
<div class="row" style="--n:3">
  <div class="card"><h5>İvazsız tasarruflar <i class="m">278</i></h5>Hacizden ya da iflastan önceki <b class="t">2 yıl</b><ul><li>Bağışlamalar ve karşılıksız işlemler</li><li>Yakın akraba ve eşler arasındaki ivazlı işlemler de bağış sayılır</li><li>Edimler arasında aşırı nispetsizlik</li></ul></div>
  <div class="card"><h5>Aciz hâlinde tasarruflar <i class="m">279</i></h5>Hacizden ya da iflastan önceki <b class="t">1 yıl</b><ul><li>Önceden taahhüt yokken mevcut borca teminat verme</li><li>Para ya da olağan ödeme araçları dışında ödeme</li><li>Vadesi gelmemiş borcu ödeme</li></ul></div>
  <div class="card"><h5>Kasten zarar verme <i class="m">280</i></h5>Hacizden ya da iflastan önceki <b class="t">5 yıl</b><ul><li>Alacaklılara zarar verme kastıyla yapılan tasarruflar</li><li>Karşı taraf bu kastı biliyor ya da bilmesi gerekiyor olmalı</li></ul></div>
</div>
<div class="box warn"><b>Hak düşürücü süre <i class="m">284</i>:</b> İptal davası açma hakkı, tasarruf tarihinden itibaren <b class="t">5 yıl</b> geçmekle düşer. Davaya genel mahkeme bakar; dava, borçluyla işlem yapan üçüncü kişiye karşı açılır.</div>

<!-- 18 -->
<h2 class="sec" id="s-suclar"><span class="no">18</span><span class="tt">İcra suçlarının genel esasları</span><span class="m"><i class="m">331–354</i></span></h2>
<div class="flow">
  <div class="n borclu"><span class="k">Alacaklı / zarar gören</span>Şikâyet <i class="m">347</i><span class="d">Eylemin öğrenilmesinden itibaren <b class="t">3 ay</b> · her hâlde eylem tarihinden itibaren <b class="t">1 yıl</b></span></div>
  <div class="n" style="border-color:#d24357;background:#fff7f8"><span class="k" style="color:#b92b40">İcra Ceza Mahkemesi</span>Yargılama<span class="d">Uzlaştırma uygulanmaz</span></div>
  <div class="n end">Borç ödenir ya da şikâyetten vazgeçilirse dava <b>düşer</b>, hüküm verilmişse infaz edilmez <i class="m">354</i></div>
</div>
<div class="grid2">
  <div class="card ceza"><h5>Mal kaçırma <i class="m">331</i></h5>Alacaklıyı zarara uğratmak amacıyla mal kaçırma, borçlu görünme gibi eylemler. <b>Hapis cezası</b>.</div>
  <div class="card ceza"><h5>Mal beyanında bulunmama <i class="m">337</i></h5>Mal beyanı yükümlülüğüne uymayan borçlu için <b>tazyik hapsi</b> <i class="m">76</i>.</div>
  <div class="card ceza"><h5>Taahhüdü ihlal <i class="m">340</i></h5>İcra dairesinde verdiği ödeme taahhüdüne uymayan borçlu için tazyik hapsi.</div>
  <div class="card ceza"><h5>Nafakaya uymama <i class="m">344</i></h5>Nafaka kararına uymayan borçlu için <b>3 aya kadar</b> tazyik hapsi.</div>
</div>
<div class="box tip"><b>Tazyik hapsi ≠ hapis cezası:</b> Tazyik hapsi borçluyu yükümlülüğünü yerine getirmeye <b>zorlama</b> aracıdır; borçlu yükümlülüğü yerine getirince (ör. mal beyanında bulunur ya da öder) serbest bırakılır.</div>

<!-- 19 -->
<h2 class="sec" id="s-sureler"><span class="no">19</span><span class="tt">Süreler tablosu</span></h2>
<table class="tb">
  <tr><th>İşlem</th><th>Süre</th><th>Merci</th><th>Madde</th></tr>
  <tr><td>Şikâyet</td><td><b>7 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">16</i></td></tr>
  <tr><td>Ödeme emrine itiraz (genel haciz)</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">62</i></td></tr>
  <tr><td>İtirazın iptali davası</td><td><b>1 yıl</b></td><td class="c-g">Genel Mah.</td><td><i class="m">67</i></td></tr>
  <tr><td>İtirazın kaldırılması</td><td><b>6 ay</b></td><td class="c-m">İcra Mah.</td><td><i class="m">68</i></td></tr>
  <tr><td>İstirdat davası</td><td><b>1 yıl</b></td><td class="c-g">Genel Mah.</td><td><i class="m">72</i></td></tr>
  <tr><td>Haciz isteme</td><td><b>1 yıl</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">78</i></td></tr>
  <tr><td>Haciz ihbarnamesine itiraz (89/1, 89/2)</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">89</i></td></tr>
  <tr><td>89/3 sonrası menfi tespit</td><td><b>15 gün</b></td><td class="c-g">Genel Mah.</td><td><i class="m">89</i></td></tr>
  <tr><td>İstihkak iddiasına itiraz (mal borçluda)</td><td><b>3 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">96</i></td></tr>
  <tr><td>İstihkak davası</td><td><b>7 gün</b></td><td class="c-g">Genel Mah.</td><td><i class="m">97 · 99</i></td></tr>
  <tr><td>Satış isteme (taşınır / taşınmaz)</td><td><b>1 yıl</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">106</i></td></tr>
  <tr><td>Kıymet takdirine şikâyet (taşınmaz)</td><td><b>7 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">128a</i></td></tr>
  <tr><td>İhalenin feshi</td><td><b>7 gün</b> · en geç 1 yıl</td><td class="c-m">İcra Mah.</td><td><i class="m">134</i></td></tr>
  <tr><td>Sıra cetveline itiraz / şikâyet</td><td><b>7 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">142</i></td></tr>
  <tr><td>Kambiyo: ödeme / itiraz</td><td><b>10 gün / 5 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">168</i></td></tr>
  <tr><td>İcra emri (para, taşınır, taşınmaz)</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">24 · 26 · 32</i></td></tr>
  <tr><td>İcranın geri bırakılması (itfa, imhal)</td><td><b>7 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">33</i></td></tr>
  <tr><td>Rehin: satış isteme (taşınır / taşınmaz)</td><td><b>6 ay / 1 yıl</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">150e</i></td></tr>
  <tr><td>Kira: tahliye için takip (süre bitimi / taahhüt)</td><td><b>1 ay</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">272</i></td></tr>
  <tr><td>İhtiyati haczin uygulanmasını isteme</td><td><b>10 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">261</i></td></tr>
  <tr><td>İhtiyati hacizden sonra takip / dava</td><td><b>7 gün</b></td><td>—</td><td><i class="m">264</i></td></tr>
  <tr><td>İhtiyati hacze itiraz</td><td><b>7 gün</b></td><td class="c-g">Kararı veren mah.</td><td><i class="m">265</i></td></tr>
  <tr><td>İptal davası (hak düşürücü)</td><td><b>5 yıl</b></td><td class="c-g">Genel Mah.</td><td><i class="m">284</i></td></tr>
  <tr><td>İcra suçlarında şikâyet</td><td><b>3 ay</b> · en geç 1 yıl</td><td>İcra Ceza Mah.</td><td><i class="m">347</i></td></tr>
</table>

<div class="foot">Bu özet 2004 sayılı İcra ve İflas Kanunu'nun güncel metni esas alınarak hazırlanmıştır (Ekim 2026). Sınavdan önce maddeleri mevzuat.gov.tr'deki güncel metin ve ders notlarınla karşılaştır. Sağdaki ve soldaki boşluklar not almak içindir.</div>
`,
});
