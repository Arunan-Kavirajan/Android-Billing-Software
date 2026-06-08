import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';

class BillingScreen extends StatefulWidget {
  final int? orderId;

  const BillingScreen({super.key, this.orderId});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  @override
  void initState() {
    super.initState();
    loadOrder();
  }

  final TextEditingController customerController = TextEditingController();

  List<Map<String, dynamic>> orderItems = [];

  bool get isEditMode => widget.orderId != null;

  double get total {
    double sum = 0;
    for (var item in orderItems) {
      sum += item["price"] * item["quantity"];
    }
    return sum;
  }

  void addItem(Map<String, dynamic> menuItem) {
    int existingIndex = orderItems.indexWhere(
      (item) => item["name"] == menuItem["name"],
    );

    setState(() {
      if (existingIndex != -1) {
        orderItems[existingIndex]["quantity"]++;
      } else {
        orderItems.add({
          "name": menuItem["name"],
          "price": menuItem["price"],
          "quantity": 1,
        });
      }
    });
  }

  void increaseQuantity(int index) {
    setState(() {
      orderItems[index]["quantity"]++;
    });
  }

  void decreaseQuantity(int index) {
    setState(() {
      if (orderItems[index]["quantity"] > 1) {
        orderItems[index]["quantity"]--;
      }
    });
  }

  void removeItem(int index) {
    setState(() {
      orderItems.removeAt(index);
    });
  }

  /// Returns the quantity of a menu item currently in the order (0 if not added)
  int getItemQuantity(String name) {
    final idx = orderItems.indexWhere((item) => item["name"] == name);
    return idx == -1 ? 0 : orderItems[idx]["quantity"] as int;
  }

  /// Decrease quantity from the add-item sheet; removes item if it reaches 0
  void decreaseItemByName(Map<String, dynamic> menuItem) {
    final idx = orderItems.indexWhere(
      (item) => item["name"] == menuItem["name"],
    );
    if (idx == -1) return;
    setState(() {
      if (orderItems[idx]["quantity"] > 1) {
        orderItems[idx]["quantity"]--;
      } else {
        orderItems.removeAt(idx);
      }
    });
  }

  // ── Persistent bottom-sheet with internal category → items navigation ──────

