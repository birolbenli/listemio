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
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Bu Ay En Çok Alınan Ürünler', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 220,
              child: topProducts.isEmpty
                  ? const Center(child: Text('Veri yok'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (topProducts.isNotEmpty ? topProducts.first.value.toDouble() + 1 : 1),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= topProducts.length) return const SizedBox();
                                return Text(topProducts[idx].key, style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(topProducts.length, (i) {
                          return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: topProducts[i].value.toDouble(), color: Colors.teal)]);
                        }),
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
          ],
        ),
      ),
    );
  }
}
