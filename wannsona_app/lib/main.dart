import 'package:flutter/material.dart';
import 'my_page_screen.dart';
import 'memories_screen.dart';
import 'package:http/http.dart' as http;
import 'walk_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_service.dart';
import 'road_temp_calculator.dart';
import 'dog_profile_screen.dart';
import 'my_dog_record_screen.dart';
import 'breed_select_screen.dart';
import 'breed_data.dart';
import 'onboarding_screen.dart';

void main() {
  runApp(const WannsonaApp());
}

class WannsonaApp extends StatelessWidget {
  const WannsonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'わんソナ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90D9)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
      locale: const Locale('ja', 'JP'),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String _errorMessage = '';
  WeatherData? _weather;

  // プロフィール情報
  double _dogWeight = 0;
  int _dogAgeYears = 0;
  String _dogBreed = '';

  double get _temp => _weather?.feelsLike ?? 20.0;
  bool get _weatherLoaded => _weather != null;

  // 快適時間を動的計算（路面温度35°C未満の時間帯）
  // 快適時間を0〜23時で全時間帯チェック
  List<String> get _comfortableHours {
    final desc = _weather?.description ?? '';
    final List<String> hours = [];
    for (int h = 0; h <= 23; h++) {
      final road = RoadTempCalculator.calculate(
        airTemp: _temp,
        weatherIcon: desc,
        hour: h,
      );
      final adjustedRoad = road + (_dogRiskFactor - 1.0) * 10;
      if (adjustedRoad < 30) hours.add('${h.toString().padLeft(2, "0")}:00');
    }
    return hours;
  }

  String get _comfortTimeLabel {
    final hours = _comfortableHours;
    if (hours.isEmpty) return '今日は散歩を控えて';
    final now = DateTime.now().hour;

    // 現在時刻以降の快適時間
    final future = hours.where((h) => int.parse(h.split(':')[0]) >= now).toList();

    // 深夜〜早朝（0〜5時）の快適時間
    final lateNight = hours.where((h) {
      final hh = int.parse(h.split(':')[0]);
      return hh >= 0 && hh <= 5;
    }).toList();

    // 今が快適帯の中にある
    if (future.isNotEmpty && int.parse(future.first.split(':')[0]) == now) {
      return '今が快適！〜${future.last}';
    }

    // 今日の残り時間に快適帯がある
    if (future.isNotEmpty) {
      if (future.length == 1) return '${future.first}ごろ';
      return '${future.first}〜${future.last}';
    }

    // 今日はもう快適時間なし → 深夜〜早朝に快適帯があるか
    if (lateNight.isNotEmpty) {
      return '深夜〜早朝 ${lateNight.first}〜${lateNight.last}';
    }

    return '今日は散歩を控えて';
  }

  String get _nextComfortTimeLabel {
    final hours = _comfortableHours;
    if (hours.isEmpty) return '';
    final now = DateTime.now().hour;
    final future = hours.where((h) => int.parse(h.split(':')[0]) >= now).toList();

    // 今日の残り快適時間がない場合、明日の早朝（0〜5時）を案内
    if (future.isEmpty) {
      final lateNight = hours.where((h) {
        final hh = int.parse(h.split(':')[0]);
        return hh >= 0 && hh <= 5;
      }).toList();
      if (lateNight.isNotEmpty) return '次  深夜${lateNight.first}〜${lateNight.last}';
    }
    return '';
  }

  List<Color> get _timelineColors {
    final desc = _weather?.description ?? '';
    return List.generate(12, (i) {
      final h = 5 + (i * 18 ~/ 12);
      final road = RoadTempCalculator.calculate(
        airTemp: _temp,
        weatherIcon: desc,
        hour: h,
);
      final adjustedRoad = road + (_dogRiskFactor - 1.0) * 10;
      if (adjustedRoad < 28) return Colors.blue.shade300;
      if (adjustedRoad < 35) return Colors.orange.shade300;
      if (adjustedRoad < 50) return Colors.red.shade400;
      return Colors.red.shade900;
    });
  }

