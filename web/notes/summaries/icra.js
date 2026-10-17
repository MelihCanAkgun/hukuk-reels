'use strict';
/*
 * İcra Hukuku şema özeti (2. sürüm). Sayfa genişliği sabittir (820 birim
 * içerik sütunu). Metin değişince `version` artırılır: notes.js eski notları
 * ait oldukları bloğun yeni yerine taşır (değişen bloklarda komşulara göre).
 * 1. sürümün metni, eski notları taşımak için icra.v1.js'de dondurulmuştur.
 *
 * Kaynak: mevzuat.gov.tr'deki güncel İİK metni (7589 sayılı Kanunla yapılan
 * 31.7.2026 tarihli değişiklik dahil); TBK, TMK, HMK ve Çocuk Koruma Kanunu.
 *
 * Renkler: .daire İcra Dairesi · .mah İcra Mahkemesi · .gen Genel Mahkeme
 *          .borclu borçlunun / ilgilinin işlemi · .q karar noktası
 */
window.hukukNotesRegister({
  id: 'icra',
  title: 'İcra Hukuku',
  version: 2,
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
  <div class="stamp">Güncel metin esas alındı: 7589 sayılı Kanunla yapılan değişiklik dahil (31.7.2026)</div>
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
  <li><b>2004 sayılı İcra ve İflas Kanunu (İİK)</b> — temel kaynak</li>
  <li><b>İcra ve İflas Kanunu Yönetmeliği</b> — örnek formlar, uygulama ayrıntıları</li>
  <li><b>Yardımcı kanunlar:</b> HMK (yargılama usulü), TBK ve TMK (maddi hukuk), TTK (kambiyo senetleri), 492 sayılı Harçlar Kanunu, Çocuk Koruma Kanunu (çocuk teslimi, m.41/A vd.)</li>
  <li><b>Kamu alacakları</b> kural olarak İİK ile değil, 6183 sayılı Kanunla takip edilir</li>
  <li><b>Yargı kararları</b> — Yargıtay ve bölge adliye mahkemesi kararları uygulamada yön gösterir</li>
</ul>
<h4>Son önemli değişiklikler</h4>
<table class="tb">
  <tr><th>Kanun</th><th>Başlıca değişiklik</th></tr>
  <tr><td>7343 (2021)</td><td>İcra daireleri başkanlığı <i class="m">3/a</i> · çocuk teslimi Çocuk Koruma Kanununa geçti (<i class="m">25</i> <i class="m">25/a</i> <i class="m">25/b</i> <i class="m">341</i> mülga) · tehiri icrada geri bırakma kararını icra mahkemesi verir <i class="m">36</i> · satış hükümleri yenilendi, <i class="m">133</i> mülga</td></tr>
  <tr><td>7445 (2023)</td><td>Konutta haciz için icra mahkemesi onayı <i class="m">79/a</i> · ev eşyasının haczedilmezliği genişledi <i class="m">82</i> · alacağı aşan haciz yasağı <i class="m">85</i> · muhafazasına gerek kalmayan malların tasfiyesi <i class="m">88/a</i></td></tr>
  <tr><td>7499 (2024)</td><td>Hafta olarak belirlenen sürelerin hesabı <i class="m">19</i> · tazyik ve disiplin hapsine itiraz ile istinaf ve temyiz süresi tebliğden itibaren <b>2 hafta</b> <i class="m">353</i> <i class="m">363</i> <i class="m">364</i></td></tr>
  <tr><td>7571 (2025)</td><td>İvazsız tasarrufların iptali yeniden düzenlendi, süre <b>1 yıl</b> <i class="m">278</i> · ihalenin feshinde yetkisiz başvurular dosya üzerinden kesin reddedilir <i class="m">134</i> · istinaf ve temyiz sınırında başvuru tarihi esas <i class="m x">Ek m.1</i></td></tr>
  <tr><td>7589 (2026)</td><td>Mirasçılar arasında ortaklığın giderilmesi satışında birinci artırma yalnız malik mirasçılar arasında yapılır <i class="m">114</i></td></tr>
</table>
<h4>Takibin temel kavramları</h4>
<table class="tb">
  <tr><th>Kavram</th><th>Anlamı</th></tr>
  <tr><td>Takip talebi</td><td>Alacaklının icra dairesine başvurusu; takibi başlatır</td></tr>
  <tr><td>Ödeme emri</td><td>İlamsız takipte borçluya gönderilen, ödemeye ya da itiraza davet eden belge</td></tr>
  <tr><td>İcra emri</td><td>İlamlı takipte borçluya gönderilen, ilamın gereğini yerine getirme emri</td></tr>
  <tr><td>Kesinleşme</td><td>Süresinde itiraz edilmemesi veya itirazın kaldırılması/iptali ile takibin hacze hazır hâle gelmesi</td></tr>
  <tr><td>Haciz</td><td>Borçlunun malına el konularak tasarruf yetkisinin sınırlandırılması</td></tr>
  <tr><td>Paraya çevirme</td><td>Haczedilen malın satılması (ihale)</td></tr>
  <tr><td>Paylaştırma</td><td>Satış bedelinin alacaklılara sıraya göre dağıtılması</td></tr>
</table>
<h4>Sürelerin hesabı <i class="m">19</i> · <i class="m">20</i></h4>
<ul>
  <li>Gün olarak belirlenen sürelerde <b>ilk gün hesaba katılmaz</b>.</li>
  <li>Ay ve yıl süreleri, başladığı güne karşılık gelen günde biter (o ayda böyle bir gün yoksa ayın son günü); hafta süreleri son haftada başladığı güne karşılık gelen günde biter.</li>
  <li>Son gün resmî tatile rastlarsa süre tatili izleyen gün biter; süre son günün tatil saatinde biter. Elektronik ortamda yapılan işlemlerde süre <b>gün sonunda</b> biter <i class="m">8/a</i>.</li>
  <li>Kanundaki süreleri değiştiren sözleşmeler hükümsüzdür; ancak bir sürenin geçmesinden yararlanacak borçlu bu haktan vazgeçebilir <i class="m">20</i>.</li>
</ul>

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
          <li><span class="tn">Rehnin paraya çevrilmesi yoluyla ilamsız takip <i class="m">145 vd.</i> · <i class="m">149/b</i></span></li>
          <li><span class="tn">İflas yolu <span class="d">— bu dersin kapsamı dışında</span></span></li>
        </ul>
      </li>
      <li><span class="tn a">İlamlı takip <i class="m">24 vd.</i> <span class="d">— mahkeme kararı ya da ilam niteliğinde belge</span></span>
        <ul>
          <li><span class="tn">Para ve teminat <i class="m">32</i></span></li>
          <li><span class="tn">Taşınır teslimi <i class="m">24</i> · Taşınmaz tahliyesi ve teslimi <i class="m">26</i></span></li>
          <li><span class="tn">Bir işin yapılması veya yapılmaması <i class="m">30</i> · İrtifak <i class="m">31</i></span></li>
          <li><span class="tn">İlam niteliğindeki belgeler <i class="m">38</i> · İpotek akit tablosu <i class="m">149</i></span></li>
          <li><span class="tn">Çocuk teslimi ve kişisel ilişki <span class="d">— Çocuk Koruma Kanunu m.41/A vd.; İİK m.25 mülga</span></span></li>
        </ul>
      </li>
    </ul>
  </li>
</ul>
<div class="flow">
  <div class="n q">Hangi yolu seçmeliyim?</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="cap">Mahkeme kararı var mı?</div><div class="n">Varsa <b>ilamlı takip</b> <i class="m">24 vd.</i></div></div>
    <div class="col"><div class="cap">Alacak rehinle güvenceli mi?</div><div class="n">Kural: önce <b>rehnin paraya çevrilmesi</b> <i class="m">45</i><span class="d">istisna: kambiyo senedi, konut finansmanı ve TOKİ alacakları, ipotekli faiz ve yıllık taksitler</span></div></div>
    <div class="col"><div class="cap">Kambiyo senedi var mı?</div><div class="n">Seçimlik: <b>kambiyo yolu</b> ya da genel haciz<span class="d">alacak rehinle güvenceli olsa bile <i class="m">167</i></span></div></div>
  </div>
</div>

<!-- 3 -->
<h2 class="sec" id="s-teskilat"><span class="no">3</span><span class="tt">İcra teşkilatı</span></h2>
<div class="grid2">
  <div class="card daire"><h5>İcra Dairesi <i class="m">1</i></h5>
    <ul><li>Her asliye mahkemesinin yargı çevresinde yeteri kadar bulunur; takibi <b>yürüten</b> idari organdır</li><li>İcra müdürü, yardımcıları ve kâtipler; iş yoğunluğunda icra başmüdürü</li><li>Ödeme/icra emri gönderir, haciz yapar, satar, paylaştırır</li><li>Genel haciz yolunda <b>ödeme emrine itiraz buraya</b> yapılır</li></ul></div>
  <div class="card mah"><h5>İcra Mahkemesi <i class="m">4</i></h5>
    <ul><li>Tek hâkimli <b>yargı organı</b>; daire işlemlerine karşı şikâyet ve itirazları inceler</li><li>İtirazın kaldırılması, icranın geri bırakılması, istihkak davası, ihalenin feshi, sıra cetveli, kambiyo itirazları</li><li>İvedi iş, <b>basit yargılama</b> <i class="m">18</i>; duruşmasız işlerde en geç <b>10 gün</b> içinde karar</li></ul></div>
  <div class="card"><h5>Gözetim ve denetim <i class="m">3/a</i> · <i class="m">13</i></h5>
    <ul><li>İcra daireleri başkanlığı (7343) dairelerin gözetim ve denetimini yapar, idari işlerine bakar</li><li>Başkanlık kurulmayan yerlerde icra mahkemesi hâkimi</li><li>Cumhuriyet savcıları daireleri yılda en az bir kez denetler</li></ul></div>
  <div class="card gen"><h5>Genel Mahkemeler</h5>
    <ul><li>Borcun <b>esası</b> hakkında tam yargılama</li><li>İtirazın iptali <i class="m">67</i>, borçtan kurtulma <i class="m">69</i>, menfi tespit ve istirdat <i class="m">72</i>, iptal davaları <i class="m">277 vd.</i></li><li>İhtiyati haciz kararı <i class="m">258</i> · Devlet aleyhine tazminat davası <i class="m">5</i></li></ul></div>
  <div class="card ceza"><h5>İcra Mahkemesi — ceza işleri <i class="m">346</i></h5>
    <ul><li>İcra suçlarına ilişkin davalar ile tazyik ve disiplin hapsi kararları; uygulamada <b>icra ceza mahkemesi</b> diye anılır</li><li>Bkz. 18. bölüm</li></ul></div>
  <div class="card"><h5>Elektronik işlemler <i class="m">8/a</i></h5>
    <ul><li>Bütün icra işlemleri UYAP üzerinden yürür; güvenli elektronik imza, elle atılan imzayla aynı ispat gücündedir</li><li>Alacaklı borçlunun mal, hak ve alacaklarını UYAP'tan sorgulayabilir <i class="m">78</i></li></ul></div>
</div>
<div class="box warn"><b>Devletin sorumluluğu <i class="m">5</i>:</b> İcra ve iflas dairesi görevlilerinin kusurlarından doğan tazminat davaları ancak <b>idare (Devlet) aleyhine</b> açılabilir; Devlet kusurlu görevliye rücu eder. Bu davalara <b>adliye mahkemeleri</b> bakar.</div>
<h4>Yetki <i class="m">50</i></h4>
<ul>
  <li>Para ve teminat takiplerinde <b>HMK'nın yetki kuralları</b> kıyasen uygulanır (borçlunun yerleşim yeri, sözleşmenin ifa yeri vb.); ayrıca takibe esas <b>sözleşmenin yapıldığı yer</b> icra dairesi de yetkilidir.</li>
  <li>Yetki itirazı <b>esasa ilişkin itirazla birlikte</b> yapılır; icra mahkemesi önce yetkiyi inceler ve kesin olarak karara bağlar.</li>
  <li>İlamların icrası <b>her icra dairesinden</b> istenebilir <i class="m">34</i>.</li>
</ul>
<h4>Kanun yolları <i class="m">363</i> · <i class="m">364</i></h4>
<table class="tb">
  <tr><th>Karar</th><th>Kanun yolu</th><th>Süre ve etkisi</th></tr>
  <tr><td>İcra mahkemesi kararları</td><td>İstinaf (bölge adliye mahkemesi)</td><td>Tebliğden itibaren <b class="t">2 hafta</b> · satıştan başka icra işlemlerini durdurmaz</td></tr>
  <tr><td>Bölge adliye mahkemesi kararları</td><td>Temyiz (Yargıtay)</td><td>Tebliğden itibaren <b class="t">2 hafta</b> · satıştan başka icra işlemlerini durdurmaz</td></tr>
</table>
<div class="box tip"><b>Kesin kararlar ve parasal sınır:</b> Kıymet takdirine ilişkin şikâyet, satışın durdurulması ve m.36'ya göre icranın geri bırakılması gibi kanunda sayılan kararlara karşı istinaf yolu kapalıdır; diğerlerinde kanundaki parasal sınır aranır. Sınırlar her yıl güncellenir; şikâyetin ya da davanın yapıldığı tarihteki miktar esas alınır <i class="m x">Ek m.1</i>.</div>

<!-- 4 -->
<h2 class="sec" id="s-sikayet"><span class="no">4</span><span class="tt">Şikâyet</span><span class="m"><i class="m">16–18</i> · <i class="m">22</i></span></h2>
<div class="flow">
  <div class="n start">İcra/iflas dairesinin kanuna veya olaya uygun olmayan işlemi<span class="d">ya da bir hakkın yerine getirilmemesi / sebepsiz sürüncemede bırakılması</span></div>
  <div class="n borclu"><span class="k">İlgili (alacaklı, borçlu, menfaati zedelenen 3. kişi)</span>Şikâyet <b class="t">7 gün</b><span class="d">işlemin öğrenildiği tarihten · <b>icra mahkemesine</b></span></div>
  <div class="n mah"><span class="k">İcra Mahkemesi</span>Basit yargılama; duruşma yapıp yapmamayı takdir eder <i class="m">18</i><span class="d">Şikâyet, icra mahkemesi karar vermedikçe <b>icrayı durdurmaz</b> <i class="m">22</i>; mahkeme durdurma kararı verebilir.</span></div>
  <div class="split" style="--n:2">
    <div class="col"><div class="n end">Kabul: işlem <b>bozulur / düzeltilir</b><span class="d">yapılmayan ya da geciktirilen işin yapılması emredilir <i class="m">17</i></span></div></div>
    <div class="col"><div class="n stop">Ret: işlem geçerli kalır</div></div>
  </div>
</div>
<div class="grid2">
  <div class="card"><h5>Süreli şikâyet — <b class="t">7 gün</b> <i class="m">16/1</i></h5>İşlemin kanuna ya da olaya uygun olmaması (ör. haczedilmezlik, usulsüz tebligat). Kanunun mahkemeye bıraktığı konular — özellikle <b>borcun esası</b> — şikâyetle ileri sürülemez.</div>
  <div class="card"><h5>Süresiz şikâyet <i class="m">16/2</i></h5>
    <ul><li>Bir hakkın yerine getirilmemesi</li><li>Sebepsiz sürüncemede bırakma</li><li>Yerleşik içtihatla: kamu düzenine aykırı veya <b>yok hükmündeki</b> işlemler</li></ul></div>
</div>
<table class="tb cmp">
  <tr><th></th><th>Şikâyet</th><th>İtiraz (ödeme emrine)</th></tr>
  <tr><td>Konu</td><td>İşlemin usule veya hukuka aykırılığı</td><td>Borcun esası, imza, yetki</td></tr>
  <tr><td>Merci</td><td class="c-m">İcra Mahkemesi</td><td class="c-d">İcra Dairesi</td></tr>
  <tr><td>Süre</td><td>7 gün (bazen süresiz)</td><td>7 gün</td></tr>
  <tr><td>Takibe etkisi</td><td>Kendiliğinden durdurmaz <i class="m">22</i></td><td>Takip durur <i class="m">66</i></td></tr>
</table>

<!-- 5 -->
<h2 class="sec" id="s-harc"><span class="no">5</span><span class="tt">İcra harç ve giderleri</span><span class="m"><i class="m">59</i> · <i class="m">138</i></span></h2>
<div class="flow">
  <div class="n s daire"><span class="k">Takip talebi ile</span>Başvurma harcı ve peşin harç<span class="d">492 sayılı Harçlar Kanunu tarifesine göre</span></div>
  <div class="n s daire"><span class="k">Takip süresince</span>Tebligat, haciz, muhafaza, ilan, satış giderleri<span class="d">Alacaklı, istediği işlemin giderini ve borçlunun itirazının kendisine tebliğ giderini <b>avans olarak peşin</b> öder <i class="m">59</i></span></div>
  <div class="n s daire"><span class="k">Tahsil sırasında</span>Tahsil harcı<span class="d">Tahsil edilen paradan alınır</span></div>
  <div class="n end s">Takip giderleri sonuçta <b>borçluya</b> aittir <i class="m">59</i><span class="d">Alacaklı ilk ödenen paradan giderlerini alabilir.</span></div>
</div>
<div class="box tip"><b>Akılda tut:</b> Gider avansı verilmezse istenen işlem yapılmaz; satış talebinde kıymet takdiri ve satış giderleri peşin yatırılmazsa talep hiç yapılmamış sayılır <i class="m">106</i>. Bütün alacaklıları ilgilendiren haciz, paraya çevirme ve paylaştırma giderleri satış bedelinden önce alınır; vekâlet ücreti tarifeye göre icra müdürünce hesaplanır ve takip giderlerine dahildir <i class="m">138</i>. Adli yardımdan yararlanan, harç ve giderleri ödemeden takip yapabilir.</div>

<!-- 6 -->
<h2 class="sec" id="s-taraflar"><span class="no">6</span><span class="tt">İcra takibinin tarafları</span></h2>
<div class="grid2">
  <div class="card"><h5>Alacaklı</h5>Takibi başlatan; alacağın sahibi ya da halefi (devralan, mirasçı).</div>
  <div class="card"><h5>Borçlu</h5>Aleyhine takip yapılan; ölmüşse terekesi ya da mirasçıları <i class="m">53</i>.</div>
</div>
<table class="tb">
  <tr><th>Ehliyet</th><th>Kimde?</th><th>Yoksa?</th></tr>
  <tr><td>Takipte taraf ehliyeti</td><td>Hak ehliyeti olan herkes (gerçek ve tüzel kişiler)</td><td>Takip yapılamaz; işlemler yok hükmünde</td></tr>
  <tr><td>Takip ehliyeti</td><td>Fiil ehliyeti olanlar</td><td>Kanuni temsilci aracılığıyla takip</td></tr>
</table>
<ul>
  <li><b>Temsil:</b> kanuni temsilci (veli, vasi) ya da vekil (avukat). Tüzel kişiyi organı temsil eder.</li>
  <li><b>Takip arkadaşlığı:</b> birden çok alacaklı veya borçlu aynı takipte yer alabilir; müşterek borçlulardan her birine ayrı ödeme emri tebliğ edilir <i class="m">61</i>.</li>
</ul>
<h4>Takip yapılamayan zamanlar ve erteleme <i class="m">51–56</i></h4>
<table class="tb">
  <tr><th>Durum</th><th>Kural</th></tr>
  <tr><td>Gece ve tatil <i class="m">51</i></td><td>Gece (güneş batışından 1 saat sonra ile doğuşundan 1 saat önce arası) ve tatil günlerinde takip işlemi yapılamaz. Tatil günlerinde haciz, tebligat ve muhafaza yapılabilir; borçlu mal kaçırıyorsa gece de haciz yapılır.</td></tr>
  <tr><td>Yakının ölümü <i class="m">52</i></td><td>Eşi, usul veya füruundan biri ölen borçluya karşı takip, ölüm günüyle birlikte <b class="t">3 gün</b> durur.</td></tr>
  <tr><td>Borçlunun ölümü <i class="m">53</i></td><td>Tereke borçları için takip ölüm günüyle birlikte <b class="t">3 gün</b> durur; mirasçılar mirası kabul ya da ret etmemişse TMK'daki ret süresi (3 ay, TMK 606) dolana kadar bekler. Tereke paylaşılmamışsa takip <b>terekeye karşı</b> sürer; mirasçıya karşı ancak rehnin paraya çevrilmesi veya haciz yoluyla devam edebilir.</td></tr>
  <tr><td>Tutukluluk, hükümlülük <i class="m">54</i></td><td>Temsilcisi olmayan borçluya temsilci bulması için uygun süre verilir; mal kaçırma ihtimali varsa bu sürede de haciz yapılabilir.</td></tr>
  <tr><td>Ağır hastalık <i class="m">55</i></td><td>Resmî belgeyle kanıtlanırsa takip belli bir süre ertelenebilir; mal kaçırma ihtimalinde haciz yapılabilir.</td></tr>
  <tr><td>Erteleme ve süreler <i class="m">56</i></td><td>Erteleme sırasında süreler <b>işlemeye devam eder</b>; son gün erteleme süresine rastlarsa süre ertelemenin bitiminden sonra bir gün uzar.</td></tr>
</table>

<!-- 7 -->
<h2 class="sec" id="s-ilamsiz"><span class="no">7</span><span class="tt">Genel haciz yoluyla ilamsız takip</span><span class="m"><i class="m">58–77</i></span></h2>
<div class="flow">
  <div class="n start">Takip talebi <i class="m">58</i><span class="d">yazılı, sözlü ya da elektronik ortamda · tarafların kimliği · alacağın Türk parası tutarı ve faizi · senet ya da borcun sebebi · seçilen takip yolu · belgeye dayanıyorsa aslı ya da onaylı örneği</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Ödeme emri düzenlenir <i class="m">60</i> ve en geç <b class="t">3 gün</b> içinde tebliğe çıkarılır <i class="m">61</i><span class="d">Ödeme <b class="t">7 gün</b> · itiraz <b class="t">7 gün</b> · imzaya itirazın açıkça yapılması gerektiği · mal beyanı ihtarı</span></div>
  <div class="n q">Borçlu 7 gün içinde ne yapar?</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="cap">Öder</div><div class="n end">Takip sona erer</div></div>
    <div class="col"><div class="cap">Susar</div><div class="n daire">Takip <b>kesinleşir</b><span class="d">→ mal beyanı · haciz istenebilir (9. bölüm)</span></div></div>
    <div class="col"><div class="cap">İtiraz eder <i class="m">62</i></div><div class="n borclu">İcra dairesine, <b>yazılı veya sözlü</b><span class="d">borca · imzaya · yetkiye</span></div><div class="n stop">Takip <b>durur</b> <i class="m">66</i><span class="d">kısmi itirazda kabul edilen kısım için devam eder</span></div></div>
  </div>
  <div class="n q w">Alacaklı itirazı nasıl aşar? → 8. bölüm</div>
  <div class="split flat" style="--n:2">
    <div class="col"><div class="n mah"><span class="k">İcra Mahkemesi</span>İtirazın kaldırılması <i class="m">68</i> · <i class="m">68/a</i><span class="d"><b class="t">6 ay</b> · belgeli alacaklar</span></div></div>
    <div class="col"><div class="n gen"><span class="k">Genel Mahkeme</span>İtirazın iptali davası <i class="m">67</i><span class="d"><b class="t">1 yıl</b> · her türlü delil</span></div></div>
  </div>
</div>
<h4>İtiraz ayrıntıları <i class="m">62–66</i></h4>
<ul>
  <li>Genel haciz yolunda itiraz için sebep göstermek zorunlu değildir; ama <b>imzaya itiraz ayrıca ve açıkça</b> yapılmalıdır — aksi hâlde senetteki imza takip bakımından kabul edilmiş sayılır.</li>
  <li><b>Kısmi itiraz:</b> itiraz edilen kısım açıkça gösterilmelidir, aksi hâlde itiraz edilmemiş sayılır; kabul edilen kısım için takip devam eder.</li>
  <li>İtiraz başka bir icra dairesine de yapılabilir; o daire itirazı derhâl yetkili daireye gönderir. Borçlu itirazla birlikte yurt içinde bir adres bildirir. İtiraz alacaklıya <b class="t">3 gün</b> içinde tebliğ edilir.</li>
  <li>Borçlu, itirazın kaldırılması duruşmasında itiraz sebeplerini <b>değiştiremez ve genişletemez</b> <i class="m">63</i>.</li>
  <li><b>Yetki itirazı</b> esasa ilişkin itirazla birlikte yapılır <i class="m">50</i>.</li>
  <li><b>Gecikmiş itiraz <i class="m">65</i>:</b> kusuru olmadan bir engel yüzünden süreyi kaçıran borçlu, engelin kalktığı günden itibaren <b class="t">3 gün</b> içinde ve paraya çevirme bitinceye kadar icra mahkemesine başvurur; mazeret kabul edilirse takip durur.</li>
</ul>
<h4>Mal beyanı <i class="m">74–77</i></h4>
<div class="box warn"><b>Mal beyanı yükümlülüğü:</b> İtiraz etmeyen borçlu ödeme süresi içinde; itirazı kaldırılan ya da iptal edilen borçlu kararın tebliğinden (yüzüne karşı verilmişse tefhiminden) itibaren <b class="t">3 gün</b> içinde mallarını, alacaklarını ve gelirlerini bildirir <i class="m">74</i> · <i class="m">75</i>. Beyanda bulunmayan borçlu, alacaklının talebiyle beyanda bulununcaya kadar <b>bir defaya mahsus</b> ve en çok <b>3 ay</b> tazyik hapsiyle zorlanır <i class="m">76</i>. Gerçeğe aykırı beyan suçtur <i class="m">338</i>. Sonradan edinilen mallar <b class="t">7 gün</b> içinde bildirilir <i class="m">77</i>.</div>

<!-- 8 -->
<h2 class="sec" id="s-itiraz"><span class="no">8</span><span class="tt">İtirazın iptali, itirazın kaldırılması ve borçlunun davaları</span></h2>
<table class="tb cmp">
  <tr><th></th><th>İtirazın kaldırılması <i class="m">68</i></th><th>İtirazın iptali <i class="m">67</i></th></tr>
  <tr><td>Merci</td><td class="c-m">İcra Mahkemesi</td><td class="c-g">Genel Mahkeme</td></tr>
  <tr><td>Süre</td><td><b class="t">6 ay</b> itirazın tebliğinden · kaçırılırsa aynı alacak için <b>yeniden ilamsız takip yapılamaz</b></td><td><b class="t">1 yıl</b> itirazın tebliğinden · kaçırılırsa genel hükümlere göre <b>alacak davası</b> açılabilir</td></tr>
  <tr><td>Belge</td><td>Yalnız m.68'deki belgeler: imzası ikrar edilmiş ya da noterce onaylanmış borç ikrarı içeren senet; resmî dairenin ya da yetkili makamın yetkisi içinde usulüne göre verdiği makbuz veya belge; kredi sözleşmeleri ve itiraz edilmemiş hesap özetleri <i class="m">68/b</i></td><td>Her türlü delil</td></tr>
  <tr><td>Borçlunun savunması</td><td>İtirazını ancak aynı nitelikte bir belgeyle haklı gösterebilir</td><td>Genel hükümler</td></tr>
  <tr><td>Yargılama</td><td>Basit yargılama, belgeyle sınırlı inceleme</td><td>Genel hükümler, tam yargılama</td></tr>
  <tr><td>Kararın niteliği</td><td>Yalnız takip hukuku bakımından sonuç doğurur; borcun varlığı hakkında <b>maddi anlamda kesin hüküm değildir</b></td><td>Borcun varlığı hakkında <b>kesin hüküm</b></td></tr>
  <tr><td>Kabulün sonucu</td><td colspan="2">Takip <b>kaldığı yerden devam eder</b>; borçlu <b class="t">3 gün</b> içinde mal beyanında bulunur <i class="m">75</i>, alacaklı haciz isteyebilir</td></tr>
  <tr><td>Tazminat</td><td>Talep esasa ilişkin nedenle kabul edilirse borçlu, aynı nedenle reddedilirse alacaklı; en az <b>%20</b> · kötü niyet aranmaz</td><td>İtirazı haksız bulunan borçlu; takibi haksız <b>ve kötü niyetli</b> alacaklı; en az <b>%20</b> · borçlu veli, vasi ya da mirasçıysa kötü niyet şartı</td></tr>
</table>
<div class="box tip"><b>Seçim:</b> Elinde m.68 belgesi olan alacaklı için icra mahkemesi hızlıdır; ancak 6 aylık süre kaçarsa aynı alacak için yeniden ilamsız takip yapılamaz. Belge yoksa ya da borcun esası tartışmalıysa 1 yıl içinde itirazın iptali davası açılır; bu süre de kaçarsa genel hükümlere göre alacak davası açılabilir <i class="m">67</i>.</div>
<h3>İmzaya itiraz: itirazın geçici kaldırılması <i class="m">68/a</i> · <i class="m">69</i></h3>
<div class="flow">
  <div class="n borclu">Takip adi senede dayanıyor, borçlu <b>imzayı açıkça reddetti</b></div>
  <div class="n mah"><span class="k">İcra Mahkemesi</span>İtirazın geçici kaldırılması <b class="t">6 ay</b><span class="d">İmza incelemesi yapılır · imzayı reddeden borçlu duruşmaya bizzat gelmek zorundadır; mazeretsiz gelmezse itiraz geçici olarak kaldırılır</span></div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">İmza borçlunun</div><div class="n end">İtiraz geçici kaldırılır<span class="d">borçluya alacağın <b>%10'u</b> para cezası · alacaklı isterse geçici haciz <i class="m">69</i></span></div></div>
    <div class="col"><div class="cap">İmza borçlunun değil</div><div class="n stop">Talep reddedilir<span class="d">alacaklı en az <b>%20</b> tazminat öder (kabulde borçlu öder)</span></div></div>
  </div>
  <div class="n gen"><span class="k">Borçlu → Genel Mahkeme</span>Borçtan kurtulma davası <b class="t">7 gün</b> <i class="m">69</i><span class="d">kararın tefhim ya da tebliğinden · dava konusu alacağın <b>%15'i</b> ilk duruşmaya kadar yatırılmazsa dava reddedilir</span></div>
  <div class="n end">Dava açılmaz ya da reddedilirse geçici kaldırma ve geçici haciz <b>kesinleşir</b><span class="d">davada haksız çıkan taraf en az <b>%20</b> tazminat öder</span></div>
</div>
<div class="box def"><b>Kesinleşmeden sonra: takibin iptali veya ertelenmesi <i class="m">71</i>:</b> Takip kesinleştikten sonra borcun faiz ve giderleriyle ödendiğini (itfa) ya da alacaklının süre verdiğini (imhal) noterce onaylı veya imzası ikrar edilmiş bir belgeyle ispat eden borçlu, icra mahkemesinden her zaman takibin iptalini ya da ertelenmesini isteyebilir; zamanaşımı iddiasında m.33/a kıyasen uygulanır.</div>
<h3>Borçlunun açabileceği davalar <i class="m">72</i></h3>
<div class="flow">
  <div class="n q">Borçlu borçlu olmadığını nasıl ileri sürer?</div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">Henüz ödemediyse</div><div class="n gen"><span class="k">Genel Mahkeme</span>Menfi tespit davası<span class="d">Takipten önce açılırsa alacağın en az <b>%15'i</b> teminatla takibin durdurulması için tedbir istenebilir. Takipten sonra açılırsa takip durdurulamaz; aynı teminatla yalnız paranın alacaklıya ödenmemesi istenebilir. Borçlu kazanırsa takip durur, icra eski hâline getirilir.</span></div></div>
    <div class="col"><div class="cap">Ödemek zorunda kaldıysa</div><div class="n gen"><span class="k">Genel Mahkeme</span>İstirdat davası<span class="d">Paranın <b>tamamen ödendiği tarihten</b> itibaren <b class="t">1 yıl</b> · borçlu yalnız paranın verilmesi gerekmediğini ispat eder · tedbir alınmadan para ödenirse menfi tespit davası istirdat davası olarak sürer</span></div></div>
  </div>
</div>
<div class="box warn"><b>Tazminat ve yetki:</b> Menfi tespit davası alacaklı lehine biterse alacaklının gecikme zararı teminattan alınır (en az %20); borçlu lehine biterse ve takip haksız ve kötü niyetliyse alacaklı en az %20 tazminat öder. Davalar takibin yapıldığı yer mahkemesinde ya da davalının yerleşim yeri mahkemesinde açılabilir.</div>

<!-- 9 -->
<h2 class="sec" id="s-haciz"><span class="no">9</span><span class="tt">Haciz safhası</span><span class="m"><i class="m">78–105</i></span></h2>
<div class="flow">
  <div class="n start">Takip kesinleşti</div>
  <div class="n daire"><span class="k">Alacaklı → İcra Dairesi</span>Haciz talebi <i class="m">78</i><span class="d">Mal beyanı beklenmez; UYAP'ta mal sorgulaması yapılıp elektronik haciz istenebilir · ödeme emrinin tebliğinden itibaren <b class="t">1 yıl</b>; itiraz ve dava süresi ile icra dairesindeki taksit sözleşmesinin ihlaline kadar geçen süre sayılmaz · süresinde istenmezse dosya işlemden kaldırılır</span></div>
  <div class="n daire"><span class="k">İcra memuru</span>Haciz <i class="m">79–85</i><span class="d">Talepten en geç <b class="t">3 gün</b> içinde <i class="m">79</i> · alacak, faiz ve giderlere <b>yetecek kadar</b> mal haczedilir, bu miktar aşılamaz <i class="m">85</i></span></div>
  <div class="n q w">Mal kimin elinde? Üçüncü kişi mülkiyet ya da rehin hakkı iddia ediyor mu?</div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">Borçlunun elinde <i class="m">96–97</i></div>
      <div class="n daire">İddia tutanağa geçirilir; alacaklıya ve borçluya itiraz için <b class="t">3 gün</b><span class="d">susarlarsa iddiayı kabul etmiş sayılırlar</span></div>
      <div class="n mah"><span class="k">İcra Mahkemesi</span>İtiraz edilirse takibin devamına ya da ertelenmesine karar<span class="d">devam kararı kesindir · erteleme için davacıdan teminat alınır</span></div>
      <div class="n mah"><span class="k">3. kişi → İcra Mahkemesi</span>İstihkak davası <b class="t">7 gün</b><span class="d">kararın tefhim ya da tebliğinden · açılmazsa iddiasından vazgeçmiş sayılır</span></div>
    </div>
    <div class="col"><div class="cap">3. kişinin elinde <i class="m">99</i></div>
      <div class="n daire">Yedieminliği kabul ederse mal muhafazaya alınmaz; alacaklıya <b class="t">7 gün</b> süre verilir</div>
      <div class="n mah"><span class="k">Alacaklı → İcra Mahkemesi</span>İstihkak davası <b class="t">7 gün</b><span class="d">açılmazsa 3. kişinin iddiası kabul edilmiş sayılır · dava sonuçlanıncaya kadar <b>satış yapılamaz</b></span></div>
    </div>
  </div>
</div>
<div class="box def"><b>İstihkak davası:</b> <b>İcra mahkemesinde</b>, genel hükümlere ve basit yargılama usulüne göre görülür <i class="m">97</i>. Haczi öğrenen borçlu ya da 3. kişi <b class="t">7 gün</b> içinde istihkak iddiasında bulunmazsa aynı takipte bu hakkı kaybeder <i class="m">96</i>. Taşınırı elinde bulunduran malik sayılır; borçlu ile birlikte bulundurulan mal borçlunun elinde sayılır <i class="m">97/a</i>. Takip ertelenmiş ve dava reddedilmişse davacı en az <b>%20</b>; dava kabul edilmiş ve itiraz eden kötü niyetliyse itiraz eden en az <b>%15</b> tazminat öder.</div>
<div class="box warn"><b>Konutta haciz <i class="m">79/a</i>:</b> Haciz yapılacak yer konutsa icra müdürünün kararı icra mahkemesinin onayına sunulur; mahkeme en geç <b class="t">3 gün</b> içinde dosya üzerinden kesin karar verir. Bu kural ihtiyati hacizde uygulanmaz.</div>
<h3>Haczedilemeyen mallar <i class="m">82–83</i></h3>
<div class="grid2">
  <div class="card"><h5>Haczedilemez <i class="m">82</i></h5><ul><li>Devlet malları ve özel kanunlarda haczi yasaklanan mallar</li><li>Borçlu ve aynı çatı altında yaşayan aile bireylerinin kişisel eşyası ile ailenin ortak kullanımındaki <b>tüm ev eşyası</b> (para, kıymetli evrak, altın, değerli taş, antika, süs eşyası gibi kıymetli şeyler hariç)</li><li>Bedenî çalışmasıyla geçinen borçlunun mesleği için gerekli eşya</li><li>Borçlunun <b>haline münasip evi</b></li><li>Vücut ve sağlık zararı için ödenen tazminatlar · öğrenci bursları · bazı sosyal yardım ve malullük aylıkları</li></ul></div>
  <div class="card"><h5>Kısmen haczedilebilir <i class="m">83</i></h5>Maaş, ücret, emekli aylığı, ilama dayanmayan nafakalar ve benzeri gelirler, borçlu ile ailesinin geçimi için gerekli miktar indirildikten sonra haczedilir; haczedilecek kısım <b>dörtte birden az olamaz</b>. Birden çok haciz varsa sıraya konur; öndeki haczin kesintisi bitmeden sonrakine geçilmez.</div>
</div>
<div class="box warn"><b>Haczedilmezlik:</b> Borç bu eşyanın bedelinden doğmuşsa meslek eşyası, çiftçi araçları ve haline münasip ev gibi bentlerdeki koruma uygulanmaz; değeri fazla olanlar satılıp bedelin haline münasip kısmı borçluya bırakılır. Haczin caiz olup olmadığına önce icra memuru karar verir; aykırı hacze karşı icra mahkemesine <b class="t">7 gün</b> içinde şikâyet edilir <i class="m">16</i>.</div>
<h3>Üçüncü kişideki alacağın haczi — haciz ihbarnamesi <i class="m">89</i></h3>
<div class="flow">
  <div class="n daire"><span class="k">1. ihbarname</span>Borcunu artık yalnız icra dairesine ödeyebilir<span class="d">3. kişi borcu olmadığı, ödediği gibi itirazlarını <b class="t">7 gün</b> içinde bildirir</span></div>
  <div class="cap">itiraz etmezse borç zimmetinde sayılır</div>
  <div class="n daire"><span class="k">2. ihbarname</span>Borcun zimmetinde sayıldığı bildirilir<span class="d">yine <b class="t">7 gün</b> içinde itiraz edebilir; etmezse borcu ödemesi istenir</span></div>
  <div class="cap">itiraz etmez ve ödemezse</div>
  <div class="n stop"><span class="k">3. bildirim</span><b class="t">15 gün</b> içinde öde ya da menfi tespit davası aç<span class="d">aksi hâlde zimmetindeki borcu ödemeye zorlanır</span></div>
  <div class="n gen"><span class="k">3. kişi → Genel Mahkeme</span>Menfi tespit davası<span class="d">takibin yapıldığı ya da 3. kişinin yerleşim yeri mahkemesinde · davayı açtığını gösteren belgeyi <b class="t">20 gün</b> içinde icra dairesine verirse cebri icra durur · davayı kaybederse en az <b>%20</b> tazminat</span></div>
</div>
<div class="box tip"><b>3. kişi itiraz ederse:</b> Alacaklı, cevabın gerçeğe aykırı olduğunu icra mahkemesinde ispatlayarak 3. kişinin cezalandırılmasını (m.338/1) ve tazminata mahkûm edilmesini isteyebilir. Haciz ihbarnameleri ve cevapları UYAP üzerinden de gönderilebilir.</div>
<h3>Haczin sonuçları ve hacze iştirak</h3>
<ul>
  <li>Borçlu haczedilen mal üzerinde alacaklının zararına <b>tasarruf edemez</b>; bu tasarruflar alacaklıya karşı hüküm doğurmaz.</li>
  <li><b>Hacze iştirak <i class="m">100</i>:</b> ilk haciz üzerine satılan malın bedeli vezneye girinceye kadar, ilk takipten önceki tarihli aciz belgesi, ilam, resmî ya da onaylı senet veya resmî makbuza dayanan alacaklılar aynı derecede hacze katılır; diğerleri ancak artan bedel için katılabilir.</li>
  <li><b>Takip yapmadan iştirak <i class="m">101</i>:</b> borçlunun eşi, çocukları ve vesayeti altındakiler (evlilik, velayet, vesayetten doğan alacaklar için) ile <b>nafaka ilamına dayanan alacaklı</b>; iştirake <b class="t">7 gün</b> içinde itiraz edilebilir.</li>
  <li>Haczedilecek mal bulunamazsa haciz tutanağı <b>kesin aciz belgesi</b> hükmündedir; malların yetersiz olduğu anlaşılırsa tutanak <b>geçici aciz belgesi</b> yerine geçer <i class="m">105</i>.</li>
</ul>

<!-- 10 -->
<h2 class="sec" id="s-satis"><span class="no">10</span><span class="tt">Paraya çevirme (satış)</span><span class="m"><i class="m">106–134</i></span></h2>
<div class="flow">
  <div class="n start">Mal haczedildi</div>
  <div class="n daire"><span class="k">Alacaklı veya borçlu → İcra Dairesi</span>Satış talebi <i class="m">106</i><span class="d">Taşınır ve taşınmazda hacizden itibaren <b class="t">1 yıl</b> · artırmada satılamazsa satış isteyen alacaklı için <b class="t">1 yıl</b> daha · kıymet takdiri ve satış giderleri peşin yatırılmazsa talep yapılmamış sayılır</span></div>
  <div class="n stop">Süresinde satış istenmez ya da talep geri alınıp süresinde yenilenmezse <b>haciz kalkar</b> <i class="m">110</i><span class="d">Satış talebi yalnız bir defa geri alınabilir · haczin kalkmasına yol açan alacaklı giderlerden sorumludur</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Kıymet takdiri<span class="d">Taşınmazda rapora tebliğden itibaren <b class="t">7 gün</b> içinde icra mahkemesine şikâyet; karar kesindir · kesinleşen takdirden itibaren 2 yıl geçmedikçe yeniden takdir istenemez <i class="m">128/a</i></span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>İlan ve elektronik artırma <i class="m">114</i><span class="d">Artırmadan en az <b class="t">15 gün</b> önce ilan · iki artırma; ikincisi birincinin bitiminden itibaren en geç 1 ay içinde başlar · katılmak için kıymetin <b>%10'u</b> teminat</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>İhale <i class="m">115</i> · <i class="m">129</i><span class="d">Artırma muhammen kıymetin <b>%50'si</b> üzerinden başlar · ihale için teklifin, kıymetin %50'si ile satış isteyenin alacağından önce gelen rehinli alacakların toplamından hangisi fazlaysa onu ve ayrıca paraya çevirme ve paylaştırma giderlerini geçmesi gerekir · teklif verme başladıktan sonra satış talebi geri alınamaz; borç ödenirse satış durur</span></div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">Şartlar sağlanmazsa</div><div class="n stop">İhale yapılamaz<span class="d">ikinci artırmaya geçilir; o da olmazsa alacaklı kalan satış isteme süresi içinde yeni satış günü ister (süre satış talebiyle durmuştu)</span></div></div>
    <div class="col"><div class="cap">İhale yapılırsa</div><div class="n end">Bedel <b class="t">7 gün</b> içinde ödenir <i class="m">118</i> · <i class="m">130</i><span class="d">ödenmezse teminat iade edilmez, hak sahiplerine ödenir · mal ihale kesinleşmeden teslim ve tescil edilmez · taşınmazda mülkiyet ihaleyle geçer <i class="m">134</i></span></div></div>
  </div>
</div>
<div class="box warn"><b>m.133 mülga (7343):</b> İhale bedelini yatırmayan alıcı için eski "ihalenin feshi ve fark" sistemi kaldırıldı; artık alıcının yatırdığı teminat iade edilmez, önce satış giderlerine sonra alacaklılara ödenir <i class="m">115</i>.</div>
<div class="box new"><b>Yeni (7589 · 31.7.2026):</b> Bütün maliklerin mirasla edindiği ve mirasçılar dışında maliki olmayan taşınmazlarda ortaklığın satış yoluyla giderilmesinde birinci artırma <b>yalnız malik mirasçılar arasında</b> ve bir defaya mahsus yapılır <i class="m">114</i>.</div>
<h3>İhalenin feshi <i class="m">134</i></h3>
<div class="flow">
  <div class="n borclu"><span class="k">Kimler isteyebilir?</span>Satış isteyen alacaklı, borçlu, sicilde kayıtlı ilgililer, sınırlı ayni hak sahipleri ve pey sürerek ihaleye katılanlar<span class="d">yurt içinde adres göstermek şartıyla · başkalarının talebi dosya üzerinden kesin olarak reddedilir (7571) · talep eden, yolsuzluk yüzünden menfaatinin zarar gördüğünü ispat etmelidir</span></div>
  <div class="n mah"><span class="k">İcra Mahkemesi</span>Şikâyet yoluyla ihalenin feshi <b class="t">7 gün</b> ihaleden<span class="d">satış ilanı tebliğ edilmemişse ya da esaslı hata veya fesat sonradan öğrenilmişse öğrenmeden · her hâlde ihale kararının e-satış portalında ilanından itibaren <b class="t">1 yıl</b> · talepten itibaren 20 gün içinde duruşma</span></div>
  <div class="split" style="--n:2">
    <div class="col"><div class="n end">Kabul: ihale bozulur</div></div>
    <div class="col"><div class="n stop">Esastan, yetkisiz başvuru ya da feragat nedeniyle ret: talep edene ihale bedelinin <b>%10'una kadar</b> para cezası</div></div>
  </div>
</div>
<div class="box tip"><b>Akılda tut:</b> İhalenin feshi istense bile alıcı bedeli 7 gün içinde öder; para karar kesinleşinceye kadar bankada nemalandırılır. Alacaklı, borçlu, sicildeki ilgililer ve sınırlı ayni hak sahipleri dışındakiler (ör. pey süren katılımcı) için ihale bedeli üzerinden nispi harç (yarısı peşin) ve ihale bedelinin <b>%5'i</b> teminat gerekir; eksikse iki haftalık kesin süre verilir.</div>

<!-- 11 -->
<h2 class="sec" id="s-paylastirma"><span class="no">11</span><span class="tt">Paraların paylaştırılması</span><span class="m"><i class="m">138–143</i></span></h2>
<div class="flow">
  <div class="n daire"><span class="k">İcra Dairesi</span>Önce bütün alacaklıları ilgilendiren giderler alınır <i class="m">138</i><span class="d">haciz, paraya çevirme ve paylaştırma giderleri</span></div>
  <div class="n q">Satış bedeli bütün alacaklara yetiyor mu?</div>
  <div class="split" style="--n:2">
    <div class="col"><div class="cap">Yetiyor</div><div class="n end">Alacaklılara ödenir; artan borçluya verilir</div></div>
    <div class="col"><div class="cap">Yetmiyor</div><div class="n daire"><span class="k">İcra Dairesi</span>Sıra cetveli düzenlenir <i class="m">140</i><span class="d">m.206'daki sıralara göre · ilk üç sıra için haciz talebi tarihi esas alınır</span></div>
      <div class="n mah"><span class="k">İcra Mahkemesi</span>Sıra cetveline itiraz / şikâyet <b class="t">7 gün</b> <i class="m">142</i><span class="d">cetvel suretinin tebliğinden</span></div></div>
  </div>
</div>
<h4>Sıra</h4>
<ol>
  <li><b>Rehinli alacaklılar</b> rehin konusu malın bedelinden önce ödenir.</li>
  <li>Rehinle güvencelenmemiş alacaklar <b>m.206'daki sıralara</b> göre ödenir: birinci sırada işçilerin son bir yıllık alacakları ve son bir yılın nafaka alacakları gibi imtiyazlı alacaklar, son sırada adi (imtiyazsız) alacaklar yer alır.</li>
  <li>Aynı sıradaki alacaklılar <b>garameten</b> (alacakları oranında) pay alır.</li>
</ol>
<div class="grid2">
  <div class="card"><h5>İtiraz mı, şikâyet mi? <i class="m">142</i></h5>Alacağın <b>esasına veya miktarına</b> itiraz: ilgililer aleyhine sıra cetveline itiraz davası (basit yargılama). Yalnız <b>sıraya</b> itiraz: icra mahkemesine şikâyet. İkisi de cetvelin tebliğinden itibaren 7 gün içinde; uygulamada icra mahkemesinde görülür.</div>
  <div class="card"><h5>Teminatla ödeme <i class="m">142/a</i></h5>Sıra cetvelinde hak sahibi görünen alacaklı, bankanın kesin ve süresiz teminat mektubunu vererek payını hemen alabilir.</div>
</div>
<div class="box def"><b>Kesin aciz belgesi <i class="m">143</i>:</b> Satış bedeli alacağı karşılamazsa kalan miktar için düzenlenir; borç ikrarını içeren senet niteliğindedir. Belgedeki alacak için <b>faiz istenemez</b>. Alacaklı <b class="t">1 yıl</b> içinde takibe geçerse yeniden ödeme emri gerekmez. Borç belgenin düzenlenmesinden itibaren <b class="t g">20 yıl</b> geçmekle zamanaşımına uğrar. Aciz belgesi iptal davası açma hakkı verir (m.277; 17. bölüm).</div>

<div class="part"><small>İKİNCİ BÖLÜM</small><div>Özel takip yolları, geçici koruma ve yaptırımlar</div></div>

<!-- 12 -->
<h2 class="sec" id="s-kambiyo"><span class="no">12</span><span class="tt">Kambiyo senetlerine mahsus haciz yolu</span><span class="m"><i class="m">167–170/b</i></span></h2>
<div class="flow">
  <div class="n start">Takip talebi + <b>senedin aslı</b> ve borçlu sayısı kadar onaylı örnek <i class="m">167</i><span class="d">çek · bono · poliçe — alacak rehinle güvenceli olsa bile bu yol kullanılabilir</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Senedin kambiyo senedi olduğunu ve <b>vadesinin geldiğini</b> inceler <i class="m">168</i><span class="d">şartlar yoksa takip talebini reddeder</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Ödeme emri <i class="m">168</i><span class="d">Ödeme <b class="t">10 gün</b> · şikâyet, imzaya itiraz ve borca itiraz <b class="t">5 gün</b> · mal beyanı: itiraz edilmezse 10 gün, itiraz reddedilirse 3 gün</span></div>
  <div class="n q w">Borçlu itiraz edecekse <b>icra dairesine değil, icra mahkemesine</b> dilekçeyle başvurur</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="cap">Borca itiraz <i class="m">169</i> · <i class="m">169/a</i></div><div class="n mah">Borç yok, ödendi, ertelendi, zamanaşımı, yetki<span class="d">Resmî ya da imzası ikrar edilmiş belgeyle ispat; zamanaşımı senet tarihine göre · en geç 30 gün içinde duruşma</span></div></div>
    <div class="col"><div class="cap">İmzaya itiraz <i class="m">170</i></div><div class="n mah">İmza borçluya ait değil<span class="d">İtiraz ciddiyse takip evrak üzerinden geçici durdurulabilir · imza incelemesi</span></div></div>
    <div class="col"><div class="cap">Şikâyet <i class="m">170/a</i></div><div class="n mah">Senet kambiyo senedi değil ya da alacaklının kambiyo hukukuna göre takip hakkı yok<span class="d">Mahkeme bunu kendiliğinden de gözetip takibi iptal edebilir</span></div></div>
  </div>
  <div class="n stop w">İtiraz <b>satış dışındaki takip işlemlerini durdurmaz</b>: haciz yapılabilir, satış yapılamaz · mahkeme takibi geçici olarak durdurabilir · itiraz kabul edilirse takip durur</div>
</div>
<div class="box warn"><b>Yaptırımlar <i class="m">169/a</i> · <i class="m">170</i>:</b>
  <ul>
    <li>İmza borçlunun çıkar ve takip itiraz üzerine durdurulmuşsa borçlu, alacağın en az <b>%20'si</b> inkâr tazminatı ve <b>%10</b> para cezası öder.</li>
    <li>İmza itirazı kabul edilir ve alacaklının senedi takibe koymada <b>kötü niyeti veya ağır kusuru</b> varsa alacaklı en az %20 tazminat ve %10 para cezası öder.</li>
    <li>Borca itiraz esastan kabul edilirse kötü niyetli ya da ağır kusurlu alacaklı; takip geçici durdurulmuş ve itiraz reddedilmişse borçlu en az %20 tazminat öder.</li>
    <li>Genel mahkemede dava açılırsa tazminat ve para cezasının tahsili dava sonuna kadar ertelenir.</li>
  </ul>
</div>
<table class="tb cmp">
  <tr><th></th><th>Genel haciz yolu</th><th>Kambiyo senetleri yolu</th></tr>
  <tr><td>Ödeme süresi</td><td>7 gün</td><td><b>10 gün</b></td></tr>
  <tr><td>İtiraz süresi</td><td>7 gün</td><td><b>5 gün</b></td></tr>
  <tr><td>İtiraz mercii</td><td class="c-d">İcra Dairesi</td><td class="c-m">İcra Mahkemesi</td></tr>
  <tr><td>İtirazın etkisi</td><td>Takip durur</td><td>Satış dışında durdurmaz</td></tr>
  <tr><td>Senet</td><td>Aslı ya da onaylı örneği</td><td>Aslı zorunlu</td></tr>
  <tr><td>Rehinli alacak</td><td>Önce rehin <i class="m">45</i></td><td>Bu yol yine açık <i class="m">167</i></td></tr>
  <tr><td>Red kararına istinaf</td><td>—</td><td>İcrayı durdurmaz; teminat gösterilirse durur <i class="m">169/a</i></td></tr>
</table>

<!-- 13 -->
<h2 class="sec" id="s-tahliye"><span class="no">13</span><span class="tt">Kiralanan taşınmazın ilamsız tahliyesi</span><span class="m"><i class="m">269–276</i></span></h2>
<div class="row" style="--n:2">
  <div class="flow" style="margin:0">
    <div class="n start s">Kira bedeli ödenmedi<span class="d">temerrüt nedeniyle tahliye <i class="m">269</i></span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>Tahliye ihtarlı ödeme emri<span class="d">TBK 315 ihtarı: konut ve çatılı işyerinde en az <b class="t">30 gün</b>, diğerlerinde en az <b class="t">10 gün</b> · itiraz <b class="t">7 gün</b> (icra dairesine) · sözleşme ve imza açıkça reddedilmezse kabul edilmiş sayılır</span></div>
    <div class="n q s">İtiraz edildi mi?</div>
    <div class="n mah s"><span class="k">İcra Mahkemesi</span>İtiraz yoksa ve süresinde ödenmediyse tahliye<span class="d">ihtar süresinin bitiminden itibaren <b class="t">6 ay</b> içinde istenir <i class="m">269/a</i></span></div>
    <div class="n mah s"><span class="k">İcra Mahkemesi</span>İtiraz varsa itirazın kaldırılması ve tahliye<span class="d"><b class="t">6 ay</b> içinde istenmezse aynı alacak için yeniden ilamsız takip yapılamaz · <i class="m">269/b</i> <i class="m">269/c</i></span></div>
  </div>
  <div class="flow" style="margin:0">
    <div class="n start s">Kira süresi bitti ya da tahliye taahhüdü var<span class="d"><i class="m">272</i> · TBK 352/1</span></div>
    <div class="n daire s"><span class="k">Kiraya veren</span>Takip talebi<span class="d">Sürenin bitiminden ya da taahhüt edilen tarihten itibaren <b class="t">1 ay</b> içinde</span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>Tahliye emri<span class="d">Tahliye için <b class="t">15 gün</b> · itiraz <b class="t">7 gün</b> (icra dairesine; takibi durdurur <i class="m">274</i>)</span></div>
    <div class="n mah s"><span class="k">İcra Mahkemesi</span>İtirazın kaldırılması <i class="m">275</i><span class="d">Noterce düzenlenmiş, onaylanmış ya da ikrar edilmiş sözleşme varsa ve kiracı yenileme ya da uzatma belgesi gösteremezse</span></div>
  </div>
</div>
<div class="box tip"><b>Tahliye taahhüdü (TBK 352/1):</b> Yazılı olmalı ve kiralananın <b>teslim edilmesinden sonra</b> verilmiş olmalıdır; teslimden önce, kira sözleşmesiyle birlikte alınan taahhüt geçersizdir. Taahhüt edilen tarihten itibaren 1 ay içinde icraya başvurulur ya da dava açılır.</div>
<div class="box warn"><b>Konut ve çatılı işyeri (TBK 347):</b> Kiraya veren, belirli süreli sözleşmeyi sürenin bitimine dayanarak sona erdiremez; kiracı bildirimde bulunmazsa sözleşme birer yıl uzar. On yıllık uzama süresinden sonra kiraya veren, her uzama yılının bitiminden en az 3 ay önce bildirimle sebep göstermeden sona erdirebilir. Bu kiralarda süre bitimi tek başına tahliye sebebi değildir.</div>
<div class="box def"><b>Tahliye kararının yerine getirilmesi <i class="m">269/c</i>:</b> İcra mahkemesinin tahliye kararı kesinleşmesi beklenmeden yerine getirilir; ancak kararın tefhim veya tebliğinden itibaren <b class="t">10 gün</b> geçmesi gerekir. Borçlu m.36'dan yararlanarak (teminatla) icranın ertelenmesini isteyebilir.</div>

<!-- 14 -->
<h2 class="sec" id="s-ilamli"><span class="no">14</span><span class="tt">İlamlı icra</span><span class="m"><i class="m">24–41</i></span></h2>
<div class="flow">
  <div class="n start">İlam ya da ilam niteliğinde belge <i class="m">38</i><span class="d">mahkeme kararları · mahkemede yapılan sulh ve kabuller · para borcu ikrarını içeren düzenleme şeklindeki noter senetleri · istinaf ve temyiz kefaletnameleri ile icra dairesindeki kefaletler (müteselsil kefalet hükmünde) · özel kanunların ilam niteliğinde saydığı belgeler</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>İcra emri <i class="m">32</i><span class="d">Para ve teminat için <b class="t">7 gün</b> · mal beyanı ihtarı · ilamın icrası her icra dairesinden istenebilir <i class="m">34</i></span></div>
  <div class="n q">Borçlunun savunma araçları</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="cap">İcranın geri bırakılması <i class="m">33</i></div><div class="n mah"><b class="t">7 gün</b> icra emrinin tebliğinden<span class="d">İlamdan sonra borç ödendi (itfa), ertelendi (imhal) ya da zamanaşımına uğradı · itfa ve imhal resmî, onaylı ya da mahkeme veya icra önünde ikrar edilmiş belgeyle ispatlanır · icra emrinden sonra doğan sebepler her zaman ileri sürülür</span></div></div>
    <div class="col"><div class="cap">Zamanaşımı <i class="m">33/a</i> · <i class="m">39</i></div><div class="n mah">İlamın zamanaşımına uğradığı iddiası<span class="d">Resmî belgelere göre incelenir · ilama dayanan takip <b>son işlemden itibaren 10 yıl</b> geçmekle zamanaşımına uğrar</span></div></div>
    <div class="col"><div class="cap">Kanun yolu + teminat <i class="m">36</i></div><div class="n borclu">İcranın ertelenmesi (tehiri icra)<span class="d">İstinaf ya da temyize başvuran borçlu parayı depo eder ya da teminat gösterirse icra müdürü, <b>icra mahkemesinden</b> geri bırakma kararı getirmesi için süre verir · Devlet ve adli yardımdan yararlanan teminat göstermez · nafakada süre verilmez</span></div></div>
  </div>
</div>
<div class="grid2">
  <div class="card"><h5>Kesinleşme şartı</h5>Kural olarak ilam <b>kesinleşmeden</b> icra edilebilir. İstisna (HMK 350): kişiler hukuku, aile hukuku ve taşınmaz üzerindeki ayni haklara ilişkin kararlar kesinleşmeden yerine getirilmez.</div>
  <div class="card"><h5>İlamın bozulması <i class="m">40</i></h5>İlamın istinafta kaldırılması ya da temyizde bozulması icrayı <b>olduğu yerde durdurur</b>. İcradan sonra borçlu olunmadığı kesin bir ilamla anlaşılırsa icra ayrıca hükme gerek olmadan eski hâline getirilir; iyi niyetli 3. kişilerin hakları saklıdır.</div>
</div>
<h4>Para dışındaki ilamlar</h4>
<table class="tb">
  <tr><th>Konu</th><th>Madde</th><th>Ana kural</th></tr>
  <tr><td>Taşınır teslimi</td><td><i class="m">24</i></td><td>İcra emri <b class="t">7 gün</b>; teslim edilmezse mal zorla alınır, bulunmazsa ilamdaki değeri haciz yoluyla tahsil edilir (değer yazılı değilse icra müdürü takdir eder)</td></tr>
  <tr><td>Taşınmaz tahliyesi / teslimi</td><td><i class="m">26</i></td><td>İcra emri <b class="t">7 gün</b>; sonra zorla tahliye · teslim edilen taşınmaza yeniden giren borçlu yeni hüküm gerekmeden çıkarılır</td></tr>
  <tr><td>Çocuk teslimi, kişisel ilişki</td><td><i class="m x">ÇKK 41/A</i></td><td>7343 ile İİK m.25, 25/a, 25/b ve 341 yürürlükten kaldırıldı · aile mahkemesi kararlarını <b>adli destek ve mağdur hizmetleri müdürlükleri</b> yerine getirir; müdürlük olmayan yerde Bakanlığın belirlediği hukuk mahkemesi yazı işleri müdürlüğü</td></tr>
  <tr><td>Bir işin yapılması / yapılmaması</td><td><i class="m">30</i></td><td>Başkasınca yapılabilecek iş gideri borçludan alınarak yaptırılır · yalnız borçlunun yapabileceği işe ya da yapmama ilamına aykırılıkta 3 aya kadar tazyik hapsi <i class="m">343</i></td></tr>
</table>

<!-- 15 -->
<h2 class="sec" id="s-rehin"><span class="no">15</span><span class="tt">Rehnin paraya çevrilmesi yolu</span><span class="m"><i class="m">45</i> · <i class="m">145–153</i></span></h2>
<div class="box warn"><b>Önce rehin kuralı <i class="m">45</i>:</b> Rehinle güvenceli alacak için alacaklı kural olarak yalnız rehnin paraya çevrilmesi yoluyla takip yapabilir; rehin yetmezse kalan için haciz ya da iflas yoluna gider. İstisnalar: kambiyo senetleri <i class="m">167</i>, konut finansmanı ve TOKİ alacakları, ipotekli faiz ve yıllık taksit alacakları.</div>
<div class="row" style="--n:2">
  <div class="flow" style="margin:0">
    <div class="n start s">Taşınır rehni<span class="d"><i class="m">145 vd.</i> · takip talebinde rehnin konusu ve varsa rehin veren 3. kişi gösterilir</span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>Ödeme emri <i class="m">146</i><span class="d">ödeme <b class="t">15 gün</b> · itiraz <b class="t">7 gün</b> (icra dairesine) · sonraki rehin hakkı sahibine bildirilir</span></div>
    <div class="n mah s"><span class="k">İcra Mahkemesi</span>İtiraz: m.62–72 uygulanır <i class="m">147</i><span class="d">rehin hakkına açıkça itiraz edilmezse artık tartışılamaz · yalnız rehin hakkına itiraz edilirse alacaklı haciz yoluna geçebilir</span></div>
  </div>
  <div class="flow" style="margin:0">
    <div class="n start s">Taşınmaz rehni (ipotek)<span class="d"><i class="m">148 vd.</i> · yetkili ya da taşınmazın bulunduğu yer icra dairesi · akit tablosunun resmî örneği</span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>İlamlı gibi: icra emri <i class="m">149</i><span class="d">akit tablosu kayıtsız şartsız para borcu ikrarı içeriyor ve borç muaccelse · <b class="t">30 gün</b> · savunma: icranın geri bırakılması <i class="m">149/a</i> · red kararına istinaf ancak <b>%15</b> teminatla satışı durdurur</span></div>
    <div class="n daire s"><span class="k">İcra Dairesi</span>İlamsız: ödeme emri <i class="m">149/b</i><span class="d">diğer muaccel alacaklarda · ödeme <b class="t">30 gün</b> · itiraz <b class="t">7 gün</b> · kredi ipoteklerinde noterden tebliğ edilmiş hesap özetiyle icra emri <i class="m">150/ı</i></span></div>
  </div>
</div>
<table class="tb">
  <tr><th>Satış isteme süresi <i class="m">150/e</i></th><th>Süre</th></tr>
  <tr><td>Taşınır rehni</td><td><b class="t">6 ay</b> ödeme ya da icra emrinin tebliğinden</td></tr>
  <tr><td>Taşınmaz rehni</td><td><b class="t">1 yıl</b> aynı tarihten · süresinde istenmez ya da talep geri alınıp yenilenmezse <b>takip düşer</b></td></tr>
</table>
<ul>
  <li>Rehin satılamazsa ya da bedeli yetmezse alacaklıya <b>rehin açığı belgesi</b> verilir <i class="m">152</i>; borç ikrarını içeren senet niteliğindedir. Alacaklı artırma gününden (satış olduysa satışın kesinleşmesinden) itibaren 1 yıl içinde haciz yoluyla takibe geçerse yeniden ödeme ya da icra emri gerekmez.</li>
  <li>İpotek alacaklısı bulunamıyor ya da parayı almaktan kaçınıyorsa borçlu, borcu icra dairesine yatırarak ipoteğin kaldırılmasını sağlayabilir <i class="m">153</i>.</li>
</ul>

<!-- 16 -->
<h2 class="sec" id="s-ihtiyati"><span class="no">16</span><span class="tt">İhtiyati haciz</span><span class="m"><i class="m">257–268</i></span></h2>
<div class="box def"><b>Amaç:</b> Alacaklının takip ya da dava sonuçlanıncaya kadar borçlunun mallarını kaçırmasını önlemek için verilen <b>geçici</b> hukuki koruma.</div>
<div class="grid2">
  <div class="card"><h5>Vadesi gelmiş alacak <i class="m">257/1</i></h5>Rehinle güvencelenmemiş, muaccel <b>para</b> alacağı için istenebilir.</div>
  <div class="card"><h5>Vadesi gelmemiş alacak <i class="m">257/2</i></h5><ul><li>Borçlunun belli bir yerleşim yeri yoksa</li><li>Borçlu kaçıyor, mallarını kaçırıyor ya da hileli işlemler yapıyorsa</li><li>Bu durumda borç yalnız o borçlu için muaccel olur</li></ul></div>
</div>
<div class="flow">
  <div class="n gen"><span class="k">Genel Mahkeme</span>İhtiyati haciz kararı <i class="m">258</i><span class="d">m.50'ye göre yetkili mahkeme · alacak ve haciz sebebi hakkında kanaat verecek delil (yaklaşık ispat) · alacaklıdan <b>teminat</b> alınır; alacak ilama dayanıyorsa aranmaz, ilam niteliğinde belgede mahkeme takdir eder <i class="m">259</i> · ret kararına istinaf</span></div>
  <div class="n daire"><span class="k">İcra Dairesi</span>Kararın uygulanması <i class="m">261</i><span class="d">Karardan itibaren <b class="t">10 gün</b> içinde, kararı veren mahkemenin yargı çevresindeki icra dairesinden istenir; istenmezse karar kendiliğinden kalkar · tutanak hazır bulunmayanlara 3 gün içinde tebliğ edilir</span></div>
  <div class="n borclu"><span class="k">Alacaklı</span>Takip ya da dava <i class="m">264</i><span class="d">Önceden konulduysa haczin uygulanmasından (yokluğunda yapıldıysa tutanağın tebliğinden) itibaren <b class="t">7 gün</b> · ödeme emrine itiraz edilirse itirazın tebliğinden itibaren <b class="t">7 gün</b> içinde itirazın kaldırılması ya da iptali · dava sürerken konulduysa hükmün tebliğinden itibaren <b class="t">1 ay</b> içinde takip</span></div>
  <div class="n end">Takip kesinleşince ihtiyati haciz kendiliğinden <b>kesin hacze</b> dönüşür<span class="d">süreler kaçırılırsa ihtiyati haciz hükümsüz kalır</span></div>
</div>
<div class="grid2">
  <div class="card mah"><h5>İhtiyati hacze itiraz <i class="m">265</i></h5>Kendisi dinlenmeden karar verilen borçlu, haczin uygulanmasından (yokluğunda yapıldıysa tutanağın tebliğinden) itibaren <b class="t">7 gün</b> içinde kararı veren mahkemeye haciz sebeplerine, yetkiye ve teminata itiraz eder. Menfaati zedelenen 3. kişiler öğrenmeden itibaren <b class="t">7 gün</b> içinde sebeplere ve teminata itiraz edebilir. İtiraz kararına istinaf icrayı durdurmaz.</div>
  <div class="card"><h5>Teminatla kaldırma <i class="m">266</i></h5>Borçlu para, rehin, esham ve tahvilat ya da banka kefaleti göstererek ihtiyati haczin kaldırılmasını isteyebilir; takip başladıktan sonra bu yetki icra mahkemesine geçer.</div>
</div>
<div class="box warn"><b>Haksız ihtiyati haciz <i class="m">259</i>:</b> Haksız çıkan alacaklı, borçlunun ve 3. kişilerin bu yüzden uğradığı bütün zararları tazmin eder; tazminat davası ihtiyati haczi koyan mahkemede de açılabilir.</div>

<!-- 17 -->
<h2 class="sec" id="s-iptal"><span class="no">17</span><span class="tt">İptal davaları (tasarrufun iptali)</span><span class="m"><i class="m">277–284</i></span></h2>
<div class="box def"><b>Amaç:</b> Borçlunun alacaklılarını zarara uğratan tasarruflarını alacaklıya karşı <b>hükümsüz</b> kılmak. Dava kazanılırsa alacaklı, tasarruf konusu malı haczettirip sattırabilir; tasarruf diğer herkes için geçerli kalır (<b>nispi etki</b> <i class="m">283</i>).</div>
<div class="flow">
  <div class="n q w">Dava şartları</div>
  <div class="split" style="--n:3">
    <div class="col"><div class="n">Kesinleşmiş takip ve <b>kesin ya da geçici aciz belgesi</b> <i class="m">277</i><span class="d">haciz tutanağı da aciz belgesi hükmünde olabilir <i class="m">105</i></span></div></div>
    <div class="col"><div class="n">Alacak, tasarruftan <b>önce doğmuş</b> olmalı<span class="d">yerleşik içtihat</span></div></div>
    <div class="col"><div class="n">Tasarruf m.278–280 kapsamında olmalı<span class="d">ve 5 yıllık hak düşürücü sürede dava açılmalı <i class="m">284</i></span></div></div>
  </div>
</div>
<div class="row" style="--n:3">
  <div class="card"><h5>İvazsız tasarruflar <i class="m">278</i></h5>Aciz belgesinin (ya da aciz belgesi niteliğindeki haciz tutanağının) düzenlendiği veya iflasın açıldığı tarihten önceki <b class="t">1 yıl</b> (7571)<ul><li>Alışılmış hediyeler dışındaki bütün bağışlamalar ve ivazsız tasarruflar</li><li>Gerçek değerine uygun ivazlı olduğu ispatlanmadıkça bağış sayılır: altsoy-üstsoy, 3. derece dahil kan ve kayın hısımları, eş (evlilik son 1 yılda bitmiş olsa da), evlat edinen-evlatlık ve ortak konutta yaşayanlar arasındaki tasarruflar</li><li>Aksi ispatlanmadıkça değerinin pek altında ivazla yapılan sözleşmeler</li><li>Uygun karşılık ispatlanmadıkça ömür boyu gelir, intifa hakkı tesisi ve ölünceye kadar bakma sözleşmeleri</li></ul></div>
  <div class="card"><h5>Aciz hâlinde tasarruflar <i class="m">279</i></h5>Hacizden, mal bulunmaması yüzünden acizden ya da iflastan önceki <b class="t">1 yıl</b><ul><li>Önceden taahhüt yokken mevcut bir borca rehin verme</li><li>Para veya olağan ödeme araçları dışında ödeme</li><li>Vadesi gelmemiş borcu ödeme</li><li>Kişisel hakları güçlendiren tapu şerhleri</li><li>Yararlanan, borçlunun durumunu bilmediğini ispat ederse dava dinlenmez</li></ul></div>
  <div class="card"><h5>Zarar verme kastı <i class="m">280</i></h5>İşlemden itibaren <b class="t">5 yıl</b> içinde borçlu aleyhine haciz ya da iflas yoluyla takip yapılmış olmalı<ul><li>Malvarlığı borçlarına yetmeyen borçlunun alacaklılara zarar verme kastıyla yaptığı bütün işlemler</li><li>Karşı taraf borçlunun durumunu ve kastını biliyor ya da açık emarelerle bilmesi gerekiyor olmalı</li><li>Eş, usul-füru, 3. derece dahil kan ve kayın hısımları, evlat edinen-evlatlık için bilme karinesi; ticari işletme devrinde de karine</li></ul></div>
</div>
<div class="grid2">
  <div class="card"><h5>Usul ve taraflar <i class="m">281</i> · <i class="m">282</i></h5>Basit yargılama; hâkim delilleri serbestçe takdir eder ve dava konusu mallara ihtiyati haciz koyabilir. Dava <b>borçlu ve onunla işlem yapan</b> ya da ondan ödeme alan kişiler ile mirasçıları aleyhine, ayrıca kötü niyetli 3. kişiler aleyhine açılır; iyi niyetli 3. kişilerin hakları korunur. Davalılardan biri alacağı öderse dava reddedilir.</div>
  <div class="card"><h5>Sonuç <i class="m">283</i></h5>Davacı, tasarruf konusu mal üzerinde cebri icra yoluyla hakkını alır; taşınmazda tapu kaydı düzeltilmeden haciz ve satış istenebilir. Mal elden çıkarılmışsa 3. kişi, alacağı aşmamak üzere değerini nakden öder. İyi niyetli bağış alan yalnız elinde kalanı geri verir.</div>
</div>
<div class="box warn"><b>Hak düşürücü süre <i class="m">284</i>:</b> İptal davası açma hakkı, iptale tabi tasarrufun yapıldığı tarihten itibaren <b class="t">5 yıl</b> geçmekle düşer. Davaya genel mahkeme bakar.</div>

<!-- 18 -->
<h2 class="sec" id="s-suclar"><span class="no">18</span><span class="tt">İcra suçlarının genel esasları</span><span class="m"><i class="m">331–354</i></span></h2>
<div class="box def"><b>Üç ayrı yaptırım:</b> Suç ve ceza (hapis, adli para cezası) · disiplin hapsi · tazyik hapsi. Disiplin ve tazyik hapsine de, bu bölümdeki suçlara ilişkin davalara da <b>icra mahkemesi</b> bakar <i class="m">346</i>; bu işler başka ceza davalarıyla birleştirilemez.</div>
<div class="flow">
  <div class="n borclu"><span class="k">Alacaklı / zarar gören</span>Şikâyet <i class="m">347</i> · <i class="m">349</i><span class="d">Fiilin öğrenilmesinden itibaren <b class="t">3 ay</b> · her hâlde fiilin işlenmesinden itibaren <b class="t">1 yıl</b> · dilekçe ya da sözlü · yetkili mahkeme: takibin yapıldığı yer icra mahkemesi <i class="m">348</i></span></div>
  <div class="n" style="border-color:#d24357;background:#fff7f8"><span class="k" style="color:#b92b40">İcra Mahkemesi</span>Yargılama <i class="m">349–352</i><span class="d">Cumhuriyet savcısı duruşmada bulunmaz · şikâyetçi mazeretsiz gelmez ve vekil de göndermezse şikâyet hakkı düşer · karar en geç <b class="t">5 gün</b> içinde verilir</span></div>
  <div class="n"><span class="k">Kanun yolu</span>İtiraz <b class="t">2 hafta</b> <i class="m">353</i><span class="d">Tazyik ve disiplin hapsi kararlarına tebliğden itibaren · suçlardan verilen hükümlere CMK'nın kanun yolları uygulanır</span></div>
  <div class="n end">Şikâyetten vazgeçilir ya da borç ödenirse dava ve ceza bütün sonuçlarıyla <b>düşer</b> <i class="m">354</i><span class="d">Tazyik ve disiplin hapsi kararı kesinleşmeden itibaren 2 yıl geçince yerine getirilmez · nafaka dışında, alacak aylık brüt asgari ücretin altındaysa disiplin ve tazyik hapsi uygulanmaz</span></div>
</div>
<div class="grid2">
  <div class="card ceza"><h5>Mal kaçırma <i class="m">331</i></h5>Haciz yoluyla takip talebinden sonra ya da önceki 2 yıl içinde alacaklıyı zarara sokmak amacıyla mal kaçırma, değerini düşürme, muvazaalı devir, gerçek olmayan borç ikrarı · aciz belgesi alınmış ya da alacak tahsil edilememiş olmalı · <b>6 ay–3 yıl hapis</b> ve adli para cezası.</div>
  <div class="card ceza"><h5>Aczine sebebiyet <i class="m">332</i></h5>Hafiflik, aşırı harcama, talih oyunu ya da ağır ihmalle aczine yol açma veya durumu ağırlaştırma · <b>15 gün–6 ay hapis</b>.</div>
  <div class="card ceza"><h5>Gerçeğe aykırı beyan <i class="m">338</i></h5>Mal beyanında ya da kanuna göre istenen başka bir beyanda gerçeğe aykırılık · <b>3 ay–1 yıl hapis</b>. Aciz belgeli borçlu asgari ücretin üstünde geçiniyorsa gelirinin mahkemece belirlenen kısmını (en az dörtte bir) yatırmazsa 1 yıla kadar tazyik hapsi.</div>
  <div class="card ceza"><h5>Mal beyanında bulunmama <i class="m">76</i></h5>Beyanda bulununcaya kadar, bir defaya mahsus ve en çok <b>3 ay tazyik hapsi</b>. Eski m.337/1'deki yaptırım Anayasa Mahkemesince (2008) iptal edildi.</div>
  <div class="card ceza"><h5>Sonradan edinilen malı bildirmeme <i class="m">339</i></h5>Sonradan edinilen mal ya da gelir artışını 7 gün içinde bildirmeme · 10 güne ya da 1 aya kadar <b>disiplin hapsi</b>; borç ödenirse ceza düşer.</div>
  <div class="card ceza"><h5>Ödeme şartını ihlal <i class="m">340</i></h5>İcra dairesinde kararlaştırılan ödeme şartına uymama · <b>3 aya kadar tazyik hapsi</b>; ödeyince tahliye.</div>
  <div class="card ceza"><h5>İlama aykırılık <i class="m">343</i></h5>Yalnız borçlunun yapabileceği iş, yapmama ya da irtifak ilamına uymama · <b>3 aya kadar tazyik hapsi</b>.</div>
  <div class="card ceza"><h5>Nafakaya uymama <i class="m">344</i></h5>Nafaka kararına uymama · <b>3 aya kadar tazyik hapsi</b>; nafakanın kaldırılması ya da azaltılması davası açılmışsa uygulanması dava sonuna bırakılabilir.</div>
</div>
<div class="box tip"><b>Tazyik hapsi ≠ hapis cezası:</b> Tazyik hapsi borçluyu yükümlülüğünü yerine getirmeye <b>zorlama</b> aracıdır; borçlu yükümlülüğünü yerine getirince (ör. mal beyanında bulunur ya da öder) serbest bırakılır.</div>

<!-- 19 -->
<h2 class="sec" id="s-sureler"><span class="no">19</span><span class="tt">Süreler tablosu</span></h2>
<table class="tb">
  <tr><th>İşlem</th><th>Süre</th><th>Merci</th><th>Madde</th></tr>
  <tr><td>Şikâyet</td><td><b>7 gün</b> öğrenmeden</td><td class="c-m">İcra Mah.</td><td><i class="m">16</i></td></tr>
  <tr><td>İcra mahkemesi kararına istinaf / BAM kararına temyiz</td><td><b>2 hafta</b> tebliğden</td><td>BAM / Yargıtay</td><td><i class="m">363</i> <i class="m">364</i></td></tr>
  <tr><td>Ödeme emrine itiraz (genel haciz)</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">62</i></td></tr>
  <tr><td>Gecikmiş itiraz</td><td><b>3 gün</b> engelin kalkmasından</td><td class="c-m">İcra Mah.</td><td><i class="m">65</i></td></tr>
  <tr><td>İtirazın iptali davası</td><td><b>1 yıl</b></td><td class="c-g">Genel Mah.</td><td><i class="m">67</i></td></tr>
  <tr><td>İtirazın kesin / geçici kaldırılması</td><td><b>6 ay</b></td><td class="c-m">İcra Mah.</td><td><i class="m">68</i> <i class="m">68/a</i></td></tr>
  <tr><td>Borçtan kurtulma davası</td><td><b>7 gün</b> · %15 depo</td><td class="c-g">Genel Mah.</td><td><i class="m">69</i></td></tr>
  <tr><td>İstirdat davası</td><td><b>1 yıl</b> ödemeden</td><td class="c-g">Genel Mah.</td><td><i class="m">72</i></td></tr>
  <tr><td>Mal beyanı (itirazı kaldırılan borçlu)</td><td><b>3 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">75</i></td></tr>
  <tr><td>Haciz isteme</td><td><b>1 yıl</b> ödeme emri tebliğinden</td><td class="c-d">İcra Dairesi</td><td><i class="m">78</i></td></tr>
  <tr><td>Haciz ihbarnamesine itiraz (1. ve 2.)</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">89</i></td></tr>
  <tr><td>3. bildirimden sonra ödeme ya da menfi tespit</td><td><b>15 gün</b> · belge 20 gün</td><td class="c-g">Genel Mah.</td><td><i class="m">89</i></td></tr>
  <tr><td>İstihkak iddiası (hacizden haberdar olunca)</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">96</i></td></tr>
  <tr><td>İstihkak iddiasına itiraz (mal borçluda)</td><td><b>3 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">96</i></td></tr>
  <tr><td>İstihkak davası</td><td><b>7 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">97</i> <i class="m">99</i></td></tr>
  <tr><td>Hacze iştirake itiraz</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">101</i></td></tr>
  <tr><td>Satış isteme (taşınır / taşınmaz)</td><td><b>1 yıl</b> hacizden</td><td class="c-d">İcra Dairesi</td><td><i class="m">106</i></td></tr>
  <tr><td>Kıymet takdirine şikâyet (taşınmaz)</td><td><b>7 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">128/a</i></td></tr>
  <tr><td>İhale bedelinin ödenmesi</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">118</i> <i class="m">130</i></td></tr>
  <tr><td>İhalenin feshi</td><td><b>7 gün</b> · en geç 1 yıl</td><td class="c-m">İcra Mah.</td><td><i class="m">134</i></td></tr>
  <tr><td>Sıra cetveline itiraz / şikâyet</td><td><b>7 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">142</i></td></tr>
  <tr><td>Kambiyo: ödeme / itiraz ve şikâyet</td><td><b>10 gün / 5 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">168</i></td></tr>
  <tr><td>İcra emri (para, taşınır, taşınmaz)</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">24</i> <i class="m">26</i> <i class="m">32</i></td></tr>
  <tr><td>İcranın geri bırakılması (itfa, imhal, zamanaşımı)</td><td><b>7 gün</b></td><td class="c-m">İcra Mah.</td><td><i class="m">33</i></td></tr>
  <tr><td>Taşınır rehni: ödeme / itiraz</td><td><b>15 gün / 7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">146</i></td></tr>
  <tr><td>İpotek: icra emri ya da ödeme emri</td><td><b>30 gün</b> · itiraz 7 gün</td><td class="c-d">İcra Dairesi</td><td><i class="m">149</i> <i class="m">149/b</i></td></tr>
  <tr><td>Rehin: satış isteme (taşınır / taşınmaz)</td><td><b>6 ay / 1 yıl</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">150/e</i></td></tr>
  <tr><td>Kira: tahliye ihtarlı ödeme emrine itiraz</td><td><b>7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">269</i></td></tr>
  <tr><td>Kira: tahliye ya da itirazın kaldırılması</td><td><b>6 ay</b></td><td class="c-m">İcra Mah.</td><td><i class="m">269</i> <i class="m">269/a</i></td></tr>
  <tr><td>Kira: süre bitimi / taahhüt için takip</td><td><b>1 ay</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">272</i> · TBK 352</td></tr>
  <tr><td>Kira: tahliye emri / itiraz</td><td><b>15 gün / 7 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">272</i> <i class="m">274</i></td></tr>
  <tr><td>İhtiyati haczin uygulanmasını isteme</td><td><b>10 gün</b></td><td class="c-d">İcra Dairesi</td><td><i class="m">261</i></td></tr>
  <tr><td>İhtiyati hacizden sonra takip / dava</td><td><b>7 gün</b></td><td>—</td><td><i class="m">264</i></td></tr>
  <tr><td>İhtiyati hacze itiraz</td><td><b>7 gün</b></td><td class="c-g">Kararı veren mah.</td><td><i class="m">265</i></td></tr>
  <tr><td>İptal davası (hak düşürücü)</td><td><b>5 yıl</b> tasarruftan</td><td class="c-g">Genel Mah.</td><td><i class="m">284</i></td></tr>
  <tr><td>İcra suçlarında şikâyet</td><td><b>3 ay</b> · en geç 1 yıl</td><td class="c-m">İcra Mah.</td><td><i class="m">347</i></td></tr>
  <tr><td>Tazyik / disiplin hapsine itiraz</td><td><b>2 hafta</b> tebliğden</td><td class="c-m">İcra Mah.</td><td><i class="m">353</i></td></tr>
</table>

<div class="foot">Bu özet 2004 sayılı İcra ve İflas Kanunu'nun mevzuat.gov.tr'deki güncel metni esas alınarak hazırlanmıştır (7589 sayılı Kanunla yapılan 31.7.2026 tarihli değişiklik dahil; Ekim 2026). Sınavdan önce maddeleri güncel metin ve ders notlarınla karşılaştır. Sağdaki ve soldaki boşluklar not almak içindir.</div>
`,
});
