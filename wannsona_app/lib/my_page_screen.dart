import 'package:flutter/material.dart';
import 'dog_profile_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildProfileCard(context),
              const SizedBox(height: 12),
              _buildQuickAccess(context),
              const SizedBox(height: 12),
              _buildSettings(context),
              const SizedBox(height: 12),
              _buildPremiumBanner(),
              const SizedBox(height: 24),
            ],
          ),
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
          const Text(
            '🐾 マイページ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D5DA6)),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2D5DA6)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined, color: Color(0xFF2D5DA6)), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE8F0FE),
                        border: Border.all(color: const Color(0xFF4A90D9), width: 2),
                      ),
                      child: const Icon(Icons.pets, size: 40, color: Color(0xFF4A90D9)),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4A90D9)),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('そな', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DogProfileScreen())),
                            child: const Icon(Icons.edit, size: 18, color: Color(0xFF4A90D9)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('ゴールデンレトリバー', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
                      const Text('3歳2ヶ月（2023/03/05生まれ）', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat('🐾', '総散歩回数', '382回'),
                _buildDivider(),
                _buildStat('📍', '総距離', '1,248km'),
                _buildDivider(),
                _buildStat('🖼️', '写真の総数', '1,248枚'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: const Color(0xFFE0E0E0));
  }

  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      {'icon': Icons.directions_walk, 'label': '散歩記録', 'color': const Color(0xFF4A90D9)},
      {'icon': Icons.photo_album, 'label': '思い出', 'color': const Color(0xFFE91E8C)},
      {'icon': Icons.location_on, 'label': '行けるとこ\nマップ', 'color': const Color(0xFF4CAF50)},
      {'icon': Icons.brush, 'label': 'AIイラスト', 'color': const Color(0xFF9C27B0)},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: Color(0xFF4A90D9), size: 18),
                SizedBox(width: 8),
                Text('よく使う', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: items.map((item) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            item['label'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF444444)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final items = [
      {'icon': Icons.pets, 'color': const Color(0xFF4A90D9), 'title': 'プロフィール設定', 'subtitle': ''},
      {'icon': Icons.favorite, 'color': const Color(0xFFE91E8C), 'title': '健康・体調の記録', 'subtitle': ''},
      {'icon': Icons.medical_services, 'color': const Color(0xFF4CAF50), 'title': '病院・ワクチンの記録', 'subtitle': ''},
      {'icon': Icons.settings, 'color': const Color(0xFF888888), 'title': 'その他の設定', 'subtitle': 'バックアップ・家族共有・通知など'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('各種設定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            ...items.map((item) {
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                    ),
                    title: Text(item['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: (item['subtitle'] as String).isNotEmpty
                        ? Text(item['subtitle'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF999999)))
                        : null,
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
                    onTap: () {},
                  ),
                  if (item != items.last) const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCC44), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('👑', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('わんソナ プレミアム+', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF8B6914))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('思い出をもっと素敵に残そう', style: TextStyle(fontSize: 12, color: Color(0xFF8B6914))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: ['AI思い出提案', 'AIタイトル生成', 'AIアルバム文章生成', 'PDFアルバム化', '広告非表示', '家族共有（無制限）']
                        .map((f) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 14),
                                const SizedBox(width: 2),
                                Text(f, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
                              ],
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFAA00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('詳細を見る >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
