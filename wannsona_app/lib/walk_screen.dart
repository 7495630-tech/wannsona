import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ══════════════════════════════════════════
// お散歩ログのデータモデル
// ══════════════════════════════════════════
class WalkLog {
  final String id;
  final String startTime;
  final String endTime;
  final int durationSeconds;
  final double distanceKm;
  final String dogMood;
  final List<String> completedTags;
  final String memo;

  WalkLog({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.dogMood,
    required this.completedTags,
    required this.memo,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime,
    'endTime': endTime,
    'durationSeconds': durationSeconds,
    'distanceKm': distanceKm,
    'dogMood': dogMood,
    'completedTags': completedTags,
    'memo': memo,
  };

  factory WalkLog.fromJson(Map<String, dynamic> j) => WalkLog(
    id: j['id'] ?? '',
    startTime: j['startTime'] ?? '',
    endTime: j['endTime'] ?? '',
    durationSeconds: j['durationSeconds'] ?? 0,
    distanceKm: (j['distanceKm'] ?? 0).toDouble(),
    dogMood: j['dogMood'] ?? '',
    completedTags: List<String>.from(j['completedTags'] ?? []),
    memo: j['memo'] ?? '',
  );
}

class WalkStorage {
  static Future<List<WalkLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('walk_logs') ?? [];
    return raw.map((s) => WalkLog.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> saveLog(WalkLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('walk_logs') ?? [];
    raw.insert(0, jsonEncode(log.toJson()));
    await prefs.setStringList('walk_logs', raw);
  }
}

const Color kPrimary = Color(0xFF2B7FE0);
const Color kSecondary = Color(0xFF59D4E8);
const Color kBg = Color(0xFFF0F8FF);
const Color kNavy = Color(0xFF2F3A45);
const Color kSubText = Color(0xFF8AA0B0);
const Color kAccent = Color(0xFFFFA94D);
const Color kGreen = Color(0xFF7AB899);

// ══════════════════════════════════════════
// お散歩トップ画面
// ══════════════════════════════════════════
class WalkTopScreen extends StatefulWidget {
  const WalkTopScreen({super.key});
  @override
  State<WalkTopScreen> createState() => _WalkTopScreenState();
}

class _WalkTopScreenState extends State<WalkTopScreen> {
  List<WalkLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await WalkStorage.loadLogs();
    if (mounted) setState(() { _logs = logs; _loading = false; });
  }

  // 今週の集計
  double get _weekDistance {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    double total = 0;
    for (final log in _logs) {
      final t = DateTime.tryParse(log.startTime);
      if (t != null && t.isAfter(weekAgo)) total += log.distanceKm;
    }
    return total;
  }

  int get _weekSeconds {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    int total = 0;
    for (final log in _logs) {
      final t = DateTime.tryParse(log.startTime);
      if (t != null && t.isAfter(weekAgo)) total += log.durationSeconds;
    }
    return total;
  }

  int get _weekCount {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _logs.where((log) {
      final t = DateTime.tryParse(log.startTime);
      return t != null && t.isAfter(weekAgo);
    }).length;
  }

