import 'package:flutter/material.dart';
import '../data/app_data.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController categoryController = TextEditingController();

  final TextEditingController itemController = TextEditingController();

  final TextEditingController priceController = TextEditingController();

  String? selectedCategory;

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void addCategory() {
    String category = categoryController.text.trim();

    if (category.isEmpty) return;

    bool exists = AppData.categories.any(
      (c) => c.toLowerCase() == category.toLowerCase(),
    );

    if (exists) {
      showMessage("Category already exists");
      return;
    }

    setState(() {
      AppData.categories.add(category);
    });

    categoryController.clear();
  }

  void editCategory(String oldCategory) {
    if (oldCategory == "Uncategorized") {
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
              onPressed: () {
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

                setState(() {
                  int index = AppData.categories.indexOf(oldCategory);

                  AppData.categories[index] = newCategory;

                  for (var item in AppData.menuItems) {
                    if (item["category"] == oldCategory) {
                      item["category"] = newCategory;
                    }
                  }
                });

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
    if (category == "Uncategorized") {
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
              onPressed: () {
                setState(() {
                  for (var item in AppData.menuItems) {
                    if (item["category"] == category) {
                      item["category"] = "Uncategorized";
                    }
                  }

                  AppData.categories.remove(category);

                  if (selectedCategory == category) {
                    selectedCategory = null;
                  }
                });

                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void addItem() {
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

    setState(() {
      AppData.menuItems.add({
        "name": name,
        "price": price,
        "category": selectedCategory,
      });
    });

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
                  onPressed: () {
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

                    setState(() {
                      AppData.menuItems[index] = {
                        "name": newName,
                        "price": newPrice,
                        "category": category,
                      };
                    });

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

  void deleteItem(int index) {
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
              onPressed: () {
                setState(() {
                  AppData.menuItems.removeAt(index);
                });

                Navigator.pop(context);
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
                .where((category) => category != "Uncategorized")
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
                  .where((category) => category != "Uncategorized")
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

            ...[
              ...AppData.categories.where(
                (category) => category != "Uncategorized",
              ),
              "Uncategorized",
            ].map((category) {
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
                    final index = AppData.menuItems.indexOf(item);

                    return Card(
                      child: ListTile(
                        title: Text(item["name"]),
                        subtitle: Text("₹${item["price"]}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => editItem(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteItem(index),
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
