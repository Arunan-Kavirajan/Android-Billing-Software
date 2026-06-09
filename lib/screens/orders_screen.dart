import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String getOrderAge(String createdAt) {
    final created = DateTime.parse(createdAt);
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    return "${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago";
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    await DatabaseHelper.instance.updateOrderStatus(
      orderId: orderId,
      status: status,
    );
    if (mounted) setState(() {});
  }

  // ── Serve confirmation ───────────────────────────────────────────────────

  Future<void> handleServe(Map<String, dynamic> order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B8E5A).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF6B8E5A),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Mark as Served?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          "Mark Order #${order["id"]} for ${order["customer_name"]} as served?",
          style: const TextStyle(fontSize: 14),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8E5A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Serve"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await updateOrderStatus(order["id"], "Served");
  }

  // ── Cancel confirmation ──────────────────────────────────────────────────

  Future<void> handleCancel(Map<String, dynamic> order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFB85C5C).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: Color(0xFFB85C5C),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Cancel Order?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel Order #${order["id"]} for ${order["customer_name"]}?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "No, Keep It",
              style: TextStyle(color: Colors.brown.shade400),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB85C5C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await updateOrderStatus(order["id"], "Cancelled");
  }

  // ── Order details bottom sheet ───────────────────────────────────────────

  Future<void> showOrderDetails(Map<String, dynamic> order) async {
    final items = await DatabaseHelper.instance.getOrderItems(order["id"]);
    if (!mounted) return;

    final status = order["status"] as String? ?? "Pending";
    final statusColor = status == "Served"
        ? const Color(0xFF6B8E5A)
        : status == "Cancelled"
        ? const Color(0xFFB85C5C)
        : const Color(0xFFC48A3A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Order #${order["id"]}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.brown.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order["customer_name"],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.brown.shade600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.access_time,
                                size: 13,
                                color: Colors.brown.shade300,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                getOrderAge(order["created_at"]),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.brown.shade400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${order["total_amount"]}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.brown.shade100, height: 1),

              // Items list
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.brown.shade50, height: 12),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final lineTotal =
                        (item["price"] as num) * (item["quantity"] as num);
                    return Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              "×${item["quantity"]}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item["item_name"],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${lineTotal.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.brown.shade700,
                              ),
                            ),
                            Text(
                              "₹${item["price"]} each",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.brown.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Total row
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.brown.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "₹${order["total_amount"]}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Print button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _triggerPrint(order);
                    },
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text(
                      "Print Receipt",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Print logic ──────────────────────────────────────────────────────────

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

  /// Entry point — fetches items then handles printer selection + printing
  Future<void> _triggerPrint(Map<String, dynamic> order) async {
    final items = await DatabaseHelper.instance.getOrderItems(order["id"]);
    if (!mounted) return;
    await _selectPrinterAndPrint(order, items);
  }

  /// Shows paired device picker as a bottom sheet, returns selected address or null
  Future<String?> _showPrinterPicker() async {
    final List<BluetoothInfo> paired =
        await PrintBluetoothThermal.pairedBluetooths;

    if (!mounted) return null;

    if (paired.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No paired printers found. Please pair your printer in Bluetooth settings first.",
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return null;
    }

    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.print_outlined,
                      color: Colors.brown.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Select Printer",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.brown.shade100, height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: paired.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.brown.shade50),
                  itemBuilder: (ctx, i) {
                    final device = paired[i];
                    return ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bluetooth,
                          color: Colors.brown.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        device.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        device.macAdress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown.shade400,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, device.macAdress),
                    );
                  },
                ),
              ), // Flexible
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectPrinterAndPrint(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) async {
    String? address = await _getSavedPrinterAddress();

    // No saved printer — show picker
    if (address == null) {
      address = await _showPrinterPicker();
      if (address == null) return; // user dismissed
      await _savePrinterAddress(address);
    }

    await _printToAddress(address, order, items);
  }

  Future<void> _printToAddress(
    String address,
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text("Connecting to printer..."),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Attempt connection — returns true/false, no silent failures
      final bool connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: address,
      );

      if (!connected) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Could not connect to printer. Make sure it's on and nearby.",
              ),
              duration: Duration(seconds: 2),
            ),
          );
          // Clear saved address and show picker to retry or pick another
          await _clearSavedPrinter();
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          final newAddress = await _showPrinterPicker();
          if (newAddress == null) return;
          await _savePrinterAddress(newAddress);
          await _printToAddress(newAddress, order, items);
        }
        return;
      }

      // Connected — verify once more then send bytes
      final bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        throw Exception("Connection dropped before printing.");
      }

      final receipt = _buildReceipt(order, items);
      final bool printed = await PrintBluetoothThermal.writeBytes(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (printed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Receipt printed successfully"),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception("Printer did not confirm print.");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await _clearSavedPrinter();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Print failed. Please try again."),
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        final newAddress = await _showPrinterPicker();
        if (newAddress == null) return;
        await _savePrinterAddress(newAddress);
        await _printToAddress(newAddress, order, items);
      }
    }
  }

  List<int> _buildReceipt(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) {
    List<int> bytes = [];
    const esc = 0x1B;
    const gs = 0x1D;

    void cmd(List<int> b) => bytes.addAll(b);
    void text(String s) => bytes.addAll(s.codeUnits);
    void nl([int n = 1]) => bytes.addAll(List.filled(n, 0x0A));

    cmd([esc, 0x40]);
    cmd([esc, 0x61, 0x01]);
    cmd([gs, 0x21, 0x11]);
    text("D Brownies");
    nl();
    cmd([gs, 0x21, 0x00]);
    text("--------------------------------");
    nl();

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

    cmd([esc, 0x61, 0x00]);
    cmd([esc, 0x45, 0x01]);
    text(_padLine("Item", "Qty  Price", 32));
    nl();
    cmd([esc, 0x45, 0x00]);
    text("--------------------------------");
    nl();

    for (var item in items) {
      final qty = item["quantity"] as int;
      final price = (item["price"] as num).toDouble();
      final lineTotal = (qty * price).toStringAsFixed(2);
      final right = "x$qty  Rs.$lineTotal";
      final name = item["item_name"] as String;
      text(_padLine(name, right, 32));
      nl();
    }

    text("--------------------------------");
    nl();
    cmd([esc, 0x61, 0x02]);
    cmd([esc, 0x45, 0x01]);
    cmd([gs, 0x21, 0x01]);
    text("Total: Rs.${order["total_amount"]}");
    nl();
    cmd([gs, 0x21, 0x00]);
    cmd([esc, 0x45, 0x00]);
    cmd([esc, 0x61, 0x01]);
    text("--------------------------------");
    nl();
    text("Thank you! Visit again :)");
    nl(4);
    cmd([gs, 0x56, 0x41, 0x03]);

    return bytes;
  }

  String _padLine(String left, String right, int width) {
    final space = width - left.length - right.length;
    if (space <= 0)
      return "${left.substring(0, width - right.length - 1)} $right";
    return left + (' ' * space) + right;
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

  // ── Search bar (Pending only) ────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search by name or order #",
          hintStyle: TextStyle(color: Colors.brown.shade300, fontSize: 13),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.brown.shade400,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => _searchController.clear(),
                  child: Icon(
                    Icons.close,
                    color: Colors.brown.shade400,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.brown.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.brown.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.brown.shade500, width: 1.5),
          ),
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

        final allOrders = snapshot.data!;

        // Apply search filter on Pending tab only
        final orders = status == "Pending" && _searchQuery.isNotEmpty
            ? allOrders.where((o) {
                final name = (o["customer_name"] as String).toLowerCase();
                final id = o["id"].toString();
                return name.contains(_searchQuery) || id.contains(_searchQuery);
              }).toList()
            : allOrders;

        if (allOrders.isEmpty) {
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

        Widget list;

        if (orders.isEmpty && _searchQuery.isNotEmpty) {
          list = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Colors.brown.shade200,
                ),
                const SizedBox(height: 10),
                Text(
                  "No results for \"$_searchQuery\"",
                  style: TextStyle(fontSize: 15, color: Colors.brown.shade400),
                ),
              ],
            ),
          );
        } else {
          list = ListView.separated(
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
                onPrint: () => _triggerPrint(order),
                onServe: status == "Pending" ? () => handleServe(order) : null,
                onCancel: status == "Pending"
                    ? () => handleCancel(order)
                    : null,
              );
            },
          );
        }

        if (status == "Pending") {
          return Column(
            children: [
              _buildSearchBar(),
              Expanded(child: list),
            ],
          );
        }

        return list;
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
  final VoidCallback onPrint;
  final VoidCallback? onServe;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.order,
    required this.status,
    required this.orderAge,
    required this.onTap,
    required this.onPrint,
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
    final isPending = status == "Pending";

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
              // ── Top row ──────────────────────────────────────────────────
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

              const SizedBox(height: 10),
              Divider(color: Colors.brown.shade100, height: 1),
              const SizedBox(height: 10),

              // ── Buttons ──────────────────────────────────────────────────
              if (isPending) ...[
                // Row 1: Edit + Print Receipt
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 15),
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
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPrint,
                        icon: const Icon(Icons.print_outlined, size: 15),
                        label: const Text("Print"),
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
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Serve + Cancel
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onServe,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text("Serve"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B8E5A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text("Cancel"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB85C5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Served / Cancelled — just a Print Receipt button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: const Text("Print Receipt"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown.shade700,
                      side: BorderSide(color: Colors.brown.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