  String _moodLabel(String mood) {
    switch (mood) {
      case 'happy': return 'ごきげん';
      case 'fun': return 'たのしそう';
      case 'normal': return 'ふつう';
      case 'tired': return 'つかれた';
      case 'sleepy': return 'ねむそう';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));
    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
        // ヘッダー
        Row(children: [
          const Text('お散歩', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(width: 6),
          const Icon(Icons.pets, color: kPrimary, size: 24),
        ]),
        const SizedBox(height: 16),
        // 今週のわんソナカード
        _buildSummaryCard(),
        const SizedBox(height: 12),
        // 最近のお散歩
        _buildRecentCard(),
      ]),
      // お散歩を始めるボタン（下部固定）
      Positioned(
        left: 16, right: 16, bottom: 16,
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalkActiveScreen()));
              _load();
            },
            icon: const Icon(Icons.pets, color: Colors.white),
            label: const Text('お散歩を始める', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildSummaryCard() {
    final dist = _weekDistance;
    final hours = _weekSeconds ~/ 3600;
    final mins = (_weekSeconds % 3600) ~/ 60;
    final count = _weekCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.flag, color: kSecondary, size: 20),
          const SizedBox(width: 6),
          const Text('今週のわんソナ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kNavy)),
        ]),
        const SizedBox(height: 16),
        _statRow(Icons.place, '距離', '${dist.toStringAsFixed(1)} km', '目標 15km', dist / 15),
        const SizedBox(height: 14),
        _statRow(Icons.access_time, '時間', '$hours時間$mins分', '目標 5時間00分', _weekSeconds / 18000),
        const SizedBox(height: 14),
        _statRow(Icons.pets, '回数', '$count回', '目標 7回', count / 7),
      ]),
    );
  }

  Widget _statRow(IconData icon, String label, String value, String target, double ratio) {
    final pct = (ratio * 100).clamp(0, 100).toInt();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: kSecondary, size: 22),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kNavy)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: kSecondary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Text('$pct%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary)),
        ),
      ]),
      const SizedBox(height: 4),
      Text(target, style: const TextStyle(fontSize: 12, color: kSubText)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: ratio.clamp(0, 1),
          minHeight: 8,
          backgroundColor: const Color(0xFFEEF3F7),
          valueColor: const AlwaysStoppedAnimation(kSecondary),
        ),
      ),
    ]);
  }

  Widget _buildRecentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pets, color: kSecondary, size: 18),
          const SizedBox(width: 6),
          const Text('最近のお散歩', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
        ]),
        const SizedBox(height: 12),
        if (_logs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('まだお散歩の記録がありません\nさっそくお散歩を始めましょう♪', textAlign: TextAlign.center, style: TextStyle(color: kSubText, fontSize: 13))),
          )
        else
          ..._logs.take(3).map((log) => _recentRow(log)),
      ]),
    );
  }

  Widget _recentRow(WalkLog log) {
    final t = DateTime.tryParse(log.startTime);
    final dateStr = t != null ? '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}' : '';
    final mins = log.durationSeconds ~/ 60;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: const Color(0xFFE8F8FB), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.pets, color: kSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 4),
          Text('$mins分 ・ ${log.distanceKm.toStringAsFixed(1)}km', style: const TextStyle(fontSize: 12, color: kSubText)),
        ])),
        if (log.dogMood.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Text(_moodLabel(log.dogMood), style: const TextStyle(fontSize: 11, color: kGreen)),
          ),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// お散歩中画面
// ══════════════════════════════════════════
class WalkActiveScreen extends StatefulWidget {
  const WalkActiveScreen({super.key});
  @override
  State<WalkActiveScreen> createState() => _WalkActiveScreenState();
}

