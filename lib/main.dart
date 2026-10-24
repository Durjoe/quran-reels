import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuranReelsApp());
}

const int totalAyahs = 6236;
const String reciter = 'Alafasy_128kbps';

// বাংলা উচ্চারণ: যাচাই করা ডেটা এখানে যোগ করুন। key = 'সূরা:আয়াত'
// উদাহরণ: '1:1': 'বিসমিল্লাহির রাহমানির রাহীম',
const Map<String, String> pronunciation = {};

const List<String> surahNamesBn = [
  'আল-ফাতিহা', 'আল-বাকারা', 'আলে ইমরান', 'আন-নিসা', 'আল-মায়িদা',
  'আল-আনআম', 'আল-আরাফ', 'আল-আনফাল', 'আত-তাওবা', 'ইউনুস',
  'হুদ', 'ইউসুফ', 'আর-রাদ', 'ইবরাহীম', 'আল-হিজর',
  'আন-নাহল', 'আল-ইসরা', 'আল-কাহফ', 'মারইয়াম', 'ত্বহা',
  'আল-আম্বিয়া', 'আল-হাজ্জ', 'আল-মুমিনূন', 'আন-নূর', 'আল-ফুরকান',
  'আশ-শুআরা', 'আন-নামল', 'আল-কাসাস', 'আল-আনকাবূত', 'আর-রূম',
  'লুকমান', 'আস-সাজদা', 'আল-আহযাব', 'সাবা', 'ফাতির',
  'ইয়াসীন', 'আস-সাফফাত', 'সোয়াদ', 'আয-যুমার', 'গাফির',
  'ফুসসিলাত', 'আশ-শূরা', 'আয-যুখরুফ', 'আদ-দুখান', 'আল-জাসিয়া',
  'আল-আহকাফ', 'মুহাম্মাদ', 'আল-ফাতহ', 'আল-হুজুরাত', 'ক্বাফ',
  'আয-যারিয়াত', 'আত-তূর', 'আন-নাজম', 'আল-ক্বামার', 'আর-রাহমান',
  'আল-ওয়াকিয়া', 'আল-হাদীদ', 'আল-মুজাদালা', 'আল-হাশর', 'আল-মুমতাহিনা',
  'আস-সাফ', 'আল-জুমুআ', 'আল-মুনাফিকূন', 'আত-তাগাবুন', 'আত-তালাক',
  'আত-তাহরীম', 'আল-মুলক', 'আল-কলম', 'আল-হাক্কাহ', 'আল-মাআরিজ',
  'নূহ', 'আল-জিন', 'আল-মুয্যাম্মিল', 'আল-মুদ্দাসসির', 'আল-ক্বিয়ামাহ',
  'আল-ইনসান', 'আল-মুরসালাত', 'আন-নাবা', 'আন-নাযিয়াত', 'আবাসা',
  'আত-তাকবীর', 'আল-ইনফিতার', 'আল-মুত্বাফফিফীন', 'আল-ইনশিক্বাক্ব', 'আল-বুরূজ',
  'আত-তারিক্ব', 'আল-আ\'লা', 'আল-গাশিয়া', 'আল-ফাজর', 'আল-বালাদ',
  'আশ-শামস', 'আল-লাইল', 'আদ-দুহা', 'আলাম নাশরাহ', 'আত-তীন',
  'আল-আলাক', 'আল-ক্বাদর', 'আল-বাইয়্যিনাহ', 'আয-যিলযাল', 'আল-আদিয়াত',
  'আল-ক্বারিআহ', 'আত-তাকাসুর', 'আল-আসর', 'আল-হুমাযাহ', 'আল-ফীল',
  'কুরাইশ', 'আল-মাউন', 'আল-কাওসার', 'আল-কাফিরূন', 'আন-নাসর',
  'আল-লাহাব', 'আল-ইখলাস', 'আল-ফালাক্ব', 'আন-নাস',
];

String toBn(int n) {
  const d = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

class Ayah {
  final int global;
  final int surah;
  final int number;
  final String arabic;
  final String bangla;

  Ayah({
    required this.global,
    required this.surah,
    required this.number,
    required this.arabic,
    required this.bangla,
  });

  String get fileKey =>
      '${surah.toString().padLeft(3, '0')}${number.toString().padLeft(3, '0')}';
  String get audioUrl => 'https://everyayah.com/data/$reciter/$fileKey.mp3';
}

Future<Ayah> fetchAyah(int global) async {
  final uri = Uri.parse(
      'https://api.alquran.cloud/v1/ayah/$global/editions/quran-uthmani,bn.bengali');
  final res = await http.get(uri).timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  final data = jsonDecode(utf8.decode(res.bodyBytes))['data'] as List;
  final ar = data.firstWhere((e) => e['edition']['identifier'] == 'quran-uthmani');
  final bn = data.firstWhere((e) => e['edition']['identifier'] == 'bn.bengali');

  final int surah = ar['surah']['number'];
  final int number = ar['numberInSurah'];
  String arabic = (ar['text'] as String).trim();

  // কিছু সূরার ১ম আয়াতের আগে বিসমিল্লাহ জুড়ে আসলে সেটা বাদ দেওয়া
  if (surah != 1 && surah != 9 && number == 1) {
    final words = arabic.split(' ');
    if (words.length > 4 && words.first.startsWith('بِسْمِ')) {
      arabic = words.skip(4).join(' ');
    }
  }

  return Ayah(
    global: global,
    surah: surah,
    number: number,
    arabic: arabic,
    bangla: (bn['text'] as String).trim(),
  );
}

class QuranReelsApp extends StatelessWidget {
  const QuranReelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'কুরআন রিলস',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const AyahFeed(),
    );
  }
}

