import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'breed_data.dart';
import 'breed_select_screen.dart';

class DogProfileScreen extends StatefulWidget {
  const DogProfileScreen({super.key});

  @override
  State<DogProfileScreen> createState() => _DogProfileScreenState();
}

class _DogProfileScreenState extends State<DogProfileScreen> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  Breed? _selectedBreed;
  DateTime? _birthDate;
  bool _hasSavedProfile = false;

  // 体重→サイズ自動判定
  String get _autoSize {
    final w = double.tryParse(_weightController.text) ?? 0;
    if (w <= 4) return 'SS（超小型）';
    if (w <= 10) return 'S（小型）';
    if (w <= 25) return 'M（中型）';
    if (w <= 45) return 'L（大型）';
    return 'XL（超大型）';
  }

  // 生年月日→年齢自動計算
  String get _autoAge {
    if (_birthDate == null) return '未設定';
    final now = DateTime.now();
    final months = (now.year - _birthDate!.year) * 12 +
        now.month - _birthDate!.month;
    if (months < 1) return '生後1ヶ月未満';
    if (months < 12) return '生後${months}ヶ月';
    final years = months ~/ 12;
    final rem = months % 12;
    return rem == 0 ? '$years歳' : '$years歳${rem}ヶ月';
  }

  // 年齢区分
  String get _ageGroup {
    if (_birthDate == null) return '不明';
    final months = (DateTime.now().year - _birthDate!.year) * 12 +
        DateTime.now().month - _birthDate!.month;
    if (months < 12) return '子犬';
    if (months < 84) return '成犬';
    return 'シニア';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('dog_name') ?? '';
      _weightController.text = prefs.getString('dog_weight') ?? '';
      final breedId = prefs.getString('dog_breed_id') ?? '';
      if (breedId.isNotEmpty) {
        try {
          _selectedBreed = allBreeds.firstWhere((b) => b.id == breedId);
        } catch (_) {}
      }
      final birthStr = prefs.getString('dog_birth_date') ?? '';
      if (birthStr.isNotEmpty) {
        _birthDate = DateTime.tryParse(birthStr);
      }
      _hasSavedProfile = prefs.getBool('has_profile') ?? false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dog_name', _nameController.text);
    await prefs.setString('dog_weight', _weightController.text);
    await prefs.setString('dog_breed_id', _selectedBreed?.id ?? '');
    await prefs.setString('dog_birth_date', _birthDate?.toIso8601String() ?? '');
    await prefs.setString('dog_age_group', _ageGroup);
    await prefs.setString('dog_size', _autoSize);
    await prefs.setBool('has_profile', true);
    setState(() => _hasSavedProfile = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを保存しました🐾')),
      );
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      helpText: '生年月日を選んでください',
      cancelText: 'キャンセル',
      confirmText: '決定',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        title: const Text('わんこのプロフィール',
            style: TextStyle(
                color: Color(0xFF4A90D9),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🐾 うちの子を登録しよう',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // 名前
            _buildLabel('名前'),
            _buildTextField(_nameController, 'ゆず、たろう など'),
            const SizedBox(height: 16),

            // 犬種
            _buildLabel('犬種'),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<Breed>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BreedSelectScreen(initialBreed: _selectedBreed),
                  ),
                );
                if (result != null) setState(() => _selectedBreed = result);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedBreed?.jaName ?? '犬種を選ぶ',
                        style: TextStyle(
                          color: _selectedBreed != null
                              ? Colors.black87
                              : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 体重
            _buildLabel('体重（kg）'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '例：5.2',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_weightController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_autoSize,
                        style: const TextStyle(
                            color: Color(0xFF4A90D9),
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 生年月日
            _buildLabel('生年月日'),
            GestureDetector(
              onTap: _pickBirthDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _birthDate != null
                            ? '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日（$_autoAge）'
                            : '生年月日を選ぶ',
                        style: TextStyle(
                          color:
                              _birthDate != null ? Colors.black87 : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today,
                        color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
            if (_birthDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('年齢区分：$_ageGroup',
                    style: const TextStyle(
                        color: Color(0xFF4A90D9), fontSize: 13)),
              ),
            const SizedBox(height: 32),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('保存する', style: TextStyle(fontSize: 16)),
              ),
            ),

            // 登録済みプロフィール表示
            if (_hasSavedProfile) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF4A90D9), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ 登録済みプロフィール',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A90D9))),
                    const SizedBox(height: 8),
                    Text('名前：${_nameController.text}'),
                    Text('犬種：${_selectedBreed?.jaName ?? '未設定'}'),
                    Text('体重：${_weightController.text}kg　$_autoSize'),
                    Text('年齢：$_autoAge（$_ageGroup）'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
