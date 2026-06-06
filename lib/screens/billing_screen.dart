import 'package:flutter/material.dart';
import '../data/app_data.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController customerController = TextEditingController();

  List<Map<String, dynamic>> orderItems = [];

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

  void showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Category"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppData.categories.length,
              itemBuilder: (context, index) {
                final category = AppData.categories[index];

                return ListTile(
                  title: Text(category),
                  onTap: () {
                    Navigator.pop(context);

                    showItemDialog(category);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void showItemDialog(String category) {
    final items = AppData.menuItems
        .where((item) => item["category"] == category)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return ListTile(
                  title: Text(item["name"]),
                  subtitle: Text("₹${item["price"]}"),
                  onTap: () {
                    addItem(item);

                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void saveBill() {
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Bill Saved"),
          content: Text(
            "Customer: ${customerController.text}\nTotal: ₹${total.toStringAsFixed(2)}",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  customerController.clear();
                  orderItems.clear();
                });
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("D Brownie Billing"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Customer Name",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: customerController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter customer name",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: showCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add Item"),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Current Order",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: orderItems.isEmpty
                  ? const Center(
                      child: Text(
                        "No items added yet",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];

                        return Card(
                          child: ListTile(
                            title: Text(item["name"]),
                            subtitle: Text(
                              "₹${item["price"]} x ${item["quantity"]}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => decreaseQuantity(index),
                                ),
                                Text(item["quantity"].toString()),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => increaseQuantity(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Total: ₹${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveBill,
                child: const Text("Save Bill", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
