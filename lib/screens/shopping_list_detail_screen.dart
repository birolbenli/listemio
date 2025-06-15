import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final ShoppingList list;
  final int listKey;
  const ShoppingListDetailScreen({super.key, required this.list, required this.listKey});

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  late Box<ShoppingList> shoppingListBox;
  final TextEditingController _controller = TextEditingController();
  final List<String> _allSuggestions = [];

  // Popüler ve sık alınan ürünler (örnek veri)
  final List<String> _popularProducts = [
    'Ekmek', 'Süt', 'Yumurta', 'Domates', 'Peynir', 'Salatalık', 'Tavuk', 'Makarna', 'Pirinç', 'Şampuan', 'Deterjan', 'Elma', 'Muz', 'Patates', 'Soğan'
  ];

  @override
  void initState() {
    super.initState();
    shoppingListBox = Hive.box<ShoppingList>('shoppingLists');
    // Tüm listelerdeki ürün isimlerini öneri için topla
    for (var l in shoppingListBox.values) {
      for (var item in l.items) {
        if (!_allSuggestions.contains(item.name)) {
          _allSuggestions.add(item.name);
        }
      }
    }
  }

  // Gelişmiş ürün adı normalizasyonu
  Future<String> normalizeProductName(String name) async {
    // 1. Küçük harfe çevir, Türkçe karakter düzelt
    String normalized = name.trim().toLowerCase();
    normalized = normalized.replaceAll('i', 'ı').replaceAll('ü', 'u').replaceAll('ö', 'o').replaceAll('ş', 's').replaceAll('ç', 'c').replaceAll('ğ', 'g');
    // 2. Listedeki ürünlerle benzerliğe bak (Levenshtein distance)
    final suggestions = _allSuggestions.map((s) => s.toLowerCase()).toList();
    String? bestMatch;
    int minDistance = 3; // 2 veya daha az harf hatası toleransı
    for (final s in suggestions) {
      final distance = _levenshtein(normalized, s);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = s;
      }
    }
    if (bestMatch != null) {
      // İlk harfi büyük yap
      return bestMatch[0].toUpperCase() + bestMatch.substring(1);
    }
    // 3. (Opsiyonel) LLM API ile daha akıllı düzeltme
    // final apiKey = "YOUR_API_KEY";
    // ...LLM API kodu buraya...
    // 4. Hiçbiri olmazsa ilk harfi büyük yapıp döndür
    return name[0].toUpperCase() + name.substring(1);
  }

  // Levenshtein mesafesi hesaplama
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<List<int>> d = List.generate(s.length + 1, (_) => List.filled(t.length + 1, 0));
    for (int i = 0; i <= s.length; i++) d[i][0] = i;
    for (int j = 0; j <= t.length; j++) d[0][j] = j;
    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[s.length][t.length];
  }

  // Ürün kategorilendirme (örnek, daha gelişmişi için LLM API entegre edilebilir)
  String getCategory(String name) {
    final n = name.toLowerCase();
    if (['elma', 'armut', 'muz', 'karpuz', 'çilek', 'kiraz'].any((k) => n.contains(k))) return 'Meyve';
    if (['domates', 'salatalık', 'patates', 'soğan', 'biber', 'havuç', 'kabak'].any((k) => n.contains(k))) return 'Sebze';
    if (['ekmek', 'makarna', 'pirinç', 'bulgur'].any((k) => n.contains(k))) return 'Bakliyat';
    if (['peynir', 'süt', 'yoğurt', 'tereyağı'].any((k) => n.contains(k))) return 'Süt Ürünü';
    if (['şampuan', 'deterjan', 'sabun', 'diş macunu'].any((k) => n.contains(k))) return 'Temizlik';
    return 'Diğer';
  }

  // Ürün adı veya kategoriye göre emoji döndür
  String getProductEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('elma')) return '🍎';
    if (n.contains('armut')) return '🍐';
    if (n.contains('muz')) return '🍌';
    if (n.contains('karpuz')) return '🍉';
    if (n.contains('çilek')) return '🍓';
    if (n.contains('kiraz')) return '🍒';
    if (n.contains('domates')) return '🍅';
    if (n.contains('salatalık')) return '🥒';
    if (n.contains('patates')) return '🥔';
    if (n.contains('soğan')) return '🧅';
    if (n.contains('biber')) return '🌶️';
    if (n.contains('havuç')) return '🥕';
    if (n.contains('kabak')) return '🥒';
    if (n.contains('ekmek')) return '🍞';
    if (n.contains('makarna')) return '🍝';
    if (n.contains('pirinç')) return '🍚';
    if (n.contains('bulgur')) return '🌾';
    if (n.contains('peynir')) return '🧀';
    if (n.contains('süt')) return '🥛';
    if (n.contains('yoğurt')) return '🥣';
    if (n.contains('tereyağı')) return '🧈';
    if (n.contains('şampuan')) return '🧴';
    if (n.contains('deterjan')) return '🧼';
    if (n.contains('sabun')) return '🧼';
    if (n.contains('diş macunu')) return '🪥';
    if (n.contains('yumurta')) return '🥚';
    if (n.contains('tavuk')) return '🍗';
    if (n.contains('zeytin')) return '🫒';
    return '🛒';
  }

  void _addItem(String name) async {
    final normalized = await normalizeProductName(name);
    final category = getCategory(normalized);
    final updatedList = widget.list;
    final newItem = ShoppingItem(name: normalized); // İleride kategori eklenirse modele eklenebilir
    updatedList.items = List<ShoppingItem>.from(updatedList.items)..add(newItem);
    shoppingListBox.put(widget.listKey, updatedList);
    setState(() {
      if (!_allSuggestions.contains(normalized)) {
        _allSuggestions.add(normalized);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$normalized" eklendi ($category)')),
    );
  }

  void _toggleItem(int index, bool? value) {
    final updatedList = widget.list;
    final items = List<ShoppingItem>.from(updatedList.items);
    items[index] = ShoppingItem(name: items[index].name, isChecked: value ?? false);
    updatedList.items = items;
    shoppingListBox.put(widget.listKey, updatedList);
    setState(() {});
  }

  void _completeList() {
    final updatedList = widget.list;
    updatedList.status = ShoppingListStatus.completed;
    shoppingListBox.put(widget.listKey, updatedList);
    setState(() {});
    Navigator.pop(context);
  }

  Future<void> _shareListAsText() async {
    final items = widget.list.items.map((e) => '- ${e.name}${e.isChecked ? " (✓)" : ""}').join('\n');
    final text = 'Alışveriş Listesi: ${widget.list.title}\n\n$items';
    await Share.share(text, subject: widget.list.title);
  }

  Future<void> _shareListAsShopx() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${widget.list.title}_${widget.listKey}.shopx');
    final content = {
      'title': widget.list.title,
      'createdAt': widget.list.createdAt.toIso8601String(),
      'status': widget.list.status.name,
      'items': widget.list.items.map((e) => {'name': e.name, 'isChecked': e.isChecked}).toList(),
    };
    await file.writeAsString(json.encode(content));
    await Share.shareXFiles([XFile(file.path)], text: 'Listemio .shopx dosyası');
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.list.items;
    // Sık alınan ürün (kişisel) sıralama
    final Map<String, int> freq = {};
    for (var l in shoppingListBox.values) {
      for (var item in l.items) {
        freq[item.name] = (freq[item.name] ?? 0) + 1;
      }
    }
    final topPersonal = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPersonalNames = topPersonal.take(5).map((e) => e.key).toList();
    final topPopular = _popularProducts.where((p) => !topPersonalNames.contains(p)).take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.title),
        actions: [
          if (widget.list.status == ShoppingListStatus.open)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Listeyi Tamamla',
              onPressed: _completeList,
            ),
          if (widget.list.status == ShoppingListStatus.completed)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Açık Listeye Taşı',
              onPressed: () {
                final updatedList = widget.list;
                updatedList.status = ShoppingListStatus.open;
                shoppingListBox.put(widget.listKey, updatedList);
                setState(() {});
                Navigator.pop(context);
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Paylaş',
            onPressed: () async {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.text_snippet),
                        title: const Text('Metin olarak paylaş'),
                        onTap: () {
                          Navigator.pop(context);
                          _shareListAsText();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.file_present),
                        title: const Text('.shopx dosyası olarak paylaş'),
                        onTap: () {
                          Navigator.pop(context);
                          _shareListAsShopx();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (topPersonalNames.isNotEmpty) ...[
                  const Text('Sık Aldıkların', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: topPersonalNames.map((name) => ActionChip(
                      label: Text(name),
                      onPressed: () {
                        _addItem(name);
                        _controller.clear();
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                if (topPopular.isNotEmpty) ...[
                  const Text('Popüler Ürünler', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: topPopular.map((name) => ActionChip(
                      label: Text(name),
                      onPressed: () {
                        _addItem(name);
                        _controller.clear();
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TypeAheadField<String>(
                        controller: _controller,
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Ürün ekle',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                _addItem(value.trim());
                                controller.clear();
                              }
                            },
                          );
                        },
                        suggestionsCallback: (pattern) {
                          return _allSuggestions.where((s) => s.toLowerCase().contains(pattern.toLowerCase())).toList();
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(title: Text(suggestion));
                        },
                        onSelected: (suggestion) {
                          _addItem(suggestion);
                          _controller.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_controller.text.trim().isNotEmpty) {
                          _addItem(_controller.text.trim());
                          _controller.clear();
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Henüz ürün yok.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return ListTile(
                        leading: Checkbox(
                          value: item.isChecked,
                          onChanged: (val) {
                            _toggleItem(i, val);
                          },
                        ),
                        title: Row(
                          children: [
                            Text(getProductEmoji(item.name), style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 4),
                            Expanded(child: Text(item.name)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final controller = TextEditingController(text: item.name);
                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Ürün Adını Düzenle'),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: const InputDecoration(labelText: 'Ürün Adı'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Kaydet')),
                                  ],
                                ),
                              );
                              if (result != null && result.isNotEmpty) {
                                final normalized = await normalizeProductName(result);
                                final updatedList = widget.list;
                                final updatedItems = List<ShoppingItem>.from(updatedList.items);
                                updatedItems[i] = ShoppingItem(name: normalized, isChecked: item.isChecked);
                                updatedList.items = updatedItems;
                                shoppingListBox.put(widget.listKey, updatedList);
                                setState(() {});
                              }
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Ürünü Sil'),
                                  content: const Text('Bu ürünü silmek istediğinize emin misiniz?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final updatedList = widget.list;
                                final updatedItems = List<ShoppingItem>.from(updatedList.items)..removeAt(i);
                                updatedList.items = updatedItems;
                                shoppingListBox.put(widget.listKey, updatedList);
                                setState(() {});
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                            const PopupMenuItem(value: 'delete', child: Text('Sil')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
