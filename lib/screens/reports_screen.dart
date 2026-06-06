import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedFilter = "today";
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

  Widget buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedFilter == value,
        onSelected: (_) {
          setState(() {
            selectedFilter = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports"), centerTitle: true),
      body: FutureBuilder(
        future: Future.wait([
          DatabaseHelper.instance.getRevenue(selectedFilter),
          DatabaseHelper.instance.getOrdersCount(selectedFilter),
          DatabaseHelper.instance.getCancelledCount(selectedFilter),
          DatabaseHelper.instance.getAverageOrder(selectedFilter),
          DatabaseHelper.instance.getTopItems(),
          DatabaseHelper.instance.getPeakDay(),
          DatabaseHelper.instance.getSlowestDay(),
          DatabaseHelper.instance.getPeakHour(),
          DatabaseHelper.instance.getWeekdayDemandPattern(),

          DatabaseHelper.instance.getCategoryLeaders(),

          DatabaseHelper.instance.getWorstSellingItems(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final revenue = snapshot.data![0] as double;

          final orders = snapshot.data![1] as int;

          final cancelled = snapshot.data![2] as int;

          final average = snapshot.data![3] as double;

          final topItems = snapshot.data![4] as List<Map<String, dynamic>>;

          final peakDay = snapshot.data![5] as Map<String, dynamic>?;

          final slowestDay = snapshot.data![6] as Map<String, dynamic>?;

          final peakHour = snapshot.data![7] as Map<String, dynamic>?;

          final weekdayDemand = snapshot.data![8] as List<Map<String, dynamic>>;

          final categoryLeaders =
              snapshot.data![9] as List<Map<String, dynamic>>;

          final worstItems = snapshot.data![10] as List<Map<String, dynamic>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildFilterChip("Today", "today"),
                      buildFilterChip("Week", "week"),
                      buildFilterChip("Month", "month"),
                      buildFilterChip("All Time", "all"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
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

                const SizedBox(height: 20),

                const Text(
                  "Category Leaders",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: categoryLeaders.map((leader) {
                      return ListTile(
                        leading: const Icon(Icons.star),
                        title: Text(leader["category"]),
                        subtitle: Text(leader["item_name"]),
                        trailing: Text("${leader["total_sold"]}"),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Business Patterns",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events),
                    title: const Text("Peak Day"),
                    subtitle: Text(
                      peakDay == null ? "No Data" : peakDay["day"],
                    ),
                    trailing: Text(
                      peakDay == null
                          ? ""
                          : "₹${(peakDay["revenue"] as num).toStringAsFixed(0)}",
                    ),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.trending_down),
                    title: const Text("Slowest Day"),
                    subtitle: Text(
                      slowestDay == null ? "No Data" : slowestDay["day"],
                    ),
                    trailing: Text(
                      slowestDay == null
                          ? ""
                          : "₹${(slowestDay["revenue"] as num).toStringAsFixed(0)}",
                    ),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text("Peak Hour"),
                    subtitle: Text(
                      peakHour == null ? "No Data" : peakHour["hour"],
                    ),
                    trailing: Text(
                      peakHour == null ? "" : "${peakHour["orders"]} orders",
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Weekday Demand Pattern",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: weekdayDemand.map((day) {
                      return ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text("${day["day"]}'s Favorite"),
                        subtitle: Text(day["item_name"]),
                        trailing: Text("${day["total_sold"]}"),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Worst Performers",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: worstItems.map((item) {
                      return ListTile(
                        leading: const Icon(Icons.trending_down),
                        title: Text(item["item_name"]),
                        trailing: Text("${item["total_sold"]} sold"),
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
