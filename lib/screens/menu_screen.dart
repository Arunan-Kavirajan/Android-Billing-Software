import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final categories = await DatabaseHelper.instance.getCategories();

    final items = await DatabaseHelper.instance.getMenuItems();

    bool hasUncategorized = categories.any(
      (c) => c["name"] == AppData.uncategorized,
    );

    if (!hasUncategorized) {
      await DatabaseHelper.instance.insertCategory(AppData.uncategorized);
      categories.add({"name": AppData.uncategorized});
    }

    AppData.categories = categories.map((e) => e["name"] as String).toList();

    AppData.categories.remove(AppData.uncategorized);

    AppData.categories.add(AppData.uncategorized);

    AppData.menuItems = items;

    if (mounted) setState(() {});
  }

  final TextEditingController categoryController = TextEditingController();

  final TextEditingController itemController = TextEditingController();

  final TextEditingController priceController = TextEditingController();

  String? selectedCategory;

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> addCategory() async {
    String category = categoryController.text.trim();

    if (category.isEmpty) return;

    bool exists = AppData.categories.any(
      (c) => c.toLowerCase() == category.toLowerCase(),
    );

    if (exists) {
      showMessage("Category already exists");
      return;
    }

    await DatabaseHelper.instance.insertCategory(category);
    await loadData();
    categoryController.clear();
  }

  void editCategory(String oldCategory) {
    if (oldCategory == AppData.uncategorized) {
      showMessage("Cannot edit Uncategorized");
      return;
    }

    final controller = TextEditingController(text: oldCategory);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Category"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Category Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String newCategory = controller.text.trim();

                if (newCategory.isEmpty) {
                  return;
                }

                bool exists = AppData.categories.any(
                  (c) =>
                      c.toLowerCase() == newCategory.toLowerCase() &&
                      c != oldCategory,
                );

                if (exists) {
                  showMessage("Category already exists");
                  return;
                }

                await DatabaseHelper.instance.updateCategory(
                  oldCategory,
                  newCategory,
                );

                for (var item in AppData.menuItems) {
                  if (item["category"] == oldCategory) {
                    await DatabaseHelper.instance.updateMenuItem(
                      oldName: item["name"],
                      name: item["name"],
                      price: item["price"],
                      category: newCategory,
                    );
                  }
                }

                await loadData();

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void deleteCategory(String category) {
    if (category == AppData.uncategorized) {
      showMessage("Cannot delete Uncategorized");
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Category"),
          content: Text(
            "Move all items to Uncategorized and delete '$category'?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                for (var item in AppData.menuItems) {
                  if (item["category"] == category) {
                    await DatabaseHelper.instance.updateMenuItem(
                      oldName: item["name"],
                      name: item["name"],
                      price: item["price"],
                      category: AppData.uncategorized,
                    );
                  }
                }

                await DatabaseHelper.instance.deleteCategory(category);

                await loadData();

                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> addItem() async {
    String name = itemController.text.trim();

    double? price = double.tryParse(priceController.text.trim());

    if (name.isEmpty || selectedCategory == null) {
      return;
    }

    if (price == null || price <= 0) {
      showMessage("Enter valid price");
      return;
    }

    bool exists = AppData.menuItems.any(
      (item) =>
          item["category"] == selectedCategory &&
          item["name"].toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      showMessage("Item already exists in this category");
      return;
    }

    await DatabaseHelper.instance.insertMenuItem(
      name: name,
      price: price,
      category: selectedCategory!,
    );

    await loadData();

    itemController.clear();
    priceController.clear();
  }

  void editItem(int index) {
    final item = AppData.menuItems[index];

    final nameController = TextEditingController(text: item["name"]);

    final editPriceController = TextEditingController(
      text: item["price"].toString(),
    );

    String category = item["category"];

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Item"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Item Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: editPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Price"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: AppData.categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          category = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String newName = nameController.text.trim();

                    double? newPrice = double.tryParse(
                      editPriceController.text,
                    );

                    if (newPrice == null || newPrice <= 0) {
                      showMessage("Enter valid price");
                      return;
                    }

                    bool exists = AppData.menuItems.any(
                      (menuItem) =>
                          menuItem != item &&
                          menuItem["category"] == category &&
                          menuItem["name"].toLowerCase() ==
                              newName.toLowerCase(),
                    );

                    if (exists) {
                      showMessage("Item already exists in this category");
                      return;
                    }

                    await DatabaseHelper.instance.updateMenuItem(
                      oldName: item["name"],
                      name: newName,
                      price: newPrice,
                      category: category,
                    );

                    await loadData();

                    /*
                        "name": newName,
                        "price": newPrice,
                        "category": category,
                      };
                    });*/

                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteItem(int index) async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Item"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.deleteMenuItem(
                  AppData.menuItems[index]["name"],
                );

                Navigator.pop(context);

                await loadData();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menu Management")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Categories",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Category Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addCategory,
                child: const Text("Add Category"),
              ),
            ),

            const SizedBox(height: 15),

            ...AppData.categories
                .where((category) => category != AppData.uncategorized)
                .map(
                  (category) => Card(
                    child: ListTile(
                      title: Text(category),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editCategory(category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCategory(category),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

            const SizedBox(height: 30),

            const Text(
              "Menu Items",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: itemController,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Category",
              ),
              items: AppData.categories
                  .where((category) => category != AppData.uncategorized)
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addItem,
                child: const Text("Add Item"),
              ),
            ),

            const SizedBox(height: 20),

            ...AppData.categories.map((category) {
              final items = AppData.menuItems
                  .where((item) => item["category"] == category)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...items.map((item) {
                    return Card(
                      child: ListTile(
                        title: Text(item["name"]),
                        subtitle: Text("₹${item["price"]}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => editItem(
                                AppData.menuItems.indexWhere(
                                  (menuItem) =>
                                      menuItem["name"] == item["name"] &&
                                      menuItem["category"] == item["category"],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteItem(
                                AppData.menuItems.indexWhere(
                                  (menuItem) =>
                                      menuItem["name"] == item["name"] &&
                                      menuItem["category"] == item["category"],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 15),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
