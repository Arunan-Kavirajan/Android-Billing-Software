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
            child: Text(
              "No $status Orders",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                      Text(
                        "#${order["id"]}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(order["customer_name"]),

                      const SizedBox(height: 4),

                      Text("₹${order["total_amount"]}"),

                      const SizedBox(height: 10),

                      if (status == "Pending")
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Edit Order coming next"),
                                    ),
                                  );
                                },
                                child: const Text("Edit"),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton(
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
          controller: tabController,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Served"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          buildOrdersList("Pending"),
          buildOrdersList("Served"),
          buildOrdersList("Cancelled"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillingScreen()),
          );

          if (mounted) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
