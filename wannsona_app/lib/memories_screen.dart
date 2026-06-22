import 'package:flutter/material.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  String _selectedCategory = 'すべて';

  final List<String> _categories = ['すべて', 'おでかけ', 'イベント', '季節', '日常'];

  final List<Map<String, dynamic>> _memories = [
    {'title': 'お花見散歩', 'emoji': '🌸', 'date': '2026/04/05', 'photos': 32, 'memo': '満開の桜の下をお散歩したよ🌸', 'category': 'おでかけ', 'color': const Color(0xFFFF6B9D)},
    {'title': '川遊び', 'emoji': '🏊', 'date': '2026/05/03', 'photos': 18, 'memo': '冷たくて気持ちよかったね〜🐾', 'category': 'おでかけ', 'color': const Color(0xFF4A90D9)},
    {'title': '4歳のお誕生日', 'emoji': '🎂', 'date': '2026/05/06', 'photos': 48, 'memo': 'そなの4歳のお誕生日をお祝いしたよ🎂', 'category': 'イベント', 'color': const Color(0xFFFF9500)},
    {'title': 'ドッグラン', 'emoji': '🐾', 'date': '2026/05/10', 'photos': 85, 'memo': 'お友達といっぱい走ったね！🐕', 'category': '日常', 'color': const Color(0xFF4CAF50)},
    {'title': 'クリスマス', 'emoji': '🎄', 'date': '2025/12/24', 'photos': 26, 'memo': 'サンタさんが来てくれたよ🎅', 'category': 'イベント', 'color': const Color(0xFF9C27B0)},
    {'title': '海辺の夕日散歩', 'emoji': '🌅', 'date': '2025/11/15', 'photos': 21, 'memo': '夕日がきれいだったね〜🌅', 'category': 'おでかけ', 'color': const Color(0xFFFF6B9D)},
  ];

  List<Map<String, dynamic>> get _filtered => _selectedCategory == 'すべて'
      ? _memories
      : _memories.where((m) => m['category'] == _selectedCategory).toList();

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
            Expanded(child: _buildGrid()),
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
          Expanded(child: _buildStatCard(Icons.photo, '総写真数', '1,248枚', '今までの思い出')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.calendar_month, '総記録数', '382件', 'お散歩・記録')),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
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
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
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
      child: Row(
        children: [
          Expanded(
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                      ),
                      child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF555555))),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]),
            child: const Row(children: [Icon(Icons.swap_vert, size: 14, color: Color(0xFF555555)), SizedBox(width: 4), Text('並び替え', style: TextStyle(fontSize: 12, color: Color(0xFF555555)))]),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final items = _filtered;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(Map<String, dynamic> memory) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
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
                    color: (memory['color'] as Color).withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(child: Text(memory['emoji'], style: const TextStyle(fontSize: 48))),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: memory['color'], borderRadius: BorderRadius.circular(10)),
                    child: Text(memory['category'], style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF888888)),
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
                Text(memory['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(memory['date'], style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                    const Spacer(),
                    const Icon(Icons.photo, size: 10, color: Color(0xFF999999)),
                    const SizedBox(width: 2),
                    Text('${memory['photos']}枚', style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(memory['memo'], style: const TextStyle(fontSize: 10, color: Color(0xFF666666)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
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
    );
  }
}
