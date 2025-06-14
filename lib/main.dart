import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'models/shopping_list.dart';
import 'models/shopping_item.dart';
import 'screens/shopping_list_detail_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ShoppingListAdapter());
  Hive.registerAdapter(ShoppingListStatusAdapter());
  Hive.registerAdapter(ShoppingItemAdapter());
  await Hive.openBox<ShoppingList>('shoppingLists');

  // Intent ile .shopx dosyası açıldıysa işle
  String? initialShopxPath;
  if (Platform.isAndroid) {
    final intent = await MethodChannel('app.channel.shared.data').invokeMethod<String>('getSharedFile');
    if (intent != null && intent.endsWith('.shopx')) {
      initialShopxPath = intent;
    }
  }

  runApp(ListemioApp(initialShopxPath: initialShopxPath));
}

class ListemioApp extends StatelessWidget {
  final String? initialShopxPath;
  const ListemioApp({super.key, this.initialShopxPath});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Listemio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ShoppingListsScreen(initialShopxPath: initialShopxPath),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ShoppingListsScreen extends StatefulWidget {
  final String? initialShopxPath;
  const ShoppingListsScreen({super.key, this.initialShopxPath});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Box<ShoppingList> shoppingListBox;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    shoppingListBox = Hive.box<ShoppingList>('shoppingLists');
    _importShopxFile();
  }

  void _importShopxFile() async {
    final path = widget.initialShopxPath;
    if (path != null) {
      try {
        final file = File(path);
        final content = await file.readAsString();
        final map = json.decode(content);
        final newList = ShoppingList(
          title: map['title'] ?? 'İçe Aktarılan Liste',
          createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
          status: ShoppingListStatus.open,
          items: (map['items'] as List).map((e) => ShoppingItem(name: e['name'], isChecked: e['isChecked'] ?? false)).toList(),
        );
        final box = Hive.box<ShoppingList>('shoppingLists');
        await box.add(newList);
        setState(() {}); // Listeyi ekranda hemen göster
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liste başarıyla içe aktarıldı.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dosya okunamadı veya format hatalı.')));
      }
    }
  }

  void _showAddListDialog() {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Alışveriş Listesi'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Liste Adı'),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Lütfen bir ad girin' : null,
            onSaved: (value) => title = value!.trim(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final newList = ShoppingList(
                  title: title,
                  createdAt: DateTime.now(),
                  status: ShoppingListStatus.open,
                  items: [],
                );
                shoppingListBox.add(newList);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lists = shoppingListBox.values.toList();
    final openLists = lists.where((l) => l.status == ShoppingListStatus.open).toList();
    final completedLists = lists.where((l) => l.status == ShoppingListStatus.completed).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listemio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Açık Listeler'),
            Tab(text: 'Tamamlanmış'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(openLists),
          _buildListView(completedLists),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddListDialog,
        tooltip: 'Yeni Liste Oluştur',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(List<ShoppingList> lists) {
    if (lists.isEmpty) {
      return const Center(child: Text('Hiç liste yok.'));
    }
    return ListView.separated(
      itemCount: lists.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final list = lists[i];
        return Card(
          child: ListTile(
            title: Text(list.title),
            subtitle: Text('Ürün: ${list.items.length} • Oluşturulma: ${list.createdAt.day}.${list.createdAt.month}.${list.createdAt.year}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(list.status == ShoppingListStatus.completed ? Icons.check_circle : Icons.radio_button_unchecked, color: list.status == ShoppingListStatus.completed ? Colors.green : Colors.grey),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final controller = TextEditingController(text: list.title);
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Liste Adını Düzenle'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: const InputDecoration(labelText: 'Liste Adı'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Kaydet')),
                          ],
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        list.title = result;
                        shoppingListBox.put(shoppingListBox.keyAt(i), list);
                        setState(() {});
                      }
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Listeyi Sil'),
                          content: const Text('Bu listeyi silmek istediğinize emin misiniz?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        shoppingListBox.delete(shoppingListBox.keyAt(i));
                        setState(() {});
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShoppingListDetailScreen(
                    list: list,
                    listKey: shoppingListBox.keyAt(i) as int,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        );
      },
    );
  }
}
