import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Widget buildCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports"), centerTitle: true),
      body: FutureBuilder(
        future: Future.wait([
          DatabaseHelper.instance.getTotalRevenue(),
          DatabaseHelper.instance.getTotalOrders(),
          DatabaseHelper.instance.getCancelledOrders(),
          DatabaseHelper.instance.getAverageOrderValue(),
          DatabaseHelper.instance.getBestSellingItem(),
          DatabaseHelper.instance.getTopItems(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final revenue = snapshot.data![0] as double;

          final orders = snapshot.data![1] as int;

          final cancelled = snapshot.data![2] as int;

          final average = snapshot.data![3] as double;

          final bestSeller = snapshot.data![4] as Map<String, dynamic>?;

          final topItems = snapshot.data![5] as List<Map<String, dynamic>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Business Health",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  children: [
                    buildCard("Revenue", "₹${revenue.toStringAsFixed(0)}"),
                    buildCard("Orders", orders.toString()),
                    buildCard("Average", "₹${average.toStringAsFixed(0)}"),
                    buildCard("Cancelled", cancelled.toString()),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "Best Seller",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    title: Text(
                      bestSeller == null ? "No Data" : bestSeller["item_name"],
                    ),
                    subtitle: Text(
                      bestSeller == null
                          ? ""
                          : "${bestSeller["total_sold"]} sold",
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Top 5 Items",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: topItems.map((item) {
                      return ListTile(
                        title: Text(item["item_name"]),
                        trailing: Text("${item["total_sold"]}"),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
