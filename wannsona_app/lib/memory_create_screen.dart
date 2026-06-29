import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'memories_screen.dart';

class MemoryCreateScreen extends StatefulWidget {
  final Memory? existing;
  const MemoryCreateScreen({super.key, this.existing});

  @override
  State<MemoryCreateScreen> createState() => _MemoryCreateScreenState();
}

class _MemoryCreateScreenState extends State<MemoryCreateScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  String _category = 'その他';
  String _memoryDate = '';
  bool _isSaving = false;

  final List<String> _categories = ['おでかけ', 'イベント', '季節', '日常', 'その他'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _memoController.text = widget.existing!.memo;
      _category = widget.existing!.category;
      _memoryDate = widget.existing!.memoryDate;
    } else {
      _memoryDate = DateTime.now().toString().substring(0, 10);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('memories') ?? '[]';
    final list = (jsonDecode(data) as List).map((e) => Memory.fromJson(e)).toList();

    if (widget.existing != null) {
      final idx = list.indexWhere((m) => m.id == widget.existing!.id);
      if (idx >= 0) {
        list[idx] = Memory(
          id: widget.existing!.id,
          dogId: widget.existing!.dogId,
          title: _titleController.text.trim(),
          memo: _memoController.text.trim(),
          category: _category,
          memoryDate: _memoryDate,
          createdAt: widget.existing!.createdAt,
          weatherIcon: widget.existing!.weatherIcon,
          weatherName: widget.existing!.weatherName,
          temperature: widget.existing!.temperature,
          walkMinutes: widget.existing!.walkMinutes,
          photos: widget.existing!.photos,
        );
      }
    } else {
      final newMemory = Memory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dogId: prefs.getString('dog_name') ?? '',
        title: _titleController.text.trim(),
        memo: _memoController.text.trim(),
        category: _category,
        memoryDate: _memoryDate,
        createdAt: DateTime.now().toIso8601String(),
      );
      list.insert(0, newMemory);
    }

    await prefs.setString('memories', jsonEncode(list.map((m) => m.toJson()).toList()));
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_memoryDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _memoryDate = picked.toString().substring(0, 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF2D5DA6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? '思い出を編集' : '思い出を作る',
          style: const TextStyle(color: Color(0xFF2D5DA6), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('保存', style: TextStyle(color: Color(0xFF4A90D9), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('タイトル *', TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '例：お花見散歩、誕生日',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                filled: true, fillColor: Colors.white,
              ),
            )),
            const SizedBox(height: 16),
            _buildSection('日付', GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF4A90D9), size: 18),
                    const SizedBox(width: 12),
                    Text(_memoryDate, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
            _buildSection('カテゴリ', Wrap(
              spacing: 8, runSpacing: 8,
              children: _categories.map((cat) {
                final selected = cat == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF4A90D9) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? const Color(0xFF4A90D9) : const Color(0xFFCCCCCC)),
                    ),
                    child: Text(cat, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF555555),
                    )),
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 16),
            _buildSection('メモ（任意）', TextField(
              controller: _memoController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '今日の出来事や気づいたことを残しておこう',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                filled: true, fillColor: Colors.white,
              ),
            )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
