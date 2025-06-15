import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shoppingListBox = Hive.box<ShoppingList>('shoppingLists');
    final allLists = shoppingListBox.values.toList();
    final Map<String, int> productCounts = {};
    final Map<String, int> dayCounts = {};
    final now = DateTime.now();
    final monthLists = allLists.where((l) => l.createdAt.month == now.month && l.createdAt.year == now.year);
    for (var list in monthLists) {
      for (var item in list.items) {
        productCounts[item.name] = (productCounts[item.name] ?? 0) + 1;
      }
      final day = DateFormat('yyyy-MM-dd').format(list.createdAt);
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;
    }
    final topProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5Products = topProducts.take(5).toList();
    // Genel istatistikler
    final totalLists = allLists.length;
    final totalItems = allLists.fold<int>(0, (sum, l) => sum + l.items.length);
    final avgItems = totalLists > 0 ? (totalItems / totalLists).toStringAsFixed(1) : '0';
    final maxList = allLists.isNotEmpty ? allLists.reduce((a, b) => a.items.length > b.items.length ? a : b) : null;
    // Haftalık analiz
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekLists = allLists.where((l) => l.createdAt.isAfter(weekAgo));
    final Map<String, int> weekProductCounts = {};
    for (var list in weekLists) {
      for (var item in list.items) {
        weekProductCounts[item.name] = (weekProductCounts[item.name] ?? 0) + 1;
      }
    }
    final topWeekProducts = weekProductCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // En çok alışveriş yapılan gün
    final Map<String, int> allDayCounts = {};
    for (var list in allLists) {
      final day = DateFormat('yyyy-MM-dd').format(list.createdAt);
      allDayCounts[day] = (allDayCounts[day] ?? 0) + 1;
    }
    String? mostActiveDay;
    int mostActiveCount = 0;
    if (allDayCounts.isNotEmpty) {
      final sorted = allDayCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      mostActiveDay = sorted.first.key;
      mostActiveCount = sorted.first.value;
    }

    // Akıllı analiz ve tavsiye
    String advice = '';
    if (totalLists > 1) {
      if (totalItems / totalLists > 5) {
        advice = 'Listelerinizde ortalama ürün sayısı yüksek. Haftalık planlama ile daha verimli alışveriş yapabilirsiniz.';
      } else {
        advice = 'Listeleriniz kısa ve pratik. Böyle devam!';
      }
      if (mostActiveDay != null && DateTime.parse(mostActiveDay!).isAfter(now.subtract(const Duration(days: 7)))) {
        advice += '\nBu hafta alışveriş sıklığınız arttı.';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Bu Ay En Çok Alınan Ürünler', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 260,
              child: top5Products.isEmpty
                  ? const Center(child: Text('Veri yok'))
                  : PieChart(
                      PieChartData(
                        sections: List.generate(top5Products.length, (i) {
                          final entry = top5Products[i];
                          final color = Colors.primaries[i % Colors.primaries.length].shade400;
                          return PieChartSectionData(
                            value: entry.value.toDouble(),
                            color: color,
                            title: '${entry.key}\n${entry.value}x',
                            radius: 70,
                            titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
            ),
            const SizedBox(height: 32),
            const Text('Alışveriş Yapılan Günler', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 80,
              child: dayCounts.isEmpty
                  ? const Center(child: Text('Veri yok'))
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: dayCounts.entries.map((e) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('d MMM').format(DateTime.parse(e.key)), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${e.value} liste', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 32),
            const Text('Genel İstatistikler', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Toplam Liste: $totalLists'),
            Text('Toplam Ürün: $totalItems'),
            Text('Ortalama Ürün/Liste: $avgItems'),
            if (maxList != null) Text('En Uzun Liste: "${maxList.title}" (${maxList.items.length} ürün)'),
            if (mostActiveDay != null) Text('En çok alışveriş yapılan gün: ${DateFormat('d MMMM y', 'tr').format(DateTime.parse(mostActiveDay!))} ($mostActiveCount liste)'),
            const SizedBox(height: 24),
            const Text('Bu Hafta En Çok Alınan Ürünler', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 120,
              child: topWeekProducts.isEmpty
                  ? const Center(child: Text('Veri yok'))
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: topWeekProducts.take(10).map((e) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${e.value} kez', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 32),
            const Text('Alışveriş Yapılan Günler', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 80,
              child: dayCounts.isEmpty
                  ? const Center(child: Text('Veri yok'))
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: dayCounts.entries.map((e) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('d MMM').format(DateTime.parse(e.key)), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${e.value} liste', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 32),
            if (advice.isNotEmpty) ...[
              const Text('Alışveriş Analizi & Tavsiye', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(advice),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