  double get _dogRiskFactor {
    try {
      double factor = 1.0;
      if (_dogWeight >= 25) factor += 0.15;
      else if (_dogWeight >= 10) factor += 0.05;
      if (_dogAgeYears >= 8) factor += 0.2;
      else if (_dogAgeYears >= 1 && _dogAgeYears <= 1) factor += 0.1;
      return factor;
    } catch (_) {
      return 1.0;
    }
  }

  double get _roadTemp => RoadTempCalculator.calculate(
    airTemp: _temp,
    weatherIcon: _weather?.description ?? '',
    hour: DateTime.now().hour,
  );

  // リスク係数は閾値を下げる方向で使う（温度に掛けない）
  double get _adjustedRoadTemp => _roadTemp + (_dogRiskFactor - 1.0) * 10;
  String get _roadComment => RoadTempCalculator.getComment(_adjustedRoadTemp);
  String get _walkAdvice => RoadTempCalculator.getDogWalkAdvice(_adjustedRoadTemp);

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadTodos();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLaunch());
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // プロフィール読み込み
    final weightStr = prefs.getString('dog_weight') ?? '0';
    final birthStr = prefs.getString('dog_birth');
    setState(() {
      _dogWeight = double.tryParse(weightStr) ?? 0;
      _dogBreed = prefs.getString('dog_breed') ?? '';
      if (birthStr != null) {
        final birth = DateTime.tryParse(birthStr);
        if (birth != null) _dogAgeYears = DateTime.now().difference(birth).inDays ~/ 365;
      }
    });
    final bool isFirst = prefs.getBool('first_launch') ?? true;
    if (isFirst && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }



  String _getWeatherIcon(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('thunder')) return '⛈';
    if (d.contains('rain') || d.contains('drizzle')) return '🌧';
    if (d.contains('snow')) return '❄️';
    if (d.contains('cloud')) return '☁️';
    if (d.contains('clear')) return '☀️';
    if (d.contains('mist') || d.contains('fog')) return '🌫';
    return '🌤';
  }

  String get _feelsLikeComment {
    if (_temp >= 35) return '危険な暑さ🔥';
    if (_temp >= 30) return 'ムシムシ〜！';
    if (_temp >= 25) return '少し暑いね';
    if (_temp >= 20) return '過ごしやすい🌤';
    if (_temp >= 15) return 'さわやか！';
    if (_temp >= 10) return 'ひんやり🍃';
    if (_temp >= 5) return '寒いね🧥';
    return 'かなり寒い❄️';
  }

  Color get _roadTempColor {
    if (_roadTemp >= 60) return Colors.red.shade900;
    if (_roadTemp >= 50) return const Color(0xFFE53935);
    if (_roadTemp >= 40) return Colors.orange;
    if (_roadTemp >= 35) return Colors.amber;
    return Colors.green;
  }
  Widget _buildDrawer() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final prefs = snapshot.data;
        final dogName = prefs?.getString('dog_name') ?? 'まだ未登録';
        final dogBreed = prefs?.getString('dog_breed') ?? '犬種未設定';
        final dogWeight = prefs?.getString('dog_weight') ?? '-';
        final dogBirthStr = prefs?.getString('dog_birth');
        String dogAge = '-';
        if (dogBirthStr != null) {
          final birth = DateTime.tryParse(dogBirthStr);
          if (birth != null) {
            final age = DateTime.now().difference(birth).inDays ~/ 365;
            dogAge = '$age歳';
          }
        }

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.82,
          child: SafeArea(
            child: Column(
              children: [
                // ユーザー情報エリア
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2B5BA8), Color(0xFF4A90D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(Icons.pets, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dogName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(dogBreed, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('$dogAge  /  ${dogWeight}kg', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () { Navigator.pop(context); _showOnboardingDialog(); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('うちの子設定を編集', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
                // メニュー一覧
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _drawerItem(Icons.person, 'マイページ', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPageScreen())); }),
                      _drawerItem(Icons.pets, 'うちの子設定', () { Navigator.pop(context); _showOnboardingDialog(); }),
                      _drawerItem(Icons.location_on, '地域・天気設定', () => Navigator.pop(context)),
                      _drawerItem(Icons.notifications, '通知設定', () => Navigator.pop(context)),
                      _drawerItem(Icons.star, 'お気に入りスポット', () => Navigator.pop(context)),
                      _drawerItem(Icons.backpack, '持ち物・準備設定', () => Navigator.pop(context)),
                      _drawerItem(Icons.book, '記録・履歴設定', () => Navigator.pop(context)),
                      _drawerItem(Icons.settings, '表示設定', () => Navigator.pop(context)),
                      const Divider(),
                      _drawerItem(Icons.workspace_premium, 'プラン管理', () => Navigator.pop(context)),
                      _drawerItem(Icons.help_outline, '使い方・ヘルプ', () => Navigator.pop(context)),
                      _drawerItem(Icons.warning_amber, '注意事項', () {
                        Navigator.pop(context);
                        showDialog(context: context, builder: (_) => AlertDialog(
                          title: const Text('注意事項'),
                          content: const Text('わんソナは、診断・治療・医療相談を行うアプリではありません。\n\n犬種・体質・天気・季節・場所などをもとに、日々の確認や行動の目安を表示します。\n\n不明点や不安なことがある場合は、飼い主の判断で専門家へ相談してください。',
                            style: TextStyle(fontSize: 14, height: 1.8),
                          ),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
                        ));
                      }),
                      _drawerItem(Icons.description, '利用規約・プライバシー', () => Navigator.pop(context)),
                      _drawerItem(Icons.mail_outline, 'お問い合わせ', () => Navigator.pop(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2B5BA8), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }

  void _showOnboardingDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('dog_name') ?? '';
    final savedWeight = prefs.getString('dog_weight') ?? '';
    final savedBreed = prefs.getString('dog_breed') ?? '';
    final savedBirthStr = prefs.getString('dog_birth');
    DateTime? savedBirth;
    if (savedBirthStr != null) savedBirth = DateTime.tryParse(savedBirthStr);

    final nameController = TextEditingController(text: savedName);
    final weightController = TextEditingController(text: savedWeight);
    String selectedBreed = savedBreed;
    DateTime? birthDate = savedBirth;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🐾 うちの子を教えてください', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('名前', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: '例：ハナ',
                    filled: true, fillColor: const Color(0xFFF5F0EB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('犬種', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const BreedSelectScreen()),
                    );
                    if (result != null) {
                      setS(() { final b = result as dynamic; selectedBreed = (b.aliases as List).isNotEmpty ? b.aliases[0] as String : b.kana as String; });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedBreed.isEmpty ? '犬種を選択する' : selectedBreed,
                          style: TextStyle(color: selectedBreed.isEmpty ? Colors.grey : Colors.black87),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('体重 (kg)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '例：25',
                    filled: true, fillColor: const Color(0xFFF5F0EB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('誕生日', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().subtract(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setS(() => birthDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      birthDate == null ? 'タップして選択' : '${birthDate!.year}/${birthDate!.month}/${birthDate!.day}',
                      style: TextStyle(color: birthDate == null ? Colors.grey : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('あとで'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C42)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('dog_name', nameController.text);
                await prefs.setString('dog_breed', selectedBreed);
                await prefs.setString('dog_weight', weightController.text);
                if (birthDate != null) {
                  await prefs.setString('dog_birth', birthDate!.toIso8601String());
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存する', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadWeather() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final weather = await WeatherService().getCurrentWeather();
      setState(() { _weather = weather; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = '天気を取得できませんでした'; _isLoading = false; });
    }
  }

  String get _tempComment {
    if (_temp >= 32) return 'ムシムシ〜！';
    if (_temp >= 28) return 'かなり暑い';
    if (_temp >= 24) return 'やや暑い';
    if (_temp >= 18) return '快適！';
    if (_temp >= 10) return 'やや寒い';
    return '寒い！';
  }

  String get _tempEmoji {
    final desc = _weather?.description ?? '';
    if (desc.contains('Rain') || desc.contains('Drizzle')) return '🌧️';
    if (desc.contains('Thunder')) return '⛈️';
    if (desc.contains('Snow')) return '🌨️';
    if (desc.contains('Clouds')) return '⛅';
    if (_temp >= 28) return '☀️';
    return '🌤️';
  }

  Color get _tempColor {
    if (_temp >= 32) return const Color(0xFFFF6B35);
    if (_temp >= 28) return Colors.orange;
    if (_temp >= 24) return Colors.amber;
    return const Color(0xFF4A90D9);
  }

  Color get _roadColor {
    if (_roadTemp >= 60) return Colors.red.shade900;
    if (_roadTemp >= 50) return const Color(0xFFE53935);
    if (_roadTemp >= 40) return Colors.orange;
    if (_roadTemp >= 35) return Colors.amber;
    return const Color(0xFF4A90D9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F4FD),
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF2B5BA8), size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('☁️', style: TextStyle(fontSize: 22)),
              ),
              const Positioned(
                top: 0,
                child: Text('🐾', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Text('わんソナ', style: TextStyle(color: Color(0xFF2B5BA8), fontSize: 26, fontWeight: FontWeight.w900)),
        ]),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF2B5BA8)), onPressed: _loadWeather),
          const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.settings, color: Color(0xFF2B5BA8), size: 28)),
        ],
      ),
body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icon/1779852692497.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: _currentIndex == 2
          ? const MyDogRecordScreen()
          : _currentIndex == 1
              ? const WalkTopScreen()
              : _currentIndex == 3
                  ? const Center(child: Text('行けるとこマップ coming soon'))
                  : _currentIndex == 4
                      ? const MemoriesScreen()
                      : _isLoading
                          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Color(0xFF4A90D9)), SizedBox(height: 16), Text('天気を取得中 ...🌤'),]))
                          : _errorMessage.isNotEmpty
                              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('😢', style: TextStyle(fontSize: 48)), SizedBox(height: 16), Text(_errorMessage, textAlign: TextAlign.center), SizedBox(height: 24), ElevatedButton(onPressed: _loadWeather, child: const Text('再読み込み')),]))
                              : RefreshIndicator(
                                  onRefresh: _loadWeather,
                                  child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                                      _buildWeatherCard(),
                                      const SizedBox(height: 12),
                                      _buildTimelineCard(),
                                      const SizedBox(height: 12),
                                      _buildAdviceCard(),
                                      const SizedBox(height: 12),
                                      _buildRecommendedItemCard(),
          _buildStoreBanner(),
          _buildTodoRow(),
                                      const SizedBox(height: 80),
                                    ]),
                            ),
                          ),
                        ),
                                  ),
                                ),
                                ),
            bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildWeatherCard() {
    final sunset = _weather?.sunsetTime;
    final sunsetStr = sunset != null
        ? '${sunset!.hour.toString().padLeft(2, '0')}:${sunset.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final weatherIcon = _getWeatherIcon(_weather?.description ?? '');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Text('体感温度', style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
            Text('${_temp.toStringAsFixed(0)}°C',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35))),
            Text(_feelsLikeComment, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ])),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(weatherIcon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 4),
            Text(_weather?.cityName ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Text('路面温度', style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
            Text('${_roadTemp.toStringAsFixed(0)}°C',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _roadTempColor)),
            Text(_roadComment, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('今日の日没 ', style: TextStyle(fontSize: 16, color: Colors.grey)),
          Text(sunsetStr,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF7B2FBE))),
          const Text('  暗くなる前に！', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ]),
      ]),
    );
  }

  Widget _buildAdviceCard() {
    final checkPoints = ['呼吸が荒い', '足裏が熱い', '食欲↓・水分↓'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 72,
            height: 72,
            margin: const EdgeInsets.only(right: 12),
            child: Image.asset('assets/images/cloud_dog.png', fit: BoxFit.contain),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('わんソナからのアドバイス',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_walkAdvice,
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
          ])),
        ]),
        const SizedBox(height: 12),
        const Text('見るポイント：', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...checkPoints.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(p, style: const TextStyle(fontSize: 12)),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4A90D9)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('チャットで相談する', style: TextStyle(color: Color(0xFF4A90D9), fontSize: 13)),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90D9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const FittedBox(fit: BoxFit.scaleDown, child: Text('安全な散歩タイムを見る', style: TextStyle(color: Colors.white, fontSize: 13))),
          )),
        ]),
      ]),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('快適時間  $_comfortTimeLabel',
                style: const TextStyle(color: Color(0xFF1976D2), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          if (_nextComfortTimeLabel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_nextComfortTimeLabel,
                style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
          ),
          ],
        ]),
        const SizedBox(height: 12),
        const Text('本日のお散歩タイム目安',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTimeline(),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _chip('あなた', const Color(0xFF4A90D9), Colors.white),
            _chip('冷感タオル', Colors.grey.shade200, Colors.black87),
            _chip('虫よけ', Colors.grey.shade200, Colors.black87),
            _chip('帽子/キャップ', Colors.grey.shade200, Colors.black87),
            _chip('わんこ', const Color(0xFF4A90D9), Colors.white),
            _chip('水400ml以上', Colors.grey.shade200, Colors.black87),
            _chip('LED首輪', Colors.grey.shade200, Colors.black87),
            _chip('足拭きタオル', Colors.grey.shade200, Colors.black87),
          ],
        ),
      ]),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg)),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTimeline() {
    final colors = _timelineColors;
      final hours = ['0','2','4','6','8','10','12','14','16','18','20','22'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(19, (i) {
          final h = 5 + i;
          if (h >= 6 && h < 18) return const Text('☀️', style: TextStyle(fontSize: 10));
          if (h >= 18 && h < 20) return const Text('🌅', style: TextStyle(fontSize: 10));
          return const Text('🌙', style: TextStyle(fontSize: 10));
        }).toList(),
      ),
      const SizedBox(height: 2),
      CustomPaint(
        size: const Size(double.infinity, 24),
        painter: _TimelinePainter(colors),
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: hours.map((h) => Text(h, style: const TextStyle(fontSize: 10, color: Colors.grey))).toList(),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Container(width: 12, height: 12, color: Colors.blue.shade300),
        const SizedBox(width: 4),
        const Text('快適', style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(width: 8),
        Container(width: 12, height: 12, color: Colors.orange.shade300),
        const SizedBox(width: 4),
        const Text('注意', style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(width: 8),
        Container(width: 12, height: 12, color: Colors.red.shade400),
        const SizedBox(width: 4),
        const Text('危険', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    ]);
  }



  // やることリスト
  List<(String, bool)> _dailyTodos = [];
  List<(String, bool)> _monthlyTodos = [];

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyRaw = prefs.getStringList('daily_todos') ?? ['🌙 夜散歩 20分　20:00〜|false', '肉球クリーム塗る！|false', '夜ご飯と一緒にお薬💊|false'];
    final monthlyRaw = prefs.getStringList('monthly_todos') ?? ['フィラリアのお薬貰う|false', 'お誕生日ケーキ予約🎂|false'];
    setState(() {
      _dailyTodos = dailyRaw.map((s) { final p = s.split('|'); return (p[0], p[1] == 'true'); }).toList();
      _monthlyTodos = monthlyRaw.map((s) { final p = s.split('|'); return (p[0], p[1] == 'true'); }).toList();
    });
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('daily_todos', _dailyTodos.map((t) => '${t.$1}|${t.$2}').toList());
    await prefs.setStringList('monthly_todos', _monthlyTodos.map((t) => '${t.$1}|${t.$2}').toList());
  }

  void _toggleTodo(bool isDaily, int index) {
    setState(() {
      if (isDaily) {
        _dailyTodos[index] = (_dailyTodos[index].$1, !_dailyTodos[index].$2);
      } else {
        _monthlyTodos[index] = (_monthlyTodos[index].$1, !_monthlyTodos[index].$2);
      }
    });
    _saveTodos();
  }

  void _showAllTodos(bool isDaily) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final items = isDaily ? _dailyTodos : _monthlyTodos;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(isDaily ? '今日のやることリスト' : '今月のやることリスト', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const Divider(),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => ListTile(
                    dense: true,
                    leading: GestureDetector(
                      onTap: () {
                        _toggleTodo(isDaily, i);
                        setModalState(() {});
                      },
                      child: Icon(items[i].$2 ? Icons.check_box : Icons.check_box_outline_blank, color: items[i].$2 ? const Color(0xFF4A90D9) : Colors.grey),
                    ),
                    title: Text(items[i].$1, style: TextStyle(fontSize: 13, decoration: items[i].$2 ? TextDecoration.lineThrough : null, color: items[i].$2 ? Colors.grey : Colors.black)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          if (isDaily) _dailyTodos.removeAt(i);
                          else _monthlyTodos.removeAt(i);
                        });
                        _saveTodos();
                        setModalState(() {});
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _addTodo(isDaily);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('追加'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90D9)),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _addTodo(bool isDaily) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDaily ? '今日のやることリスト追加' : '今月のやること追加', style: const TextStyle(fontSize: 14)),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '例：肉球チェックする')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  if (isDaily) _dailyTodos.add((controller.text.trim(), false));
                  else _monthlyTodos.add((controller.text.trim(), false));
                });
                _saveTodos();
              }
              Navigator.pop(ctx);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  // ── おすすめアイテムカード ──────────────────────────────
  Widget _buildRecommendedItemCard() {
    final items = WansonaStoreScreen.storeItems;
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items[0];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreItemDetailScreen(item: item))),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.shopping_bag_outlined, color: Color(0xFF59D4E8), size: 18),
            const SizedBox(width: 6),
            const Text('今日のおすすめアイテム', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2F3A45))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: const Color(0xFFF0FAFC), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF59D4E8)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['name']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2F3A45))),
              const SizedBox(height: 4),
              Text(item['description']!, style: const TextStyle(fontSize: 12, color: Color(0xFF7AB899))),
              const SizedBox(height: 6),

            ])),
            Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                child: Text(item['tag']!, style: const TextStyle(fontSize: 10, color: Color(0xFFFFA94D), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              const Text('詳しく見る ›', style: TextStyle(fontSize: 12, color: Color(0xFF59D4E8), fontWeight: FontWeight.bold)),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStoreBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WansonaStoreScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF59D4E8), Color(0xFF8DE7F5)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(children: [
          const Icon(Icons.storefront_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('わんソナストア', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('お散歩・ケアに役立つアイテムがそろっています', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: const Text('人気アイテムを見る ›', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  Widget _buildTodoRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _buildTodoCard('今日のやることリスト', '天気と体調ログから', _dailyTodos, true)),
      const SizedBox(width: 10),
      Expanded(child: _buildTodoCard('今月のやることリスト', '', _monthlyTodos, false)),
    ]);
  }

  Widget _buildTodoCard(String title, String sub, List<(String, bool)> items, bool isDaily) {
    final displayItems = items.take(3).toList();
    final remaining = items.length - 3;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 8),
        ...displayItems.asMap().entries.map((e) => GestureDetector(
          onTap: () => _toggleTodo(isDaily, e.key),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFF1976D2), fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 4),
              Expanded(child: Text(e.value.$1, style: TextStyle(fontSize: 11, decoration: e.value.$2 ? TextDecoration.lineThrough : null, color: e.value.$2 ? Colors.grey : Colors.black))),
              Icon(e.value.$2 ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: e.value.$2 ? const Color(0xFF4A90D9) : Colors.grey),
            ]),
          ),
        )),
        const SizedBox(height: 6),
        if (remaining > 0)
          OutlinedButton(
            onPressed: () => _showAllTodos(isDaily),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), minimumSize: const Size(0, 28), side: const BorderSide(color: Color(0xFF4A90D9)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: Text('リストを開く（他${remaining}件）', style: const TextStyle(fontSize: 10, color: Color(0xFF4A90D9))),
          )
        else
          Align(alignment: Alignment.centerRight, child: ElevatedButton(
            onPressed: () => _addTodo(isDaily),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90D9), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(0, 28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text('＋追加', style: TextStyle(color: Colors.white, fontSize: 11)),
          )),
      ]),
    );
  }


  Widget _buildBottomNav() {
    final navImages = [
      ['assets/images/nav_home.png', 64.0],
      ['assets/images/nav_walk.png', 76.0],
      ['assets/images/nav_pet.png', 76.0],
      ['assets/images/nav_map.png', 76.0],
      ['assets/images/nav_memory.png', 64.0],
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: navImages.asMap().entries.map((e) {
              final selected = e.key == _currentIndex;
              final size = e.value[1] as double;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = e.key),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    border: selected ? Border.all(color: const Color(0xFF4A90D9), width: 3) : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(e.value[0] as String, fit: BoxFit.contain),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// わんソナストア画面
// ══════════════════════════════════════════════════════════
class WansonaStoreScreen extends StatefulWidget {
  const WansonaStoreScreen({super.key});

  static List<Map<String, dynamic>> storeItems = [
    {
      'name': 'ニオイをしっかり閉じ込める袋',
      'description': 'お出かけの必需品！ニオイ漏れを防いで快適に。',
      'tag': '暑い日やお出かけにおすすめ！',
      'price': '¥980（税込）',
      'points': ['ニオイをしっかり閉じ込める', '中身が見えにくい安心設計', 'コンパクトで持ち運びやすい'],
      'recommend': ['お散歩のニオイが気になる子', 'お出かけや旅行が多い子', '室内でも快適に過ごしたい子'],
      'url': 'https://www.rakuten.co.jp',
      'category': 'お散歩',
    },
    {
      'name': 'クールネックバンド',
      'description': '首まわりを冷やして熱中症対策に。',
      'tag': '暑さ対策',
      'price': '¥1,780（税込）',
      'points': ['繰り返し使える', '軽量で負担が少ない', 'サイズ調整可能'],
      'recommend': ['夏のお散歩が多い子', '熱中症が心配な子'],
      'url': 'https://www.rakuten.co.jp',
      'category': '暑さ対策',
    },
    {
      'name': '足拭きタオル',
      'description': '帰宅後の足拭きに。速乾素材で清潔キープ。',
      'tag': 'お散歩後に',
      'price': '¥980（税込）',
      'points': ['速乾素材', '抗菌防臭加工', '洗濯機で洗える'],
      'recommend': ['散歩後のお手入れをラクにしたい'],
      'url': 'https://www.rakuten.co.jp',
      'category': 'お散歩',
    },
  ];

  static const List<String> categories = ['お散歩', '暑さ対策', '雨の日', '消臭・衛生', 'お出かけ', 'シニア犬'];

  @override
  State<WansonaStoreScreen> createState() => _WansonaStoreScreenState();
}

class _WansonaStoreScreenState extends State<WansonaStoreScreen> {
  bool _loading = true;
  String? _error;

  static const String _csvUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQJhIdaQ2CQJQPwRVTSy_IvymazVuZf7EyH_K0JxEaAMK_a6a3idUetG3f-s53hDWv8GoHsmioiLMxS/pub?gid=1109404046&single=true&output=csv';

  @override
  void initState() {
    super.initState();
    _loadFromSheets();
  }

  Future<void> _loadFromSheets() async {
    try {
      final res = await http.get(Uri.parse(_csvUrl));
      if (res.statusCode == 200) {
        final lines = res.body.split('\n');
        final items = <Map<String, dynamic>>[];
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = _parseCsvLine(line);
          if (cols.length < 9) continue;
          items.add({
            'id': cols[0],
            'name': cols[1],
            'description': cols[2],
            'tag': cols[3],
            'price': cols[4],
            'points': cols[5].split('／'),
            'recommend': cols[6].split('／'),
            'url': cols[7],
            'category': cols[8],
          });
        }
        if (mounted) setState(() { WansonaStoreScreen.storeItems = items; _loading = false; });
      } else {
        if (mounted) setState(() { _error = 'HTTP ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'エラー: $e'; _loading = false; });
      }
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final buf = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') { inQuotes = !inQuotes; }
      else if (c == ',' && !inQuotes) { result.add(buf.toString().trim()); buf.clear(); }
      else { buf.write(c); }
    }
    result.add(buf.toString().trim());
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF59D4E8))));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));
    final items = WansonaStoreScreen.storeItems;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF59D4E8),
        foregroundColor: Colors.white,
        title: const Text('わんソナストア', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [const Icon(Icons.shopping_cart_outlined), const SizedBox(width: 16)],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // 検索バー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Row(children: [
            const Icon(Icons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            const Text('なにをお探しですか？', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 16),
        // カテゴリ
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WansonaStoreScreen.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => Column(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFE8F8FB), shape: BoxShape.circle),
                child: const Icon(Icons.pets, color: Color(0xFF59D4E8), size: 22),
              ),
              const SizedBox(height: 4),
              Text(WansonaStoreScreen.categories[i], style: const TextStyle(fontSize: 10, color: Color(0xFF2F3A45))),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        // 人気アイテム
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('人気アイテム', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2F3A45))),
          const Text('もっと見る ›', style: TextStyle(fontSize: 12, color: Color(0xFF59D4E8))),
        ]),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.72, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreItemDetailScreen(item: item))),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      height: 64, width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFFF0FAFC), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF59D4E8), size: 30),
                    ),
                    const SizedBox(height: 6),
                    Text(item['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2F3A45)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),

                    Text(item['price']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2F3A45))),
                  ]),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // 特集バナー
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('暑さ対策アイテム特集', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2F3A45))),
            const Text('暑い日のお散歩を快適に', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFFA94D), borderRadius: BorderRadius.circular(20)),
              child: const Text('特集を見る', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 商品詳細画面
// ══════════════════════════════════════════════════════════
class StoreItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const StoreItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2F3A45),
        title: const Text('おすすめアイテム', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        elevation: 0.5,
        actions: [const Icon(Icons.share_outlined), const SizedBox(width: 16)],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // 商品画像エリア
        Container(
          height: 200,
          decoration: BoxDecoration(color: const Color(0xFFF0FAFC), borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Icon(Icons.inventory_2_outlined, size: 80, color: Color(0xFF59D4E8))),
        ),
        const SizedBox(height: 16),
        // 商品名・評価
        Text(item['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F3A45))),
        const SizedBox(height: 6),

        Text(item['description']!, style: const TextStyle(fontSize: 13, color: Color(0xFF7AB899))),
        const SizedBox(height: 16),
        // ポイント
        ...( item['points'] as List<String>).map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            const Icon(Icons.check_box, color: Color(0xFF59D4E8), size: 18),
            const SizedBox(width: 8),
            Text(p, style: const TextStyle(fontSize: 13, color: Color(0xFF2F3A45))),
          ]),
        )),
        const SizedBox(height: 16),
        // 価格
        Text(item['price']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2F3A45))),
        const SizedBox(height: 12),
        // 購入ボタン
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(item['url']!);
              // url_launcherなしのため、スナックバーで案内
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('商品ページ: ${item['url']}'), backgroundColor: const Color(0xFF59D4E8)),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('商品を詳しく見る', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA94D), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(height: 16),
        // こんな子におすすめ
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFE8F8FB), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('こんな子におすすめ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF59D4E8))),
            const SizedBox(height: 8),
            ...(item['recommend'] as List<String>).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.pets, size: 14, color: Color(0xFF59D4E8)),
                const SizedBox(width: 6),
                Text(r, style: const TextStyle(fontSize: 12, color: Color(0xFF2F3A45))),
              ]),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<Color> colors;
  _TimelinePainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final blockW = size.width / colors.length;
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i];
      canvas.drawRect(
        Rect.fromLTWH(i * blockW, 0, blockW, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => old.colors != colors;
}
