import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';

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

  void _addItem(String name) {
    final updatedList = widget.list;
    final newItem = ShoppingItem(name: name);
    updatedList.items = List<ShoppingItem>.from(updatedList.items)..add(newItem);
    shoppingListBox.put(widget.listKey, updatedList);
    setState(() {
      if (!_allSuggestions.contains(name)) {
        _allSuggestions.add(name);
      }
    });
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
            child: Row(
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
                        title: Text(item.name),
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
                                final updatedList = widget.list;
                                final updatedItems = List<ShoppingItem>.from(updatedList.items);
                                updatedItems[i] = ShoppingItem(name: result, isChecked: item.isChecked);
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
