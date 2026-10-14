import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DietDb.instance.database;
  runApp(const HealthDietApp());
}

class HealthDietApp extends StatelessWidget {
  const HealthDietApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF237A57);
    return MaterialApp(
      title: '健康饮食助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF5F7F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F4),
          foregroundColor: Color(0xFF173D2D),
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class Food {
  final int? id;
  final String name;
  final String category;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const Food(this.id, this.name, this.category, this.kcal, this.protein,
      this.carbs, this.fat);

  Map<String, Object?> toMap() => {
    'name': name, 'category': category, 'kcal': kcal,
    'protein': protein, 'carbs': carbs, 'fat': fat,
  };

  factory Food.fromMap(Map<String, Object?> m) => Food(
    m['id'] as int?, m['name'] as String, m['category'] as String,
    (m['kcal'] as num).toDouble(), (m['protein'] as num).toDouble(),
    (m['carbs'] as num).toDouble(), (m['fat'] as num).toDouble(),
  );
}

class DietDb {
  DietDb._();
  static final DietDb instance = DietDb._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'health_diet_v15.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''CREATE TABLE foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        category TEXT NOT NULL, kcal REAL NOT NULL, protein REAL NOT NULL,
        carbs REAL NOT NULL, fat REAL NOT NULL)''');
      await db.execute('''CREATE TABLE meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT, food_id INTEGER,
        food_name TEXT NOT NULL, meal_type TEXT NOT NULL, grams REAL NOT NULL,
        kcal REAL NOT NULL, protein REAL NOT NULL, carbs REAL NOT NULL,
        fat REAL NOT NULL, created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE water_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT, ml INTEGER NOT NULL,
        created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE weight_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT, kg REAL NOT NULL,
        created_at TEXT NOT NULL)''');
      for (final f in seedFoods) {
        await db.insert('foods', f.toMap());
      }
    });
    return _db!;
  }

  Future<List<Food>> foods({String query = ''}) async {
    final db = await database;
    final rows = await db.query('foods',
      where: query.isEmpty ? null : 'name LIKE ? OR category LIKE ?',
      whereArgs: query.isEmpty ? null : ['%$query%', '%$query%'],
      orderBy: 'category, name');
    return rows.map(Food.fromMap).toList();
  }

  Future<void> addMeal(Food f, String type, double grams) async {
    final db = await database;
    final factor = grams / 100;
    await db.insert('meals', {
      'food_id': f.id, 'food_name': f.name, 'meal_type': type, 'grams': grams,
      'kcal': f.kcal * factor, 'protein': f.protein * factor,
      'carbs': f.carbs * factor, 'fat': f.fat * factor,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> todayMeals() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    return db.query('meals', where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start, end], orderBy: 'id DESC');
  }

  Future<void> addWater(int ml) async {
    final db = await database;
    await db.insert('water_records', {'ml': ml, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<int> todayWater() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final rows = await db.rawQuery('SELECT SUM(ml) AS total FROM water_records WHERE created_at >= ? AND created_at < ?', [start, end]);
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> addWeight(double kg) async {
    final db = await database;
    await db.insert('weight_records', {'kg': kg, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, Object?>>> weights() async {
    final db = await database;
    return db.query('weight_records', orderBy: 'id DESC', limit: 20);
  }
}

const seedFoods = <Food>[
  Food(null, '鸡胸肉', '肉类', 133, 24.6, 0, 1.9),
  Food(null, '鸡蛋', '蛋奶', 144, 13.3, 2.8, 8.8),
  Food(null, '纯牛奶', '蛋奶', 54, 3.0, 3.4, 3.2),
  Food(null, '米饭', '主食', 116, 2.6, 25.9, 0.3),
  Food(null, '燕麦片', '主食', 389, 16.9, 66.3, 6.9),
  Food(null, '全麦面包', '主食', 247, 13.0, 41.0, 4.2),
  Food(null, '西兰花', '蔬菜', 34, 2.8, 6.6, 0.4),
  Food(null, '菠菜', '蔬菜', 23, 2.9, 3.6, 0.4),
  Food(null, '番茄', '蔬菜', 18, 0.9, 3.9, 0.2),
  Food(null, '苹果', '水果', 52, 0.3, 13.8, 0.2),
  Food(null, '香蕉', '水果', 89, 1.1, 22.8, 0.3),
  Food(null, '三文鱼', '海鲜', 208, 20.4, 0, 13.4),
  Food(null, '豆腐', '豆制品', 84, 8.1, 4.2, 4.2),
  Food(null, '花生', '坚果', 567, 25.8, 16.1, 49.2),
  Food(null, '可乐', '饮品', 42, 0, 10.6, 0),
];

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int tab = 0;
  int refresh = 0;

  Future<void> reload() async {
    if (mounted) setState(() => refresh++);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(key: ValueKey('home$refresh'), onChanged: reload, onFoods: () => setState(() => tab = 1)),
      FoodTab(key: ValueKey('food$refresh'), onAdded: reload),
      ReportTab(key: ValueKey('report$refresh')),
      ProfileTab(key: ValueKey('profile$refresh'), onChanged: reload),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康饮食助手', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: '食物库'),
          NavigationDestination(icon: Icon(Icons.insights), label: '报告'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final VoidCallback onChanged;
  final VoidCallback onFoods;
  const HomeTab({super.key, required this.onChanged, required this.onFoods});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, Object?>> meals = [];
  int water = 0;
  bool loading = true;
  static const goal = 2000.0;
  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final m = await DietDb.instance.todayMeals();
    final w = await DietDb.instance.todayWater();
    if (!mounted) return;
    setState(() { meals = m; water = w; loading = false; });
  }

  double sum(String key) => meals.fold<double>(0, (s, m) => s + ((m[key] as num?)?.toDouble() ?? 0));
  String get greeting {
    final h = DateTime.now().hour;
    if (h < 11) return '早上好，今天也要好好吃饭';
    if (h < 14) return '中午好，记得均衡搭配';
    if (h < 18) return '下午好，别忘了补充水分';
    return '晚上好，看看今天的饮食吧';
  }

  @override
  Widget build(BuildContext context) {
    final kcal = sum('kcal');
    final protein = sum('protein');
    final carbs = sum('carbs');
    final fat = sum('fat');
    return loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(greeting, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日热量摄入', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(kcal.toStringAsFixed(0), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF237A57))),
              const SizedBox(width: 8),
              const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('/ 2000 kcal')),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: (kcal / goal).clamp(0, 1), minHeight: 9, backgroundColor: const Color(0xFFE4EEE7))),
            const SizedBox(height: 8),
            Text(kcal > goal ? '已超过示例目标 ${(kcal-goal).toStringAsFixed(0)} kcal' : '距离示例目标还差 ${(goal-kcal).toStringAsFixed(0)} kcal', style: const TextStyle(color: Colors.black54)),
          ],
        ))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _metric('蛋白质', '${protein.toStringAsFixed(1)} g', Icons.fitness_center, const Color(0xFF3478C8))),
          const SizedBox(width: 10),
          Expanded(child: _metric('碳水', '${carbs.toStringAsFixed(1)} g', Icons.grain, const Color(0xFFE59A32))),
          const SizedBox(width: 10),
          Expanded(child: _metric('脂肪', '${fat.toStringAsFixed(1)} g', Icons.opacity, const Color(0xFF9867C5))),
        ]),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.water_drop, color: Colors.blue), const SizedBox(width: 8), const Text('今日饮水', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text('$water / 2000 ml')]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [250, 350, 500].map((ml) => OutlinedButton(
              onPressed: () async { await DietDb.instance.addWater(ml); await load(); widget.onChanged(); },
              child: Text('+$ml ml'),
            )).toList()),
          ],
        ))),
        const SizedBox(height: 12),
        Row(children: [
          const Text('今日饮食', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(onPressed: widget.onFoods, icon: const Icon(Icons.add), label: const Text('添加食物')),
        ]),
        const SizedBox(height: 6),
        if (meals.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('还没有记录，点击“添加食物”开始记录')))),
        ...meals.map((m) => Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: const Color(0xFFE4F1E8), child: const Icon(Icons.restaurant, color: Color(0xFF237A57))),
          title: Text('${m['food_name']} · ${m['grams']}g'),
          subtitle: Text('${m['meal_type']} · 蛋白质 ${((m['protein'] as num).toDouble()).toStringAsFixed(1)}g'),
          trailing: Text('${((m['kcal'] as num).toDouble()).toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
        ))),
        const SizedBox(height: 12),
        Card(child: const Padding(padding: EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFFE59A32)), SizedBox(width: 10),
          Expanded(child: Text('饮食小提示：尽量搭配蔬菜、水果、全谷物和优质蛋白。热量与营养数据为估算值，实际会因品牌和烹饪方式不同而变化。')),
        ]))),
      ],
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) => Card(
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10), child: Column(
      children: [Icon(icon, color: color), const SizedBox(height: 8), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12))],
    )),
  );
}

class FoodTab extends StatefulWidget {
  final VoidCallback onAdded;
  const FoodTab({super.key, required this.onAdded});
  @override
  State<FoodTab> createState() => _FoodTabState();
}

class _FoodTabState extends State<FoodTab> {
  String query = '';
  String category = '全部';
  final searchController = TextEditingController();
  final categories = const ['全部','肉类','蛋奶','主食','蔬菜','水果','海鲜','豆制品','坚果','饮品'];

  Future<void> add(Food food) async {
    String type = '午餐';
    final gramsController = TextEditingController(text: '100');
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
        title: Text('记录 ${food.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('每100g约 ${food.kcal.toStringAsFixed(0)} kcal'),
          const SizedBox(height: 12),
          TextField(controller: gramsController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '食用重量（克）', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: '餐次'), items: const ['早餐','午餐','晚餐','加餐'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { if (v != null) setDialog(() => type = v); }),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () {
            final grams = double.tryParse(gramsController.text.trim());
            if (grams == null || grams <= 0 || grams > 5000) return;
            Navigator.pop(context, {'grams': grams, 'type': type});
          }, child: const Text('加入记录')),
        ],
      )),
    );
    if (result != null) {
      await DietDb.instance.addMeal(food, result['type'] as String, result['grams'] as double);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已记录 ${food.name}')));
      widget.onAdded();
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: TextField(
      controller: searchController,
      decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: '搜索食物或分类', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); setState(() => query = ''); })),
      onChanged: (v) => setState(() => query = v.trim()),
    )),
    SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: categories.map((c) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(c), selected: category == c, onSelected: (_) => setState(() => category = c)))).toList())),
    Expanded(child: FutureBuilder<List<Food>>(
      future: DietDb.instance.foods(query: query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final foods = snapshot.data!.where((f) => category == '全部' || f.category == category).toList();
        if (foods.isEmpty) return const Center(child: Text('没有找到食物'));
        return ListView.builder(padding: const EdgeInsets.all(12), itemCount: foods.length, itemBuilder: (context, i) {
          final f = foods[i];
          return Card(child: ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFFE4F1E8), child: Text(f.name.characters.first, style: const TextStyle(color: Color(0xFF237A57), fontWeight: FontWeight.bold))),
            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${f.category} · 每100g：蛋白质 ${f.protein}g / 碳水 ${f.carbs}g / 脂肪 ${f.fat}g'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${f.kcal.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold)), const Text('/100g', style: TextStyle(fontSize: 11, color: Colors.black54))]),
            onTap: () => add(f),
          ));
        });
      },
    )),
  ]);
}

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});
  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  List<Map<String, Object?>> meals = [];
  List<Map<String, Object?>> weights = [];
  int water = 0;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    final m = await DietDb.instance.todayMeals();
    final w = await DietDb.instance.todayWater();
    final wt = await DietDb.instance.weights();
    if (mounted) setState(() { meals = m; water = w; weights = wt; });
  }
  double sum(String key) => meals.fold<double>(0, (s,m) => s + ((m[key] as num?)?.toDouble() ?? 0));
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('今日营养报告', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 12),
    _reportCard('总热量', '${sum('kcal').toStringAsFixed(0)} kcal', Icons.local_fire_department, '示例参考目标：2000 kcal'),
    _reportCard('蛋白质', '${sum('protein').toStringAsFixed(1)} g', Icons.fitness_center, '包含今日已记录食物'),
    _reportCard('碳水化合物', '${sum('carbs').toStringAsFixed(1)} g', Icons.grain, '营养值为估算值'),
    _reportCard('脂肪', '${sum('fat').toStringAsFixed(1)} g', Icons.opacity, '建议结合个人目标评估'),
    _reportCard('饮水', '$water ml', Icons.water_drop, '记录的饮水总量'),
    const SizedBox(height: 8),
    const Text('近期体重记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    if (weights.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('还没有体重记录。可以在“我的”页面添加。'))),
    ...weights.map((w) => Card(child: ListTile(leading: const Icon(Icons.monitor_weight_outlined), title: Text('${w['kg']} kg'), subtitle: Text((w['created_at'] as String).replaceFirst('T',' ').split('.').first)))),
  ]);
  Widget _reportCard(String title, String value, IconData icon, String note) => Card(child: ListTile(
    leading: CircleAvatar(backgroundColor: const Color(0xFFE4F1E8), child: Icon(icon, color: const Color(0xFF237A57))),
    title: Text(title), subtitle: Text(note), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  ));
}

class ProfileTab extends StatefulWidget {
  final VoidCallback onChanged;
  const ProfileTab({super.key, required this.onChanged});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final weightController = TextEditingController();
  List<Map<String, Object?>> weights = [];
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    final list = await DietDb.instance.weights();
    if (mounted) setState(() => weights = list);
  }
  Future<void> addWeight() async {
    final kg = double.tryParse(weightController.text.trim());
    if (kg == null || kg < 20 || kg > 400) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入20至400之间的有效体重（kg）')));
      return;
    }
    await DietDb.instance.addWeight(kg);
    weightController.clear();
    await load();
    widget.onChanged();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('体重已保存到本机')));
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Card(child: Padding(padding: EdgeInsets.all(20), child: Row(children: [
      CircleAvatar(radius: 28, child: Icon(Icons.person, size: 32)),
      SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('我的健康档案', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('数据保存在当前手机本地数据库')]))
    ]))),
    const SizedBox(height: 12),
    const Text('记录体重', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '当前体重（kg）', hintText: '例如 65.5', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: addWeight, icon: const Icon(Icons.save_outlined), label: const Text('保存体重记录'))),
    ]))),
    const SizedBox(height: 12),
    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('说明：本应用为离线记录工具，热量目标2000 kcal仅为示例值，并非个性化医疗建议。需要个性化营养目标时，应结合年龄、身高、体重、活动量和健康情况评估。'))),
    const SizedBox(height: 12),
    const Text('最近记录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    ...weights.take(5).map((w) => ListTile(leading: const Icon(Icons.monitor_weight), title: Text('${w['kg']} kg'), subtitle: Text((w['created_at'] as String).replaceFirst('T',' ').split('.').first))),
  ]);
}
