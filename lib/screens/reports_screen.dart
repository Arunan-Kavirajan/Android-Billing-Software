import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedFilter = "today";

  Future<void> showResetDialog() async {
    final stats = await DatabaseHelper.instance.getBusinessDataStats();
    if (!mounted) return;

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Reset Business Data?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Orders: ${stats["orders"]}\n\n"
          "Revenue History: ₹${stats["revenue"]}\n\n"
          "All orders and reports will be deleted.\n"
          "Menu items and categories will be kept.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.brown.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Continue"),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;
    if (!mounted) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Final Warning",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          "This action cannot be undone.\n\n"
          "All order history and reports will be permanently deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("No", style: TextStyle(color: Colors.brown.shade400)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete Everything"),
          ),
        ],
      ),
    );

    if (secondConfirm != true) return;

    await DatabaseHelper.instance.clearBusinessData();
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Business data cleared")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text(
          "Reports",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
      ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Filter chips ───────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip("Today", "today"),
                      _filterChip("Week", "week"),
                      _filterChip("Month", "month"),
                      _filterChip("All Time", "all"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Business health ────────────────────────────────────────
                _sectionTitle("Business Health"),
                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    _statCard(
                      "Revenue",
                      "₹${revenue.toStringAsFixed(0)}",
                      Icons.currency_rupee_rounded,
                      Colors.brown.shade700,
                    ),
                    _statCard(
                      "Orders",
                      orders.toString(),
                      Icons.receipt_long_outlined,
                      const Color(0xFF6B8E5A),
                    ),
                    _statCard(
                      "Avg Order",
                      "₹${average.toStringAsFixed(0)}",
                      Icons.analytics_outlined,
                      Colors.brown.shade500,
                    ),
                    _statCard(
                      "Cancelled",
                      cancelled.toString(),
                      Icons.cancel_outlined,
                      const Color(0xFFB85C5C),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Top 5 items ────────────────────────────────────────────
                _sectionTitle("Top 5 Items"),
                const SizedBox(height: 12),

                _listCard(
                  children: topItems.isEmpty
                      ? [_emptyRow("No data yet")]
                      : topItems.asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final item = e.value;
                          return _rankRow(
                            rank: rank,
                            label: item["item_name"],
                            trailing: "${item["total_sold"]} sold",
                          );
                        }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Category leaders ───────────────────────────────────────
                _sectionTitle("Category Leaders"),
                const SizedBox(height: 12),

                _listCard(
                  children: categoryLeaders.isEmpty
                      ? [_emptyRow("No data yet")]
                      : categoryLeaders.map((leader) {
                          return _iconRow(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFC48A3A),
                            title: leader["item_name"],
                            subtitle: leader["category"],
                            trailing: "${leader["total_sold"]} sold",
                          );
                        }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Business patterns ──────────────────────────────────────
                _sectionTitle("Business Patterns"),
                const SizedBox(height: 12),

                _listCard(
                  children: [
                    _iconRow(
                      icon: Icons.emoji_events_rounded,
                      iconColor: const Color(0xFFC48A3A),
                      title: "Peak Day",
                      subtitle: peakDay == null ? "No data" : peakDay["day"],
                      trailing: peakDay == null
                          ? ""
                          : "₹${(peakDay["revenue"] as num).toStringAsFixed(0)}",
                    ),
                    _divider(),
                    _iconRow(
                      icon: Icons.trending_down_rounded,
                      iconColor: const Color(0xFFB85C5C),
                      title: "Slowest Day",
                      subtitle: slowestDay == null
                          ? "No data"
                          : slowestDay["day"],
                      trailing: slowestDay == null
                          ? ""
                          : "₹${(slowestDay["revenue"] as num).toStringAsFixed(0)}",
                    ),
                    _divider(),
                    _iconRow(
                      icon: Icons.access_time_rounded,
                      iconColor: Colors.brown.shade600,
                      title: "Peak Hour",
                      subtitle: peakHour == null ? "No data" : peakHour["hour"],
                      trailing: peakHour == null
                          ? ""
                          : "${peakHour["orders"]} orders",
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Weekday demand pattern ─────────────────────────────────
                _sectionTitle("Weekday Demand Pattern"),
                const SizedBox(height: 12),

                _listCard(
                  children: weekdayDemand.isEmpty
                      ? [_emptyRow("No data yet")]
                      : weekdayDemand.asMap().entries.map((e) {
                          final i = e.key;
                          final day = e.value;
                          return Column(
                            children: [
                              if (i > 0) _divider(),
                              _iconRow(
                                icon: Icons.calendar_today_outlined,
                                iconColor: Colors.brown.shade500,
                                title: "${day["day"]}'s Favorite",
                                subtitle: day["item_name"],
                                trailing: "${day["total_sold"]} sold",
                              ),
                            ],
                          );
                        }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Worst performers ───────────────────────────────────────
                _sectionTitle("Worst Performers"),
                const SizedBox(height: 12),

                _listCard(
                  children: worstItems.isEmpty
                      ? [_emptyRow("No data yet")]
                      : worstItems.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          return Column(
                            children: [
                              if (i > 0) _divider(),
                              _iconRow(
                                icon: Icons.trending_down_rounded,
                                iconColor: const Color(0xFFB85C5C),
                                title: item["item_name"],
                                subtitle: null,
                                trailing: "${item["total_sold"]} sold",
                              ),
                            ],
                          );
                        }).toList(),
                ),

                const SizedBox(height: 30),

                // ── Danger zone ────────────────────────────────────────────
                Divider(color: Colors.brown.shade200),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Danger Zone",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reset all order history and revenue reports. Menu items and categories will not be affected.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: showResetDialog,
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: const Text(
                            "Reset Business Data",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Reusable UI helpers ──────────────────────────────────────────────────

  Widget _filterChip(String label, String value) {
    final selected = selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.brown.shade700 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.brown.shade700 : Colors.brown.shade200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.brown.shade600,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.brown.shade800,
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.brown.shade400),
              ),
              Icon(icon, size: 18, color: color.withOpacity(0.7)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Column(children: children),
    );
  }

  Widget _rankRow({
    required int rank,
    required String label,
    required String trailing,
  }) {
    final isTop = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isTop ? const Color(0xFFC48A3A) : Colors.brown.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$rank",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isTop ? Colors.white : Colors.brown.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            trailing,
            style: TextStyle(fontSize: 13, color: Colors.brown.shade500),
          ),
        ],
      ),
    );
  }

  Widget _iconRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String? subtitle,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown.shade400,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 13,
                color: Colors.brown.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyRow(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.brown.shade300, fontSize: 13),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.brown.shade100,
    );
  }
}
