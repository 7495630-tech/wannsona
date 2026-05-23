import 'package:flutter/material.dart';
import 'weather_service.dart';

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
  bool _isLoading = true;
  String _errorMessage = '';
  WeatherData? _weather;

  double get _temp => _weather?.feelsLike ?? 32.0;
  double get _roadTemp => _temp + 20;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final weather = await WeatherService().getCurrentWeather();
      setState(() { _weather = weather; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = '天気を取得できませんでした\n再読み込みしてください'; _isLoading = false; });
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

  String get _roadComment {
    if (_roadTemp >= 55) return '足裏アチアチ🔥';
    if (_roadTemp >= 45) return '足裏かなり熱い';
    if (_roadTemp >= 35) return '足裏注意';
    return '足裏OK';
  }

  String get _tempEmoji {
    if (_temp >= 32) return '☀️';
    if (_temp >= 24) return '⛅';
    if (_temp >= 15) return '🌤️';
    return '🌥️';
  }

  Color get _tempColor {
    if (_temp >= 32) return const Color(0xFFFF6B35);
    if (_temp >= 28) return Colors.orange;
    if (_temp >= 24) return Colors.amber;
    return const Color(0xFF4A90D9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F4FD),
        elevation: 0,
        leading: const Icon(Icons.menu, color: Color(0xFF2B5BA8), size: 28),
        title: const Text('わんソナ', style: TextStyle(color: Color(0xFF2B5BA8), fontSize: 26, fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2B5BA8)),
            onPressed: _loadWeather,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings, color: Color(0xFF2B5BA8), size: 28),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF4A90D9)),
                SizedBox(height: 16),
                Text('天気を取得中...🌤️'),
              ],
            ))
          : _errorMessage.isNotEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('😢', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(_errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _loadWeather, child: const Text('再読み込み')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadWeather,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildWeatherCard(),
                        const SizedBox(height: 12),
                        _buildTimelineCard(),
                        const SizedBox(height: 12),
                        _buildAdviceCard(),
                        const SizedBox(height: 12),
                        _buildTodoRow(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [
                const Text('体感温度', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text('${_temp.round()}℃', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _tempColor)),
                Text(_tempComment, style: TextStyle(fontSize: 12, color: _tempColor)),
              ]),
              Text(_tempEmoji, style: const TextStyle(fontSize: 56)),
              Column(children: [
                const Text('路面温度', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text('${_roadTemp.round()}℃', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
                Text(_roadComment, style: const TextStyle(fontSize: 12, color: Color(0xFFE53935))),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE8F4FD), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📍 ', style: TextStyle(fontSize: 15)),
                Text(_weather?.cityName ?? '取得中...', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Text('　湿度：', style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text('${_weather?.humidity ?? '--'}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _badge('快適時間　19:00〜21:00', const Color(0xFFE3F2FD), const Color(0xFF1976D2)),
            const SizedBox(width: 8),
            _badge('次　5:00〜6:00', const Color(0xFFFCE4EC), const Color(0xFFE91E63)),
          ]),
          const SizedBox(height: 10),
          const Text('本日のお散歩タイム目安', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTimeline(),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _chip('あなた', const Color(0xFF4A90D9), Colors.white),
            _chip('冷感タオル', Colors.grey.shade200, Colors.black87),
            _chip('虫よけ', Colors.grey.shade200, Colors.black87),
            _chip('帽子/キャップ', Colors.grey.shade200, Colors.black87),
            _chip('わんこ', const Color(0xFF8BC34A), Colors.white),
            _chip('水400ml以上', Colors.grey.shade200, Colors.black87),
            _chip('LED首輪', Colors.grey.shade200, Colors.black87),
            _chip('足拭きタオル', Colors.grey.shade200, Colors.black87),
          ]),
        ],
      ),
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
    final colors = [Colors.grey.shade300, Colors.grey.shade300, Colors.orange.shade300, Colors.red.shade400, Colors.red.shade600, Colors.red.shade400, Colors.orange.shade300, Colors.blue.shade300, Colors.blue.shade600, Colors.blue.shade300, Colors.grey.shade400, Colors.grey.shade300];
    final hours = ['5','7','9','11','13','15','17','19','21','23'];
    return Column(children: [
      Row(children: colors.map((c) => Expanded(child: Container(height: 20, color: c))).toList()),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: hours.map((h) => Text(h, style: const TextStyle(fontSize: 10, color: Colors.grey))).toList()),
    ]);
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAdviceCard() {
    String advice;
    if (_temp >= 32) {
      advice = '今日は暑さが強めです。お散歩は日没後20:00〜21:00が安心です。お水は400ml以上を目安に、日陰ルートで短めが良さそうです。無理に外に行かない選択も、立派なケアです。';
    } else if (_temp >= 28) {
      advice = 'やや暑めです。朝夕の涼しい時間帯を選んで。水分補給をしっかり忘れずに！';
    } else if (_temp >= 18) {
      advice = '今日は散歩日和です！思い切り楽しんで🐾 水分補給も忘れずに。';
    } else {
      advice = '少し肌寒いです。防寒対策をして短時間から様子を見てみましょう。';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('わんソナからのアドバイス', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(advice, style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF4A90D9)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: const Text('チャットで相談する', style: TextStyle(color: Color(0xFF4A90D9))),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: const Text('安全な散歩タイムを見る', style: TextStyle(color: Colors.white, fontSize: 12)),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildTodoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTodoCard('今日のやること', '天気と体調ログから', [('🌙 夜散歩 20分　20:00〜', true), ('肉球クリーム塗る！', false), ('夜ご飯と一緒にお薬💊', false)], '他3件')),
        const SizedBox(width: 10),
        Expanded(child: _buildTodoCard('今月のやること', '', [('フィラリアのお薬貰う', true), ('お誕生日ケーキ予約🎂', true), ('', false)], null)),
      ],
    );
  }

  Widget _buildTodoCard(String title, String sub, List<(String, bool)> items, String? more) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Text('${e.key + 1}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 4),
              Expanded(child: Text(e.value.$1, style: const TextStyle(fontSize: 11))),
              Icon(e.value.$2 ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: e.value.$2 ? const Color(0xFF4A90D9) : Colors.grey),
            ]),
          )),
          const SizedBox(height: 6),
          if (more != null)
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), minimumSize: const Size(0, 28), side: const BorderSide(color: Color(0xFF4A90D9)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Text('リストを開く（$more）', style: const TextStyle(fontSize: 10, color: Color(0xFF4A90D9))),
            )
          else
            Align(alignment: Alignment.centerRight, child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90D9), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(0, 28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('＋追加', style: TextStyle(color: Colors.white, fontSize: 11)),
            )),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [('🏠', 'HOME'), ('🚶', 'お散歩'), ('🐕', 'うちの子\n記録'), ('👥', 'コミュニティ'), ('📖', '思い出')];
    return Container(
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final selected = e.key == _currentIndex;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = e.key),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: selected ? const Color(0xFF4A90D9) : Colors.transparent, shape: BoxShape.circle),
                    child: Text(e.value.$1, style: const TextStyle(fontSize: 22)),
                  ),
                  Text(e.value.$2, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: selected ? const Color(0xFF4A90D9) : Colors.grey, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                ]),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