class _WalkActiveScreenState extends State<WalkActiveScreen> {
  Timer? _timer;
  int _seconds = 0;
  double _distanceKm = 0;
  bool _paused = false;
  bool _gpsReady = false;
  String _gpsMessage = 'GPSを準備中...';
  final DateTime _startTime = DateTime.now();
  Position? _lastPosition;
  StreamSubscription<Position>? _posSub;
  final List<LatLng> _route = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initGps();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused) setState(() => _seconds++);
    });
  }

  Future<void> _initGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _gpsMessage = '位置情報サービスをオンにしてください');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _gpsMessage = '位置情報の許可が必要です');
        return;
      }
      setState(() { _gpsReady = true; _gpsMessage = ''; });
      // 最初の現在地をすぐ取得
      try {
        final first = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final firstPoint = LatLng(first.latitude, first.longitude);
        _lastPosition = first;
        setState(() => _route.add(firstPoint));
        try { _mapController.move(firstPoint, 17); } catch (_) {}
      } catch (_) {}
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((pos) {
        if (_paused) { _lastPosition = pos; return; }
        final newPoint = LatLng(pos.latitude, pos.longitude);
        if (_lastPosition != null) {
          final d = Geolocator.distanceBetween(
            _lastPosition!.latitude, _lastPosition!.longitude,
            pos.latitude, pos.longitude,
          );
          // 位置の急なジャンプを無視（50m以上は異常値として除外）
          if (d < 50) {
            setState(() {
              _distanceKm += d / 1000;
              _route.add(newPoint);
            });
          }
        } else {
          setState(() => _route.add(newPoint));
        }
        _lastPosition = pos;
        try { _mapController.move(newPoint, _mapController.camera.zoom); } catch (_) {}
      });
    } catch (e) {
      setState(() => _gpsMessage = 'GPSエラー: $e');
    }
  }

  String get _timeStr {
    final h = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _confirmEnd() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('お散歩を終了しますか？'),
        content: const Text('記録を保存して終了画面に進みます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('つづける')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('終了する')),
        ],
      ),
    );
    if (ok == true && mounted) {
      _timer?.cancel();
      _posSub?.cancel();
      final result = await Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => WalkFinishScreen(
          startTime: _startTime,
          endTime: DateTime.now(),
          seconds: _seconds,
          distanceKm: _distanceKm,
        ),
      ));
      if (mounted) Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kPrimary,
        title: const Text('お散歩中', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
        centerTitle: true,
      ),
      body: Column(children: [
        Text('$startStr 開始', style: const TextStyle(fontSize: 14, color: kSubText)),
        const SizedBox(height: 16),
        // 計測カード
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _metric(Icons.access_time, '経過時間', _timeStr),
            _metric(Icons.place, '距離', '${_distanceKm.toStringAsFixed(2)} km'),
          ]),
        ),
        const SizedBox(height: 16),
        // GPS状態
        if (!_gpsReady && _gpsMessage.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.gps_off, color: kAccent),
              const SizedBox(width: 12),
              Expanded(child: Text(_gpsMessage, style: const TextStyle(color: kNavy, fontSize: 13))),
            ]),
          ),
        const SizedBox(height: 12),
        // 地図
        Expanded(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: _route.isEmpty
            ? Container(
                color: const Color(0xFFE8F4FC),
                child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.gps_fixed, color: kSecondary, size: 32),
                  SizedBox(height: 8),
                  Text('現在地を取得中...', style: TextStyle(color: kSubText)),
                ])),
              )
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _route.last,
                  initialZoom: 17,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'app.wansona',
                  ),
                  PolylineLayer(polylines: [
                    Polyline(points: _route, strokeWidth: 5, color: kPrimary),
                  ]),
                  MarkerLayer(markers: [
                    if (_route.isNotEmpty)
                      Marker(point: _route.first, width: 30, height: 30, child: const Icon(Icons.flag, color: kPrimary)),
                    if (_route.isNotEmpty)
                      Marker(point: _route.last, width: 36, height: 36, child: const Icon(Icons.place, color: kAccent, size: 36)),
                  ]),
                ],
              ),
        )),
        const SizedBox(height: 8),
        // 下部ボタン
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _paused = !_paused),
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause, color: kPrimary),
                label: Text(_paused ? '再開' : '一時停止', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kPrimary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _confirmEnd,
                icon: const Icon(Icons.flag, color: Colors.white),
                label: const Text('お散歩終了', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Column(children: [
      Icon(icon, color: kSecondary, size: 28),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: kSubText)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kNavy)),
    ]);
  }
}

// ══════════════════════════════════════════
// お散歩終了画面
// ══════════════════════════════════════════
class WalkFinishScreen extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final int seconds;
  final double distanceKm;
  const WalkFinishScreen({super.key, required this.startTime, required this.endTime, required this.seconds, required this.distanceKm});
  @override
  State<WalkFinishScreen> createState() => _WalkFinishScreenState();
}

class _WalkFinishScreenState extends State<WalkFinishScreen> {
  String _mood = '';
  final Set<String> _tags = {};
  final TextEditingController _memoCtrl = TextEditingController();
  bool _saving = false;
  double _dogWeight = 0;
  int _dogAgeYears = 0;

  @override
  void initState() {
    super.initState();
    _loadDogInfo();
  }

