import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import 'billing_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);

    tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String getOrderAge(String createdAt) {
    final created = DateTime.parse(createdAt);

    final diff = DateTime.now().difference(created);

    if (diff.inMinutes < 1) {
      return "Just now";
    }

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    }

    if (diff.inHours < 24) {
      return "${diff.inHours} hr ago";
    }

    return "${diff.inDays} day ago";
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    await DatabaseHelper.instance.updateOrderStatus(
      orderId: orderId,
      status: status,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> showOrderDetails(Map<String, dynamic> order) async {
    final items = await DatabaseHelper.instance.getOrderItems(order["id"]);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Order #${order["id"]}"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order["customer_name"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text("₹${order["total_amount"]}"),

                  const Divider(),

                  ...items.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item["item_name"]),
                      trailing: Text("x${item["quantity"]}"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget buildSummaryHeader() {
    return FutureBuilder(
      future: Future.wait([
        DatabaseHelper.instance.getOrdersByStatus("Pending"),
        DatabaseHelper.instance.getOrdersByStatus("Served"),
        DatabaseHelper.instance.getOrdersByStatus("Cancelled"),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final pending = (snapshot.data![0] as List).length;

        final served = (snapshot.data![1] as List).length;

        final cancelled = (snapshot.data![2] as List).length;

        Widget statCard(String title, int value, Color color) {
          return Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(title),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              statCard("Pending", pending, const Color(0xFFC48A3A)),

              statCard("Served", served, const Color(0xFF6B8E5A)),

              statCard("Cancelled", cancelled, const Color(0xFFB85C5C)),
            ],
          ),
        );
      },
    );
  }

  Widget buildOrdersList(String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getOrdersByStatus(status),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!;

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Color(0xFFA1887F),
                ),

                const SizedBox(height: 16),

                Text(
                  "No $status Orders",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "New orders will appear here.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            return InkWell(
              onTap: () => showOrderDetails(order),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Order #${order["id"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status == "Pending"
                                  ? const Color(0xFFC48A3A)
                                  : status == "Served"
                                  ? const Color(0xFF6B8E5A)
                                  : const Color(0xFFB85C5C),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        order["customer_name"],
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        getOrderAge(order["created_at"]),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "₹${order["total_amount"]}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (status == "Pending")
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BillingScreen(orderId: order["id"]),
                                    ),
                                  );

                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                                child: const Text("Edit"),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B8E5A),
                                ),
                                onPressed: () async {
                                  await updateOrderStatus(
                                    order["id"],
                                    "Served",
                                  );
                                },
                                child: const Text("Serve"),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB85C5C),
                                ),
                                onPressed: () async {
                                  await updateOrderStatus(
                                    order["id"],
                                    "Cancelled",
                                  );
                                },
                                child: const Text("Cancel"),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        bottom: TabBar(
          labelColor: Colors.white, // selected tab text
          unselectedLabelColor: Colors.white70, // unselected tabs
          indicatorColor: Colors.white,
          controller: tabController,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Served"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: Column(
        children: [
          buildSummaryHeader(),

          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                buildOrdersList("Pending"),
                buildOrdersList("Served"),
                buildOrdersList("Cancelled"),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillingScreen()),
          );

          if (mounted) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF6D4C41),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Order"),
      ),
    );
  }
}
