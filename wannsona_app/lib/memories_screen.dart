import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'memory_detail_screen.dart';
import 'memory_create_screen.dart';

class Memory {
  final String id;
  final String dogId;
  final String title;
  final String memo;
  final String category;
  final String memoryDate;
  final String createdAt;
  final String weatherIcon;
  final String weatherName;
  final double temperature;
  final int walkMinutes;
  final List<String> photos;

  Memory({
    required this.id,
    required this.dogId,
    required this.title,
    required this.memo,
    required this.category,
    required this.memoryDate,
    required this.createdAt,
    this.weatherIcon = '',
    this.weatherName = '',
    this.temperature = 0,
    this.walkMinutes = 0,
    this.photos = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'dogId': dogId, 'title': title, 'memo': memo,
    'category': category, 'memoryDate': memoryDate, 'createdAt': createdAt,
    'weatherIcon': weatherIcon, 'weatherName': weatherName,
    'temperature': temperature, 'walkMinutes': walkMinutes, 'photos': photos,
  };

  factory Memory.fromJson(Map<String, dynamic> j) => Memory(
    id: j['id'] ?? '', dogId: j['dogId'] ?? '', title: j['title'] ?? '',
    memo: j['memo'] ?? '', category: j['category'] ?? 'その他',
    memoryDate: j['memoryDate'] ?? '', createdAt: j['createdAt'] ?? '',
    weatherIcon: j['weatherIcon'] ?? '', weatherName: j['weatherName'] ?? '',
    temperature: (j['temperature'] ?? 0).toDouble(),
    walkMinutes: j['walkMinutes'] ?? 0,
    photos: List<String>.from(j['photos'] ?? []),
  );
}

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});
  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  String _selectedCategory = 'すべて';
  List<Memory> _memories = [];
  final List<String> _categories = ['すべて', 'おでかけ', 'イベント', '季節', '日常', 'その他'];

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('memories') ?? '[]';
    final list = jsonDecode(data) as List;
    setState(() {
      _memories = list.map((e) => Memory.fromJson(e)).toList()
        ..sort((a, b) => b.memoryDate.compareTo(a.memoryDate));
    });
  }

  Future<void> _deleteMemory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _memories.removeWhere((m) => m.id == id);
    await prefs.setString('memories', jsonEncode(_memories.map((m) => m.toJson()).toList()));
    setState(() {});
  }

  List<Memory> get _filtered => _selectedCategory == 'すべて'
      ? _memories
      : _memories.where((m) => m.category == _selectedCategory).toList();

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'おでかけ': return const Color(0xFF4A90D9);
      case 'イベント': return const Color(0xFFFF9500);
      case '季節': return const Color(0xFF9C27B0);
      case '日常': return const Color(0xFF4CAF50);
      default: return const Color(0xFF888888);
    }
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'おでかけ': return '🚗';
      case 'イベント': return '🎉';
      case '季節': return '🌸';
      case '日常': return '🐾';
      default: return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(),
            _buildCategories(),
            Expanded(child: _filtered.isEmpty ? _buildEmpty() : _buildGrid()),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Spacer(),
          const Text('🐾 思い出', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D5DA6))),
          const Spacer(),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4A90D9), width: 2)),
            child: const Icon(Icons.pets, color: Color(0xFF4A90D9)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(Icons.photo, '総写真数', '${_memories.fold(0, (s, m) => s + m.photos.length)}枚', '今までの思い出')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.calendar_month, '総記録数', '${_memories.length}件', 'お散歩・記録')),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: const Color(0xFF4A90D9), size: 18),
              ),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((cat) {
            final selected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF4A90D9) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
                ),
                child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF555555))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🐾', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('まだ思い出がありません', style: TextStyle(fontSize: 16, color: Color(0xFF888888))),
          SizedBox(height: 8),
          Text('下の「思い出を作る」から\n最初の記録を残してみましょう！',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final items = _filtered;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(Memory memory) {
    final color = _categoryColor(memory.category);
    final emoji = _categoryEmoji(memory.category);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => MemoryDetailScreen(memory: memory, onDelete: _deleteMemory, onUpdate: _loadMemories),
        ));
        _loadMemories();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                      child: Text(memory.category, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => _showOptions(memory),
                      child: Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF888888)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(memory.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(memory.memoryDate, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                      if (memory.walkMinutes > 0) ...[
                        const Spacer(),
                        Text('${memory.walkMinutes}分', style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                      ],
                    ],
                  ),
                  if (memory.memo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(memory.memo, style: const TextStyle(fontSize: 10, color: Color(0xFF666666)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(Memory memory) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF4A90D9)),
              title: const Text('編集'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MemoryCreateScreen(existing: memory),
                ));
                _loadMemories();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('削除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(memory);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Memory memory) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${memory.title}」を削除します。この操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteMemory(memory.id); },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryCreateScreen()));
        _loadMemories();
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4A90D9).withValues(alpha: 0.3), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: const Row(
          children: [
            Icon(Icons.add, color: Color(0xFF4A90D9), size: 24),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('思い出を作る', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9))),
                Text('記録をまとめてアルバムを作ろう', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
