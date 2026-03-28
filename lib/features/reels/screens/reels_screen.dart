import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/question_generator.dart';
import '../widgets/flashcard_reel.dart';
import '../widgets/music_indicator.dart';

/// ───────────────────────────────────────────────
/// Ana Reels Ekranı (Dikey Kaydırmalı Sayfalama)
///
/// TikTok/Reels tarzı tam ekran dikey PageView.
/// Her reel'de sillycat müziği döngüsel çalar.
/// ───────────────────────────────────────────────
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  final _pageController = PageController();
  final _dbService = DatabaseService.instance;
  final _audio = AudioService.instance;

  List<_ReelItem> _items = [];
  int _currentPage = 0;
  int _totalAnswered = 0;
  int _correctCount = 0;

  static const _trackNames = [
    'sillycat_1',
    'sillycat_2',
    'sillycat_3',
    'sillycat_4',
    'sillycat_5',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudio();
    _loadQuestions();
  }

  Future<void> _initAudio() async {
    await _audio.init();
    // İlk reel'in müziğini başlat
    await _audio.playForReel(0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana gidince duraklat, geri gelince devam et
    if (state == AppLifecycleState.paused) {
      _audio.pause();
    } else if (state == AppLifecycleState.resumed) {
      _audio.resume();
    }
  }

  void _loadQuestions() {
    final dbQuestions = _dbService.getDueQuestions();

    if (dbQuestions.isNotEmpty) {
      setState(() {
        _items = dbQuestions
            .map((q) => _ReelItem(
                  id: q.id,
                  questionText: q.questionText,
                  correctAnswer: q.correctAnswer,
                  options: q.options,
                  sourceSnippet: q.sourceSnippet,
                ))
            .toList();
      });
    } else {
      _loadDemoQuestions();
    }
  }

  void _loadDemoQuestions() {
    const demoText = '''
Türk Ceza Kanunu madde 141 uyarınca, hırsızlık suçunun cezası 1 yıldan 3 yıla kadar hapis cezasıdır.
Ceza Muhakemesi Kanunu m.91 gereğince gözaltı süresi 24 saati geçemez.
Borçlar hukukunda zamanaşımı süresi genel olarak 10 yıldır.
İcra ve İflas Kanunu madde 68 uyarınca, borçluya ödeme emri tebliğ edildikten sonra 7 gün içinde itiraz edebilir.
Bir kimsenin başkasının taşınmazı üzerinde yüklü bir alacak hakkı elde etmesine ipotek denir.
Mahkemenin davalı lehine karar vermesine ve sanığın suçsuz bulunmasına beraat denir.
Tarafların mahkeme dışında anlaşarak uyuşmazlığı çözmesine arabuluculuk denir.
Davanın bir üst mahkemede incelenmesi talebi temyiz olarak adlandırılır.
Hâkim, delilleri serbestçe değerlendirerek sanığın mahkumiyetine karar verirse mahkumiyet kararı verilmiş sayılır.
Ceza Kanunu madde 53 uyarınca, belli hakları kullanmaktan yoksun bırakma 5 yıla kadar uygulanabilir.
Kasten yaralama halinde, mağdurun şikayeti durumunda 6 ay içinde dava açılmalıdır.
Ağırlaştırılmış müebbet hapis cezası, en ağır ceza türüdür.
Bilirkişi raporu 30 gün içinde mahkemeye sunulmalıdır.
Tanık, duruşmada yeminli olarak ifade verir.
Velayet hakkı, çocuğun yararına göre düzenlenir.
İddianame düzenlenmeden kamu davası açılamaz.
Nafaka yükümlülüğü, tarafların mali durumuna göre belirlenir.
''';

    final generator = QuestionGenerator();
    final generated = generator.generateFromText(demoText);

    setState(() {
      _items = generated
          .map((g) => _ReelItem(
                id: null,
                questionText: g.questionText,
                correctAnswer: g.correctAnswer,
                options: g.options,
                sourceSnippet: g.sourceSnippet,
              ))
          .toList();

      if (_items.isEmpty) {
        _items = [
          const _ReelItem(
            id: null,
            questionText: 'Henüz soru yok.\nNotlar sekmesinden metin ekleyin!',
            correctAnswer: '-',
            options: [],
            sourceSnippet: '',
          ),
        ];
      }
    });
  }

  void _onCorrect(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _totalAnswered++;
      _correctCount++;
    });
    final id = _items[index].id;
    if (id != null) _dbService.markCorrect(id);
  }

  void _onWrong(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _totalAnswered++;
    });
    final id = _items[index].id;
    if (id != null) _dbService.markWrong(id);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _audio.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // ── Ana Reels PageView ──
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: _items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              HapticFeedback.selectionClick();
              // Yeni reel'e geçince müziği değiştir
              _audio.playForReel(index);
            },
            itemBuilder: (context, index) {
              final item = _items[index];
              final colors = [
                const Color(0xFFFF6D00),
                const Color(0xFF2979FF),
                const Color(0xFF00E676),
                const Color(0xFFAA00FF),
                const Color(0xFFFF1744),
              ];

              return FlashcardReel(
                frontText: item.questionText,
                backText: item.correctAnswer,
                sourceSnippet:
                    item.sourceSnippet.isNotEmpty ? item.sourceSnippet : null,
                options: item.options,
                onCorrect: () => _onCorrect(index),
                onWrong: () => _onWrong(index),
                accentColor: colors[index % colors.length],
              );
            },
          ),

          // ── Üst Bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            right: 20,
            child: Row(
              children: [
                const Text(
                  'Hukuk Reels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Yenile butonu
                GestureDetector(
                  onTap: _loadQuestions,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh,
                        color: Colors.white54, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                if (_totalAnswered > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_correctCount/$_totalAnswered',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Sağ Kenar Butonları ──
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                // Müzik aç/kapa
                _SideButton(
                  icon: _audio.isMuted
                      ? Icons.volume_off
                      : Icons.volume_up,
                  label: _audio.isMuted ? 'Sessiz' : 'Müzik',
                  onTap: () async {
                    await _audio.toggleMute();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                _SideButton(
                  icon: Icons.bookmark_border,
                  label: 'Kaydet',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kaydedildi!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _SideButton(
                  icon: Icons.share_outlined,
                  label: 'Paylaş',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _SideButton(
                  icon: Icons.flag_outlined,
                  label: 'Raporla',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Sol Alt: Müzik Göstergesi (dönen disk) ──
          Positioned(
            left: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: MusicIndicator(
              trackName: _trackNames[_currentPage % _trackNames.length],
              isPlaying: !_audio.isMuted,
            ),
          ),

          // ── Alt Orta: Sayfa Göstergesi ──
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_items.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// UI katmanı için lightweight soru modeli
class _ReelItem {
  final String? id;
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final String sourceSnippet;

  const _ReelItem({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.sourceSnippet,
  });
}

/// Sağ kenar aksiyon butonu
class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SideButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