  void showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddItemSheet(
          orderItems: orderItems,
          onAdd: (item) {
            addItem(item);
          },
          onDecrease: (item) {
            decreaseItemByName(item);
          },
          getQuantity: getItemQuantity,
        );
      },
    );
  }

  // ── Save / load ─────────────────────────────────────────────────────────────

  Future<void> saveBill() async {
    if (customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter customer name")),
      );
      return;
    }

    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please add items")));
      return;
    }

    if (isEditMode) {
      await DatabaseHelper.instance.updateOrder(
        orderId: widget.orderId!,
        customerName: customerController.text.trim(),
        totalAmount: total,
      );

      await DatabaseHelper.instance.deleteOrderItems(widget.orderId!);

      for (var item in orderItems) {
        await DatabaseHelper.instance.addOrderItem(
          orderId: widget.orderId!,
          itemName: item["name"],
          price: item["price"],
          quantity: item["quantity"],
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final orderId = await DatabaseHelper.instance.createOrder(
      customerName: customerController.text.trim(),
      totalAmount: total,
    );

    for (var item in orderItems) {
      await DatabaseHelper.instance.addOrderItem(
        orderId: orderId,
        itemName: item["name"],
        price: item["price"],
        quantity: item["quantity"],
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Order Placed")));

    setState(() {
      customerController.clear();
      orderItems.clear();
    });

    Navigator.pop(context);
  }

  Future<void> loadOrder() async {
    if (widget.orderId == null) return;

    final order = await DatabaseHelper.instance.getOrder(widget.orderId!);
    final items = await DatabaseHelper.instance.getOrderItems(widget.orderId!);

    if (order == null) return;

    customerController.text = order["customer_name"];

    orderItems.clear();
    for (var item in items) {
      orderItems.add({
        "name": item["item_name"],
        "price": item["price"],
        "quantity": item["quantity"],
      });
    }

    if (mounted) setState(() {});
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text(
          "Billing",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Customer name ──────────────────────────────────────────────
            const Text(
              "Customer Name",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: customerController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.brown.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.brown.shade600,
                    width: 2,
                  ),
                ),
                hintText: "Enter customer name",
                hintStyle: TextStyle(color: Colors.brown.shade300),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 14),

            // ── Add Item button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: showAddItemSheet,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                label: const Text(
                  "Add Item",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade600,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Order list header ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Current Order",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                if (orderItems.isNotEmpty)
                  Text(
                    "${orderItems.length} item${orderItems.length == 1 ? '' : 's'}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.brown.shade400,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Order items list ───────────────────────────────────────────
            Expanded(
              child: orderItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.brown.shade200,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No items added yet",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.brown.shade300,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: orderItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        final lineTotal =
                            (item["price"] as num) * (item["quantity"] as num);

                        return Card(
                          elevation: 1,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                // Item info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["name"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "₹${item["price"]} × ${item["quantity"]}  =  ₹${lineTotal.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.brown.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Qty controls
                                _QtyControl(
                                  quantity: item["quantity"] as int,
                                  onDecrease: () => decreaseQuantity(index),
                                  onIncrease: () => increaseQuantity(index),
                                ),
                                // Delete
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.brown.shade300,
                                    size: 22,
                                  ),
                                  onPressed: () => removeItem(index),
                                  tooltip: "Remove",
                                  padding: const EdgeInsets.only(left: 4),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            // ── Total ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    "₹${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Place / Update Order ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade500,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isEditMode ? "Update Order" : "Place Order",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quantity control widget (reusable) ──────────────────────────────────────

class _QtyControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QtyControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circleBtn(Icons.remove, onDecrease),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "$quantity",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        _circleBtn(Icons.add, onIncrease),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback cb) {
    return InkWell(
      onTap: cb,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.brown.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.brown.shade700),
      ),
    );
  }
}

// ── Add Item Bottom Sheet ────────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final void Function(Map<String, dynamic> item) onAdd;
  final void Function(Map<String, dynamic> item) onDecrease;
  final int Function(String name) getQuantity;

  const _AddItemSheet({
    required this.orderItems,
    required this.onAdd,
    required this.onDecrease,
    required this.getQuantity,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String? _selectedCategory;

  List<Map<String, dynamic>> get _currentItems => _selectedCategory == null
      ? []
      : AppData.menuItems
            .where((item) => item["category"] == _selectedCategory)
            .toList();

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ─────────────────────────────────────────────
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

              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (_selectedCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () =>
                              setSheetState(() => _selectedCategory = null),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      _selectedCategory ?? "Select Category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    const Spacer(),
                    // Close button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.brown.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.brown.shade100, height: 1),

              // ── Content: categories or items ───────────────────────────
              Expanded(
                child: _selectedCategory == null
                    ? _CategoryList(
                        onSelect: (cat) =>
                            setSheetState(() => _selectedCategory = cat),
                      )
                    : _ItemList(
                        items: _currentItems,
                        getQuantity: (name) {
                          // Re-read live from parent's orderItems
                          final idx = widget.orderItems.indexWhere(
                            (o) => o["name"] == name,
                          );
                          return idx == -1
                              ? 0
                              : widget.orderItems[idx]["quantity"] as int;
                        },
                        onAdd: (item) {
                          widget.onAdd(item);
                          setSheetState(() {}); // refresh qty display
                        },
                        onDecrease: (item) {
                          widget.onDecrease(item);
                          setSheetState(() {});
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Category list inside sheet ───────────────────────────────────────────────

class _CategoryList extends StatelessWidget {
  final void Function(String category) onSelect;

  const _CategoryList({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: AppData.categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final category = AppData.categories[index];
        return ListTile(
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.brown.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: Colors.brown.shade50,
          onTap: () => onSelect(category),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        );
      },
    );
  }
}

// ── Item list inside sheet (with inline qty controls) ────────────────────────

class _ItemList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int Function(String name) getQuantity;
  final void Function(Map<String, dynamic> item) onAdd;
  final void Function(Map<String, dynamic> item) onDecrease;

  const _ItemList({
    required this.items,
    required this.getQuantity,
    required this.onAdd,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = items[index];
        final qty = getQuantity(item["name"] as String);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: qty > 0 ? Colors.brown.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: qty > 0 ? Colors.brown.shade300 : Colors.brown.shade100,
              width: qty > 0 ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Name + price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["name"],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "₹${item["price"]}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.brown.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Qty controls or Add button
              if (qty == 0)
                ElevatedButton(
                  onPressed: () => onAdd(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Add",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sheetQtyBtn(Icons.remove, () => onDecrease(item)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "$qty",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _sheetQtyBtn(Icons.add, () => onAdd(item)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetQtyBtn(IconData icon, VoidCallback cb) {
    return InkWell(
      onTap: cb,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.brown.shade600,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
