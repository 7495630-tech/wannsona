import 'package:flutter/material.dart';
import 'breed_data.dart';

class BreedSelectScreen extends StatefulWidget {
  final Breed? initialBreed;
  const BreedSelectScreen({super.key, this.initialBreed});

  @override
  State<BreedSelectScreen> createState() => _BreedSelectScreenState();
}

class _BreedSelectScreenState extends State<BreedSelectScreen> {
  final _searchController = TextEditingController();
  List<Breed> _filtered = allBreeds;
  Breed? _selected;
  String _tab = 'all';

  @override
  void initState() {
    super.initState();
    _selected = widget.initialBreed;
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = searchBreeds(q);
      _tab = 'all';
    });
  }

  List<Breed> _getFiltered() {
    if (_tab == 'all') return _filtered;
    if (_tab == 'popular') {
      const ids = ['toy_poodle_id', 'chihuahua', 'shiba', 'french_bulldog',
        'golden_retriever', 'labrador_retriever', 'pomeranian',
        'dachshund_miniature', 'yorkshire_terrier', 'maltese'];
      return allBreeds.where((b) => ids.contains(b.id)).toList();
    }
    return _filtered.where((b) => b.jkcGroup == _tab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _getFiltered();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        title: const Text('犬種を選んでください',
            style: TextStyle(color: Color(0xFF4A90D9),
                fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: '犬種名・読みがな・英名で検索',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90D9)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('all', '全犬種'),
                _chip('popular', '人気'),
                _chip('1G', '牧羊犬'),
                _chip('2G', '使役犬'),
                _chip('3G', 'テリア'),
                _chip('4G', 'ダックス'),
                _chip('5G', 'スピッツ'),
                _chip('6G', '嗅覚猟犬'),
                _chip('7G', 'ポインター'),
                _chip('8G', '鳥猟犬'),
                _chip('9G', '愛玩犬'),
                _chip('10G', '視覚猟犬'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length + 2,
              itemBuilder: (ctx, i) {
                if (i == 0) return _mixedCard();
                if (i == 1) return _unknownCard();
                final b = list[i - 2];
                return _breedCard(b);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selected != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('${_selected!.jaName}にする',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _chip(String tab, String label) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _tab = tab),
        selectedColor: const Color(0xFF4A90D9),
        labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87, fontSize: 12),
      ),
    );
  }

  Widget _breedCard(Breed b) {
    final selected = _selected?.id == b.id;
    return GestureDetector(
      onTap: () => setState(() => _selected = b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? const Color(0xFF4A90D9)
                  : Colors.transparent,
              width: 2),
        ),
        child: Row(
          children: [
            const Text('🐶', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.jaName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(b.enName,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      _tag(b.sizeDefault),
                      _tag(b.coatLength),
                      if (b.risk.shortNose) _tag('短頭種⚠️'),
                      if (b.risk.heatRisk >= 4) _tag('暑さ注意🌡️'),
                      if (b.risk.jointRisk >= 4) _tag('関節注意'),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF4A90D9)),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  Future<void> _selectMixed() async {
    Breed? first;
    Breed? second;

    // 親犬種1を選ぶ
    first = await showDialog<Breed>(
      context: context,
      builder: (ctx) => _MixBreedPickerDialog(title: '親犬種①を選んでください'),
    );
    if (first == null || !mounted) return;

    // 親犬種2を選ぶ
    second = await showDialog<Breed>(
      context: context,
      builder: (ctx) => _MixBreedPickerDialog(title: '親犬種②を選んでください'),
    );
    if (second == null || !mounted) return;

    // ミックス犬としてBreedを生成して返す
    final mixBreed = Breed(
      id: 'mix_${first.id}_${second.id}',
      jaName: '${first.jaName}×${second.jaName}',
      enName: '${first.enName} × ${second.enName}',
      kana: 'ミックス',
      aliases: ['${first.jaName}×${second.jaName}'],
      sizeDefault: first.sizeDefault,
      coatType: first.coatType,
      coatLength: first.coatLength,
      jkcGroup: 'mix',
      risk: BreedRisk(
        heatRisk: ((first.risk.heatRisk + second.risk.heatRisk) / 2).round(),
        coldRisk: ((first.risk.coldRisk + second.risk.coldRisk) / 2).round(),
        jointRisk: ((first.risk.jointRisk + second.risk.jointRisk) / 2).round(),
        shortNose: first.risk.shortNose || second.risk.shortNose,
      ),
    );
    if (mounted) Navigator.pop(context, mixBreed);
  }

  Widget _mixedCard() {
    return GestureDetector(
      onTap: _selectMixed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB347), width: 1.5),
        ),
        child: const Row(
          children: [
            Text('🐕', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ミックス犬を登録する',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('2種類の親犬種からリスクを合成します',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _unknownCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, {'name': '不明（体格でリスク判断）', 'id': 'unknown'});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Text('🐾', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('犬種がわからない / 不明',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('体の特徴から安全指数を作れます',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MixBreedPickerDialog extends StatefulWidget {
  final String title;
  const _MixBreedPickerDialog({required this.title});
  @override
  State<_MixBreedPickerDialog> createState() => _MixBreedPickerDialogState();
}

class _MixBreedPickerDialogState extends State<_MixBreedPickerDialog> {
  final _ctrl = TextEditingController();
  List<Breed> _list = allBreeds;
  Breed? _selected;

  void _onSearch(String q) {
    setState(() => _list = searchBreeds(q));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: '犬種名で検索',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _list.length,
              itemBuilder: (ctx, i) {
                final b = _list[i];
                final sel = _selected?.id == b.id;
                return GestureDetector(
                  onTap: () => setState(() => _selected = b),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFE8F4FD) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? const Color(0xFF4A90D9) : Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      const Text('🐶', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(b.jaName,
                          style: const TextStyle(fontSize: 13))),
                      if (sel) const Icon(Icons.check_circle,
                          color: Color(0xFF4A90D9), size: 18),
                    ]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    foregroundColor: Colors.white),
                child: const Text('選択'),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}
