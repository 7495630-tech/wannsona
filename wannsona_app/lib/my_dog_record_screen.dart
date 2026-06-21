import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyDogRecordScreen extends StatefulWidget {
  const MyDogRecordScreen({super.key});
  @override
  State<MyDogRecordScreen> createState() => _MyDogRecordScreenState();
}

class _MyDogRecordScreenState extends State<MyDogRecordScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _meal = '';
  String _water = '';
  String _toilet = '';
  String _energy = '';
  String _memo = '';
  final TextEditingController _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _meal = prefs.getString('meal_today') ?? '';
      _water = prefs.getString('water_today') ?? '';
      _toilet = prefs.getString('toilet_today') ?? '';
      _energy = prefs.getString('energy_today') ?? '';
      _memo = prefs.getString('memo_today') ?? '';
      _memoController.text = _memo;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meal_today', _meal);
    await prefs.setString('water_today', _water);
    await prefs.setString('toilet_today', _toilet);
    await prefs.setString('energy_today', _energy);
    await prefs.setString('memo_today', _memo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C42),
        title: const Text('うちの子記録', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: '今日の記録'), Tab(text: '体調メモ')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTodayRecord(), _buildHealthMemo()],
      ),
    );
  }

  Widget _buildTodayRecord() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ごはん'),
          _chips(['完食', '半分', '少なめ', '食べず'], _meal, (v) { setState(() => _meal = v); _saveData(); }),
          const SizedBox(height: 16),
          _sectionTitle('水分'),
          _chips(['よく飲んだ', '普通', '少なめ', 'ほぼ飲まず'], _water, (v) { setState(() => _water = v); _saveData(); }),
          const SizedBox(height: 16),
          _sectionTitle('排泄'),
          _chips(['問題なし', '回数多め', '回数少なめ', '未確認'], _toilet, (v) { setState(() => _toilet = v); _saveData(); }),
          const SizedBox(height: 16),
          _sectionTitle('元気度'),
          _chips(['元気いっぱい', '普通', '少し元気なし', 'ぐったり'], _energy, (v) { setState(() => _energy = v); _saveData(); }),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Text(
              '今日のまとめ\nごはん：${_meal.isEmpty ? "未記録" : _meal}\n水分：${_water.isEmpty ? "未記録" : _water}\n排泄：${_toilet.isEmpty ? "未記録" : _toilet}\n元気度：${_energy.isEmpty ? "未記録" : _energy}',
              style: const TextStyle(fontSize: 14, height: 2.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMemo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('気になった様子・メモ'),
          const Text('※診断用途ではありません', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _memoController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: '例：少し暑そうだった、よく寝ている、食欲少なめ...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) { _memo = v; _saveData(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _chips(List<String> options, String selected, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      children: options.map((o) => ChoiceChip(
        label: Text(o),
        selected: selected == o,
        selectedColor: const Color(0xFFFF8C42),
        labelStyle: TextStyle(color: selected == o ? Colors.white : Colors.black87),
        onSelected: (_) => onSelect(o),
      )).toList(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
