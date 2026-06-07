import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  String getOrderAge(String createdAt) {
    final created = DateTime.parse(createdAt);
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    return "${diff.inDays} day ago";
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    await DatabaseHelper.instance.updateOrderStatus(
      orderId: orderId,
      status: status,
    );
    if (mounted) setState(() {});
  }

  // ── Order details dialog ─────────────────────────────────────────────────

  Future<void> showOrderDetails(Map<String, dynamic> order) async {
    final items = await DatabaseHelper.instance.getOrderItems(order["id"]);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.brown.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Order #${order["id"]}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order["customer_name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${order["total_amount"]}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade700,
                    ),
                  ),
                  const Divider(height: 20),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item["item_name"],
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "x${item["quantity"]}  ₹${(item["price"] * item["quantity"]).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.brown.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: Colors.brown.shade400),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Print bill ───────────────────────────────────────────────────────────

  Future<void> showPrintDialog(Map<String, dynamic> order) async {
    final items = await DatabaseHelper.instance.getOrderItems(order["id"]);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.print_outlined,
                color: Colors.brown.shade700,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                "Print Bill?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            "Do you want to print the bill for ${order["customer_name"]}?",
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Skip",
                style: TextStyle(color: Colors.brown.shade400),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print, size: 18),
              label: const Text("Print"),
              onPressed: () {
                Navigator.pop(ctx);
                _selectPrinterAndPrint(order, items);
              },
            ),
          ],
        );
      },
    );
  }

  static const _printerKey = 'saved_printer_address';

  Future<String?> _getSavedPrinterAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_printerKey);
  }

  Future<void> _savePrinterAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerKey, address);
  }

  Future<void> _clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_printerKey);
  }

  Future<void> _selectPrinterAndPrint(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) async {
    // Check if we already have a saved printer
    String? address = await _getSavedPrinterAddress();

    if (address == null) {
      // First time — show device picker and save the choice
      final device = await FlutterBluetoothPrinter.selectDevice(context);
      if (device == null) return;
      address = device.address;
      await _savePrinterAddress(address);
    }

    await _printToAddress(address, order, items);
  }

  Future<void> _printToAddress(
    String address,
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final receipt = _buildReceipt(order, items);
      await FlutterBluetoothPrinter.printBytes(
        address: address,
        data: Uint8List.fromList(receipt),
        keepConnected: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Bill printed successfully"),
            action: SnackBarAction(
              label: "Change Printer",
              onPressed: () async {
                await _clearSavedPrinter();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Printer cleared. Next print will ask again.",
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // If print failed, clear saved address so they can re-select
        await _clearSavedPrinter();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Print failed. Please try again: $e")),
        );
      }
    }
  }

  /// Builds a raw ESC/POS byte array for a 58mm thermal printer.
  List<int> _buildReceipt(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) {
    // ESC/POS command helpers
    List<int> bytes = [];

    // ── ESC/POS constants ──
    const esc = 0x1B;
    const gs = 0x1D;

    void cmd(List<int> b) => bytes.addAll(b);
    void text(String s) => bytes.addAll(s.codeUnits);
    void nl([int n = 1]) => bytes.addAll(List.filled(n, 0x0A));

    // Initialize printer
    cmd([esc, 0x40]);

    // Center align
    cmd([esc, 0x61, 0x01]);
    // Double width + height (big header)
    cmd([gs, 0x21, 0x11]);
    text("D Brownies");
    nl();
    // Normal size
    cmd([gs, 0x21, 0x00]);
    text("--------------------------------");
    nl();

    // Date & time
    final now = DateTime.now();
    final dateStr =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    text(dateStr);
    nl();

    text("Order #${order["id"]}");
    nl();
    text("Customer: ${order["customer_name"]}");
    nl();
    text("--------------------------------");
    nl();

    // Left align for items
    cmd([esc, 0x61, 0x00]);
    // Bold on
    cmd([esc, 0x45, 0x01]);
    text(_padLine("Item", "Qty  Price", 32));
    nl();
    // Bold off
    cmd([esc, 0x45, 0x00]);
    text("--------------------------------");
    nl();

    for (var item in items) {
      final qty = item["quantity"] as int;
      final price = (item["price"] as num).toDouble();
      final lineTotal = (qty * price).toStringAsFixed(2);
      final right = "x$qty  ₹$lineTotal";
      final name = item["item_name"] as String;
      text(_padLine(name, right, 32));
      nl();
    }

    // Divider
    text("--------------------------------");
    nl();

    // Right align total
    cmd([esc, 0x61, 0x02]);
    cmd([esc, 0x45, 0x01]);
    cmd([gs, 0x21, 0x01]); // double height
    text("Total: Rs.${order["total_amount"]}");
    nl();
    cmd([gs, 0x21, 0x00]);
    cmd([esc, 0x45, 0x00]);

    // Center footer
    cmd([esc, 0x61, 0x01]);
    text("--------------------------------");
    nl();
    text("Thank you! Visit again :)");
    nl(4);

    // Cut paper
    cmd([gs, 0x56, 0x41, 0x03]);

    return bytes;
  }

  /// Pads two strings to fill [width] chars total (left + right aligned).
  String _padLine(String left, String right, int width) {
    final space = width - left.length - right.length;
    if (space <= 0)
      return "${left.substring(0, width - right.length - 1)} $right";
    return left + (' ' * space) + right;
  }

  // ── Serve with print prompt ──────────────────────────────────────────────

  Future<void> handleServe(Map<String, dynamic> order) async {
    await updateOrderStatus(order["id"], "Served");
    if (mounted) await showPrintDialog(order);
  }

  // ── Summary header ───────────────────────────────────────────────────────

  Widget buildSummaryHeader() {
    return FutureBuilder(
      future: Future.wait([
        DatabaseHelper.instance.getOrdersByStatus("Pending"),
        DatabaseHelper.instance.getOrdersByStatus("Served"),
        DatabaseHelper.instance.getOrdersByStatus("Cancelled"),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final pending = (snapshot.data![0] as List).length;
        final served = (snapshot.data![1] as List).length;
        final cancelled = (snapshot.data![2] as List).length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              _statCard(
                "Pending",
                pending,
                const Color(0xFFC48A3A),
                Icons.hourglass_top_rounded,
              ),
              const SizedBox(width: 8),
              _statCard(
                "Served",
                served,
                const Color(0xFF6B8E5A),
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _statCard(
                "Cancelled",
                cancelled,
                const Color(0xFFB85C5C),
                Icons.cancel_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Orders list ──────────────────────────────────────────────────────────

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
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: Colors.brown.shade200,
                ),
                const SizedBox(height: 12),
                Text(
                  "No $status Orders",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "New orders will appear here.",
                  style: TextStyle(color: Colors.brown.shade300, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderCard(
              order: order,
              status: status,
              orderAge: getOrderAge(order["created_at"]),
              onTap: () => showOrderDetails(order),
              onEdit: status == "Pending"
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillingScreen(orderId: order["id"]),
                        ),
                      );
                      if (mounted) setState(() {});
                    }
                  : null,
              onServe: status == "Pending" ? () => handleServe(order) : null,
              onCancel: status == "Pending"
                  ? () => updateOrderStatus(order["id"], "Cancelled")
                  : null,
            );
          },
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text(
          "Orders",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
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
          if (mounted) setState(() {});
        },
        backgroundColor: const Color(0xFF6D4C41),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          "New Order",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Order card widget ────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String status;
  final String orderAge;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onServe;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.order,
    required this.status,
    required this.orderAge,
    required this.onTap,
    this.onEdit,
    this.onServe,
    this.onCancel,
  });

  Color get _statusColor {
    switch (status) {
      case "Pending":
        return const Color(0xFFC48A3A);
      case "Served":
        return const Color(0xFF6B8E5A);
      default:
        return const Color(0xFFB85C5C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.brown.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: order # + status badge ─────────────────────────
              Row(
                children: [
                  Text(
                    "Order #${order["id"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ── Customer + age ───────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 15,
                    color: Colors.brown.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order["customer_name"],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.brown.shade700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 13,
                    color: Colors.brown.shade300,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    orderAge,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown.shade400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Total ────────────────────────────────────────────────────
              Text(
                "₹${order["total_amount"]}",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),

              // ── Action buttons (Pending only) ─────────────────────────
              if (onEdit != null || onServe != null || onCancel != null) ...[
                const SizedBox(height: 12),
                Divider(color: Colors.brown.shade100, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Edit
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text("Edit"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.brown.shade700,
                          side: BorderSide(color: Colors.brown.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Serve
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onServe,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("Serve"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B8E5A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Cancel
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text("Cancel"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB85C5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