  Future<void> _loadDogInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final w = double.tryParse(prefs.getString('dog_weight') ?? '0') ?? 0;
    int age = 0;
    final birth = prefs.getString('dog_birth');
    if (birth != null) {
      final b = DateTime.tryParse(birth);
      if (b != null) {
        age = DateTime.now().difference(b).inDays ~/ 365;
      }
    }
    if (mounted) setState(() { _dogWeight = w; _dogAgeYears = age; });
  }

  final List<(String, String)> _moods = [
    ('happy', 'ごきげん'),
    ('fun', 'たのしそう'),
    ('normal', 'ふつう'),
    ('tired', 'つかれた'),
    ('sleepy', 'ねむそう'),
  ];

  final List<(String, String)> _tagOptions = [
    ('poop', 'うんち出た'),
    ('drankWater', 'お水飲んだ'),
    ('played', '遊んだ'),
    ('metFriend', 'お友達に会えた'),
    ('other', 'その他'),
  ];

  String get _durationStr {
    final m = (widget.seconds ~/ 60).toString().padLeft(2, '0');
    final s = (widget.seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get _calories {
    // わんソナ独自の目安計算（学術的根拠に基づくものではありません）
    // 基本: 体重(kg) × 距離(km) × 係数0.8
    double weight = _dogWeight > 0 ? _dogWeight : 5; // 未設定時は仮に5kg
    double base = weight * widget.distanceKm * 0.8;
    // 年齢補正: シニア(7歳以上)は代謝が落ちる
    double ageFactor = _dogAgeYears >= 7 ? 0.9 : 1.0;
    // 体型補正: 大型犬はやや効率的、小型犬はやや多め
    double sizeFactor;
    if (weight >= 25) {
      sizeFactor = 0.95;
    } else if (weight >= 10) {
      sizeFactor = 1.0;
    } else {
      sizeFactor = 1.05;
    }
    return (base * ageFactor * sizeFactor).round();
  }

  void _showCalorieInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('推定消費カロリーについて'),
        content: const Text(
          'この数値は、体重・距離・年齢・体型をもとにした「目安」です。\n\n'
          '医学的・学術的に正確な消費カロリーではなく、毎日のお散歩の参考にしていただくためのものです。\n\n'
          '気になることがある場合は、かかりつけの獣医師さんにご相談ください。',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final log = WalkLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: widget.startTime.toIso8601String(),
      endTime: widget.endTime.toIso8601String(),
      durationSeconds: widget.seconds,
      distanceKm: widget.distanceKm,
      dogMood: _mood,
      completedTags: _tags.toList(),
      memo: _memoCtrl.text,
    );
    await WalkStorage.saveLog(log);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.startTime;
    final e = widget.endTime;
    final timeRange = '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')} 〜 ${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kPrimary,
        title: const Text('お散歩終了', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
        centerTitle: true,
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), children: [
        Center(child: Text(timeRange, style: const TextStyle(fontSize: 14, color: kSubText))),
        const SizedBox(height: 16),
        const Text('おつかれさまでした！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 4),
        const Text('楽しいお散歩になりましたね♪\n今日の思い出を記録しましょう', style: TextStyle(fontSize: 14, color: kSubText)),
        const SizedBox(height: 16),
        // 結果サマリー
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _summary(Icons.access_time, 'お散歩時間', _durationStr),
            _summary(Icons.place, '距離', '${widget.distanceKm.toStringAsFixed(2)} km'),
            _summary(Icons.local_fire_department, '推定カロリー', '$_calories kcal'),
          ]),
        ),
        const SizedBox(height: 20),
        // 今日のうちの子の様子
        const Text('今日のうちの子の様子', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _moods.map((m) {
          final selected = _mood == m.$1;
          return GestureDetector(
            onTap: () => setState(() => _mood = m.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? kPrimary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? kPrimary : const Color(0xFFE0E8EF), width: selected ? 2 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (selected) const Icon(Icons.check_circle, color: kPrimary, size: 16),
                if (selected) const SizedBox(width: 4),
                Text(m.$2, style: TextStyle(fontSize: 13, color: selected ? kPrimary : kNavy, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              ]),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),
        // 今日のできたこと
        const Text('今日のできたこと（任意）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _tagOptions.map((t) {
          final selected = _tags.contains(t.$1);
          return GestureDetector(
            onTap: () => setState(() => selected ? _tags.remove(t.$1) : _tags.add(t.$1)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? kSecondary.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? kSecondary : const Color(0xFFE0E8EF), width: selected ? 2 : 1),
              ),
              child: Text(t.$2, style: TextStyle(fontSize: 13, color: selected ? kPrimary : kNavy)),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),
        // メモ
        TextField(
          controller: _memoCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'メモを入力（任意）',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: GestureDetector(
          onTap: _showCalorieInfo,
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.info_outline, size: 16, color: kSubText),
            SizedBox(width: 4),
            Text('推定消費カロリーについて', style: TextStyle(fontSize: 13, color: kSubText, decoration: TextDecoration.underline)),
          ]),
        )),
      ]),
      bottomSheet: Container(
        color: kBg,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.menu_book, color: Colors.white),
            label: const Text('思い出に保存する', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(IconData icon, String label, String value) {
    return Expanded(child: Column(children: [
      Icon(icon, color: kSecondary, size: 24),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: kSubText), textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy), textAlign: TextAlign.center),
    ]));
  }
}
