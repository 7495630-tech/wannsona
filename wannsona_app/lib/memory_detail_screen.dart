import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'memories_screen.dart';
import 'memory_create_screen.dart';

class MemoryDetailScreen extends StatelessWidget {
  final Memory memory;
  final Function(String) onDelete;
  final VoidCallback onUpdate;

  const MemoryDetailScreen({
    super.key,
    required this.memory,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5DA6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('思い出', style: TextStyle(color: Color(0xFF2D5DA6), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4A90D9)),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => MemoryCreateScreen(existing: memory),
              ));
              onUpdate();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoArea(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            if (memory.memo.isNotEmpty) _buildMemoCard(),
            if (memory.walkMinutes > 0) ...[
              const SizedBox(height: 16),
              _buildWalkCard(),
            ],
            if (memory.weatherName.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWeatherCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoArea() {
    if (memory.photos.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🐾', style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text('写真なし', style: TextStyle(color: Color(0xFF888888))),
            ],
          ),
        ),
      );
    }
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: Text('📷', style: TextStyle(fontSize: 48))),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90D9).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(memory.category, style: const TextStyle(fontSize: 12, color: Color(0xFF4A90D9), fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(memory.memoryDate, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
            ],
          ),
          const SizedBox(height: 12),
          Text(memory.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  Widget _buildMemoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, color: Color(0xFF4A90D9), size: 18),
              SizedBox(width: 8),
              Text('メモ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 12),
          Text(memory.memo, style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildWalkCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_walk, color: Color(0xFF4A90D9), size: 18),
              SizedBox(width: 8),
              Text('お散歩記録', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildWalkStat('⏱️', '散歩時間', '${memory.walkMinutes}分'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalkStat(String emoji, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny, color: Color(0xFFFFAA00), size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(memory.weatherName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('${memory.temperature.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${memory.title}」を削除します。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(memory.id);
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