class AyahFeed extends StatelessWidget {
  const AyahFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B21),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: totalAyahs,
        itemBuilder: (context, index) => AyahPage(global: index + 1),
      ),
    );
  }
}

class AyahPage extends StatefulWidget {
  final int global;
  const AyahPage({super.key, required this.global});

  @override
  State<AyahPage> createState() => _AyahPageState();
}

class _AyahPageState extends State<AyahPage> {
  late Future<Ayah> _future;
  Ayah? _ayah;
  AudioPlayer? _player;
  bool _playing = false;
  bool _loadingAudio = false;
  bool _downloading = false;
  bool _downloaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = fetchAyah(widget.global).then((a) {
      _ayah = a;
      _checkDownloaded(a);
      return a;
    });
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<File> _file(Ayah a) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/ayah_audio');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}/${a.fileKey}.mp3');
  }

  Future<void> _checkDownloaded(Ayah a) async {
    final f = await _file(a);
    final exists = await f.exists();
    if (mounted) setState(() => _downloaded = exists);
  }

  Future<void> _togglePlay() async {
    final a = _ayah;
    if (a == null || _loadingAudio) return;
    try {
      if (_player == null) {
        final p = AudioPlayer();
        _player = p;
        p.playerStateStream.listen((s) {
          if (!mounted) return;
          if (s.processingState == ProcessingState.completed) {
            p.seek(Duration.zero);
            p.pause();
            setState(() => _playing = false);
          } else {
            setState(() => _playing = s.playing);
          }
        });
        setState(() => _loadingAudio = true);
        final f = await _file(a);
        if (await f.exists()) {
          await p.setFilePath(f.path);
        } else {
          await p.setUrl(a.audioUrl);
        }
        if (mounted) setState(() => _loadingAudio = false);
      }
      if (_player!.playing) {
        await _player!.pause();
      } else {
        _player!.play();
      }
    } catch (_) {
      _player?.dispose();
      _player = null;
      if (mounted) {
        setState(() {
          _loadingAudio = false;
          _playing = false;
        });
      }
      _snack('অডিও চালানো যায়নি। ইন্টারনেট চেক করুন।');
    }
  }

  Future<void> _download() async {
    final a = _ayah;
    if (a == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      final res = await http
          .get(Uri.parse(a.audioUrl))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final f = await _file(a);
      await f.writeAsBytes(res.bodyBytes);
      if (mounted) setState(() => _downloaded = true);
      _snack('অডিও ডাউনলোড হয়েছে');
    } catch (_) {
      _snack('ডাউনলোড ব্যর্থ হয়েছে। ইন্টারনেট চেক করুন।');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final a = _ayah;
    if (a == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ডাউনলোড মুছবেন?'),
        content: const Text('এই আয়াতের সেভ করা অডিও ফোন থেকে মুছে যাবে।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('না')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('হ্যাঁ')),
        ],
      ),
    );
    if (ok == true) {
      _player?.dispose();
      _player = null;
      final f = await _file(a);
      if (await f.exists()) await f.delete();
      if (mounted) {
        setState(() {
          _downloaded = false;
          _playing = false;
        });
      }
      _snack('সেভ করা অডিও মুছে ফেলা হয়েছে');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF062B21), Color(0xFF0E4D3A)],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<Ayah>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('লোড করা যায়নি। ইন্টারনেট চেক করুন।'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(_load),
                      child: const Text('আবার চেষ্টা করুন'),
                    ),
                  ],
                ),
              );
            }
            final a = snap.data!;
            final pron = pronunciation['${a.surah}:${a.number}'];
            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: c.maxHeight - 32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  a.arabic,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    height: 2.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (pron != null && pron.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  pron,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFFFFD27A),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Text(
                                a.bangla,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.6,
                                  color: Color(0xFFE6F2EC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        IconButton.filledTonal(
                          iconSize: 32,
                          onPressed: _togglePlay,
                          icon: _loadingAudio
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3),
                                )
                              : Icon(_playing
                                  ? Icons.pause
                                  : Icons.play_arrow),
                        ),
                        const SizedBox(height: 4),
                        const Text('শুনুন', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        IconButton.filledTonal(
                          iconSize: 32,
                          onPressed: _downloading
                              ? null
                              : (_downloaded ? _confirmDelete : _download),
                          icon: _downloading
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3),
                                )
                              : Icon(
                                  _downloaded
                                      ? Icons.download_done
                                      : Icons.download,
                                  color: _downloaded
                                      ? const Color(0xFF7CFFB2)
                                      : null,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _downloaded ? 'সেভ করা আছে' : 'ডাউনলোড',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'সূরা ${surahNamesBn[a.surah - 1]} • আয়াত ${toBn(a.number)}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFB7D4C6),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
