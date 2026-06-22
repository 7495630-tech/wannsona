import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'breed_select_screen.dart';
import 'breed_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  String _dogName = '';
  String _dogBreed = '';
  String _dogBreedId = '';
  int _birthYear = DateTime.now().year - 2;
  int _birthMonth = 1;
  int _birthDay = 1;
  bool _birthUnknown = false;
  double _dogWeight = 5.0;
  List<String> _concerns = [];

  final List<Map<String, String>> _concernItems = [
    {'label': '雷が苦手', 'icon': '⛈'},
    {'label': '暑さが苦手', 'icon': '☀️'},
    {'label': '寒さが苦手', 'icon': '❄️'},
    {'label': '夜のお散歩が多い', 'icon': '🌙'},
    {'label': '他の犬が苦手', 'icon': '🐕'},
    {'label': '人が苦手', 'icon': '👤'},
    {'label': '持病・アレルギーがある', 'icon': '💊'},
  ];

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _saveAndFinish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveAndFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dog_name', _dogName);
    await prefs.setString('dog_breed', _dogBreed);
    await prefs.setString('dog_breed_id', _dogBreedId);
    if (!_birthUnknown) {
      final birth = DateTime(_birthYear, _birthMonth, _birthDay);
      await prefs.setString('dog_birth', birth.toIso8601String());
    }
    await prefs.setString('dog_weight', _dogWeight.toString());
    await prefs.setStringList('dog_concerns', _concerns);
    await prefs.setBool('first_launch', false);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CompleteScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD6EFFF), Color(0xFFF0F8FF)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            if (_currentStep > 0) _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        GestureDetector(
          onTap: _prevStep,
          child: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A90D9), size: 20),
        ),
        Expanded(
          child: Column(children: [
            Text('🐾  ステップ ${_currentStep + 1}/5', style: const TextStyle(fontSize: 13, color: Color(0xFF4A90D9), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: i <= _currentStep ? 30 : 20,
                height: 6,
                decoration: BoxDecoration(
                  color: i <= _currentStep ? const Color(0xFF4A90D9) : const Color(0xFFCCE4F6),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            })),
          ]),
        ),
        const SizedBox(width: 36),
      ]),
    );
  }

  // STEP1: 名前入力
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Text('🐾', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('わんソナ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2B5BA8))),
        ]),
        const SizedBox(height: 12),
        const Text('ようこそ、わんソナへ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B))),
        const SizedBox(height: 6),
        const Text('まずは、\nうちの子のことを教えてね。', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.6)),
        const SizedBox(height: 12),
        Image.asset('assets/images/dog_welcome.png', height: 220, fit: BoxFit.contain),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('お名前 ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('🐾', style: TextStyle(fontSize: 14)),
            ]),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _dogName = v),
              decoration: InputDecoration(
                hintText: '例：そな',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCCE4F6))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 2)),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('🌸  あとから変更できます', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        const SizedBox(height: 20),
        _mainBtn('つぎへ  >', _dogName.isNotEmpty ? _nextStep : null),
        const SizedBox(height: 20),
      ]),
    );
  }

  // STEP2: 犬種選択
  Widget _buildStep2() {
    final popular = [
      {'name': 'トイプードル', 'img': 'assets/images/breed_toy_poodle.png'},
      {'name': '柴犬', 'img': 'assets/images/breed_shiba.png'},
      {'name': 'ゴールデンレトリバー', 'img': 'assets/images/breed_golden.png'},
      {'name': 'チワワ', 'img': 'assets/images/breed_chihuahua.png'},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('うちの子に近い\n犬種を教えてね', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B), height: 1.3)),
        const SizedBox(height: 4),
        const Text('あとからいつでも変更できます', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BreedSelectScreen()));
            if (result != null && result is Breed) setState(() { _dogBreed = result.jaName; _dogBreedId = result.id; });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
            child: Row(children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Text(_dogBreed.isNotEmpty ? _dogBreed : '犬種名で検索（例：コーギー、レトリバー）',
                style: TextStyle(color: _dogBreed.isNotEmpty ? const Color(0xFF4A90D9) : Colors.grey, fontSize: 13)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BreedSelectScreen()));
            if (result != null && result is Breed) setState(() { _dogBreed = result.jaName; _dogBreedId = result.id; });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A90D9).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Text('📖', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('犬種一覧を見る', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B))),
                const Text('200犬種以上に対応！', style: TextStyle(fontSize: 12, color: Color(0xFF4A90D9))),
                const SizedBox(height: 6),
                ...['JKC・AKC準拠の豊富な犬種データ', 'MIXの子も選択できます', 'いつでもあとから変更できます'].map((t) =>
                  Row(children: [const Icon(Icons.check_circle, color: Color(0xFF4A90D9), size: 13), const SizedBox(width: 4), Text(t, style: const TextStyle(fontSize: 11))])),
              ])),
              const Icon(Icons.chevron_right, color: Color(0xFF4A90D9)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        const Text('🐾  最近よく選ばれている犬種', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9))),
        const SizedBox(height: 10),
        Row(children: popular.map((b) {
          final sel = _dogBreed == b['name'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _dogBreed = b['name']!; _dogBreedId = b['name']!; }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFD6EFFF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: sel ? Border.all(color: const Color(0xFF4A90D9), width: 2) : null,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(children: [
                  Image.asset(b['img']!, height: 52, fit: BoxFit.contain),
                  const SizedBox(height: 4),
                  Text(b['name']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                ]),
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 14),
GestureDetector(
          onTap: () {
            setState(() { _dogBreed = 'MIX（ミックス犬）'; });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _dogBreed == 'MIX（ミックス犬）' ? const Color(0xFFFFE8D0) : const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _dogBreed == 'MIX（ミックス犬）' ? Colors.orange : Colors.orange.shade200),
            ),
            child: Row(children: const [
              Text('🐾', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MIX（ミックス犬）の子はこちら', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('MIXの子を選びたい方はこちらから', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              Icon(Icons.chevron_right, color: Colors.grey),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF0F8FF), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Text('💡', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('わからなくても大丈夫！', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9))),
              Text('迷ったときは、おおまかに選んでOKです◎', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _subBtn('もどる', _prevStep)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _mainBtn('つぎへ  >', _nextStep)),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }

  // STEP3: 誕生日
  Widget _buildStep3() {
    int ageY = 0, ageM = 0;
    if (!_birthUnknown) {
      final diff = DateTime.now().difference(DateTime(_birthYear, _birthMonth, _birthDay)).inDays;
      ageY = diff ~/ 365; ageM = (diff % 365) ~/ 30;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('うちの子の\nお誕生日を教えてね', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B), height: 1.3)),
            SizedBox(height: 4),
            Text('年齢に合わせたサポートができます', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ])),
          Image.asset('assets/images/cloud_dog.png', width: 80, height: 80, fit: BoxFit.contain),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Column(children: [
            const Row(children: [Text('📅 ', style: TextStyle(fontSize: 18)), Text('お誕生日を選択', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _dropdown(List.generate(25, (i) => '${DateTime.now().year - i}年'), '${_birthYear}年', (v) => setState(() => _birthYear = int.parse(v!.replaceAll('年', ''))))),
              const SizedBox(width: 8),
              Expanded(child: _dropdown(List.generate(12, (i) => '${i + 1}月'), '${_birthMonth}月', (v) => setState(() => _birthMonth = int.parse(v!.replaceAll('月', ''))))),
              const SizedBox(width: 8),
              Expanded(child: _dropdown(List.generate(31, (i) => '${i + 1}日'), '${_birthDay}日', (v) => setState(() => _birthDay = int.parse(v!.replaceAll('日', ''))))),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0F8FF), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Text('🎂 ', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$_birthYear年${_birthMonth}月${_birthDay}日 生まれ', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF4A90D9).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('🐾  $ageY歳${ageM}か月', style: const TextStyle(fontSize: 13, color: Color(0xFF4A90D9), fontWeight: FontWeight.bold)),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF0F8FF), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡  お誕生日を登録すると…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9))),
            const SizedBox(height: 8),
            ...['年齢に合わせたアドバイスが届きます', 'シニア期のサポートも充実します', '成長の記録をふり返ることができます'].map((t) =>
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
                const Icon(Icons.check_circle, color: Color(0xFF4A90D9), size: 14),
                const SizedBox(width: 6),
                Text(t, style: const TextStyle(fontSize: 12)),
              ]))),
          ]),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () { setState(() => _birthUnknown = true); _nextStep(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: const Row(children: [
              Text('📅 ', style: TextStyle(fontSize: 16)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('わからない場合はあとで設定できます', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('いつでもプロフィールから変更できます', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              Icon(Icons.chevron_right, color: Colors.grey),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _subBtn('もどる', _prevStep)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _mainBtn('つぎへ  >', _nextStep)),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _dropdown(List<String> items, String value, void Function(String?) onChange) {
    final v = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: DropdownButton<String>(
        value: v, isExpanded: true, underline: const SizedBox(),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChange,
      ),
    );
  }

  // STEP4: 体重
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('うちの子の\n体重を教えてね', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B), height: 1.3)),
            SizedBox(height: 4),
            Text('よりぴったりなアドバイスをお届けするために', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ])),
          Image.asset('assets/images/cloud_dog.png', width: 80, height: 80, fit: BoxFit.contain),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Column(children: [
            const Row(children: [Text('⚖️ ', style: TextStyle(fontSize: 18)), Text('体重を入力', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_dogWeight.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B))),
                const SizedBox(width: 8),
                const Text('kg', style: TextStyle(fontSize: 20, color: Colors.grey)),
              ]),
            ),
            Slider(
              value: _dogWeight, min: 0.5, max: 80,
              activeColor: const Color(0xFF4A90D9),
              inactiveColor: const Color(0xFFCCE4F6),
              onChanged: (v) => setState(() => _dogWeight = (v * 10).round() / 10),
            ),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('0.5kg', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('80kg', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0F8FF), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Text('💡 ', style: TextStyle(fontSize: 16)),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('体重はあとから変更できます', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('こまめに更新すると、より最適な提案ができます', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ])),
                Image.asset('assets/images/cloud_dog.png', width: 44, height: 44, fit: BoxFit.contain),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF0F8FF), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💙  年齢や体重に合わせて', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9))),
            const SizedBox(height: 8),
            ...['お散歩の時間や距離を調整', '必要な持ち物や量を提案', '健康管理のサポートが充実'].map((t) =>
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
                const Icon(Icons.check_circle, color: Color(0xFF4A90D9), size: 14),
                const SizedBox(width: 6),
                Text(t, style: const TextStyle(fontSize: 12)),
              ]))),
          ]),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () { _nextStep(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: const Row(children: [
              Text('📅 ', style: TextStyle(fontSize: 16)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('わからない場合はスキップできます', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('あとからいつでも設定・変更できます', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              Icon(Icons.chevron_right, color: Colors.grey),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _subBtn('もどる', _prevStep)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _mainBtn('つぎへ  >', _nextStep)),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }

  // STEP5: 気をつけたいこと
  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('うちの子について\n教えてね', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B), height: 1.3)),
            SizedBox(height: 4),
            Text('よりぴったりな提案のために', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ])),
          Image.asset('assets/images/cloud_dog_wave.png', width: 90, height: 90, fit: BoxFit.contain),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('🛡️ ', style: TextStyle(fontSize: 18)),
              Text('気をつけたいこと ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('（複数選択OK）', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 12),
            ...List.generate((_concernItems.length / 2).ceil(), (row) {
              final left = _concernItems[row * 2];
              final right = row * 2 + 1 < _concernItems.length ? _concernItems[row * 2 + 1] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: _concernCard(left)),
                  const SizedBox(width: 8),
                  right != null ? Expanded(child: _concernCard(right)) : const Expanded(child: SizedBox()),
                ]),
              );
            }),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF0F8FF), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Text('💡 ', style: TextStyle(fontSize: 16)),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('わからない場合は選ばなくても大丈夫', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9))),
              Text('あとからマイページでいつでも変更できます', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            Image.asset('assets/images/cloud_dog.png', width: 44, height: 44, fit: BoxFit.contain),
          ]),
        ),
        const SizedBox(height: 20),
        _mainBtn('わんソナを始める  >', _nextStep),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _concernCard(Map<String, String> item) {
    final sel = _concerns.contains(item['label']);
    return GestureDetector(
      onTap: () => setState(() { if (sel) _concerns.remove(item['label']); else _concerns.add(item['label']!); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFEBF5FF) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? const Color(0xFF4A90D9) : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          Text(item['icon']!, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(item['label']!, style: TextStyle(fontSize: 12, color: sel ? const Color(0xFF1A3A6B) : Colors.black87))),
          Icon(sel ? Icons.check_box : Icons.check_box_outline_blank, color: sel ? const Color(0xFF4A90D9) : Colors.grey, size: 18),
        ]),
      ),
    );
  }

  Widget _mainBtn(String label, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _subBtn(String label, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDE8D8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF996644), fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class CompleteScreen extends StatelessWidget {
  const CompleteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD6EFFF), Color(0xFFF8FBFF)],
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            Positioned(top: 20, left: 20, child: _cloud(80)),
            Positioned(top: 80, right: 20, child: _cloud(60)),
            Positioned(top: 150, left: 80, child: _cloud(40)),
            Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset('assets/images/cloud_dog_wave.png', width: 160, height: 160, fit: BoxFit.contain),
                const SizedBox(height: 32),
                const Text('さぁ、はじめよう', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A3A6B))),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.home, color: Colors.white),
                      SizedBox(width: 8),
                      Text('ホームへ', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Text('>', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _cloud(double size) => Container(
    width: size, height: size * 0.6,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(size * 0.3)),
  );
}
