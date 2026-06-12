import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  // ── Category actions ────────────────────────────────────────────────────────

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Edit Category",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Category Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.brown.shade400),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String newCategory = controller.text.trim();
                if (newCategory.isEmpty) return;

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
                      oldCategory: oldCategory,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Category",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Move all items to Uncategorized and delete '$category'?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.brown.shade400),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              onPressed: () async {
                for (var item in AppData.menuItems) {
                  if (item["category"] == category) {
                    await DatabaseHelper.instance.updateMenuItem(
                      oldName: item["name"],
                      oldCategory: category,
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

  // ── Item actions ─────────────────────────────────────────────────────────────

  Future<void> addItem() async {
    String name = itemController.text.trim();
    double? price = double.tryParse(priceController.text.trim());

    if (name.isEmpty || selectedCategory == null) return;

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Edit Item",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                      initialValue: category,
                      decoration: const InputDecoration(labelText: "Category"),
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
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.brown.shade400),
                  ),
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

                    final originalName = item["name"] as String;
                    final originalCategory = item["category"] as String;

                    bool exists = AppData.menuItems.any(
                      (menuItem) =>
                          !(menuItem["name"] == originalName &&
                              menuItem["category"] == originalCategory) &&
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
                      oldCategory: item["category"],
                      name: newName,
                      price: newPrice,
                      category: category,
                    );

                    await loadData();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Item",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.brown.shade400),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              onPressed: () async {
                await DatabaseHelper.instance.deleteMenuItem(
                  AppData.menuItems[index]["name"],
                  AppData.menuItems[index]["category"],
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text(
          "Menu Management",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.category_outlined), text: "Categories"),
            Tab(icon: Icon(Icons.restaurant_menu_outlined), text: "Items"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoriesTab(
            categoryController: categoryController,
            onAdd: addCategory,
            onEdit: editCategory,
            onDelete: deleteCategory,
          ),
          _ItemsTab(
            itemController: itemController,
            priceController: priceController,
            selectedCategory: selectedCategory,
            onCategoryChanged: (val) => setState(() => selectedCategory = val),
            onAdd: addItem,
            onEdit: editItem,
            onDelete: deleteItem,
          ),
        ],
      ),
    );
  }
}

// ── Categories Tab ───────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final TextEditingController categoryController;
  final VoidCallback onAdd;
  final void Function(String) onEdit;
  final void Function(String) onDelete;

  const _CategoriesTab({
    required this.categoryController,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final displayCategories = AppData.categories
        .where((c) => c != AppData.uncategorized)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Add category form ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "New Category",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    hintText: "Enter category name",
                    hintStyle: TextStyle(color: Colors.brown.shade300),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Add Category",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Category list ────────────────────────────────────────────────
          if (displayCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48,
                      color: Colors.brown.shade200,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No categories yet",
                      style: TextStyle(
                        color: Colors.brown.shade300,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "${displayCategories.length} categor${displayCategories.length == 1 ? 'y' : 'ies'}",
                style: TextStyle(fontSize: 13, color: Colors.brown.shade400),
              ),
            ),
            ...displayCategories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.brown.shade100),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.label_outline,
                        size: 18,
                        color: Colors.brown.shade600,
                      ),
                    ),
                    title: Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      "${AppData.menuItems.where((i) => i["category"] == category).length} item(s)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown.shade400,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionBtn(
                          icon: Icons.edit_outlined,
                          color: Colors.brown.shade600,
                          bg: Colors.brown.shade50,
                          onTap: () => onEdit(category),
                        ),
                        const SizedBox(width: 6),
                        _actionBtn(
                          icon: Icons.delete_outline,
                          color: Colors.red.shade400,
                          bg: Colors.red.shade50,
                          onTap: () => onDelete(category),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ── Items Tab ────────────────────────────────────────────────────────────────

class _ItemsTab extends StatelessWidget {
  final TextEditingController itemController;
  final TextEditingController priceController;
  final String? selectedCategory;
  final void Function(String?) onCategoryChanged;
  final VoidCallback onAdd;
  final void Function(int) onEdit;
  final void Function(int) onDelete;

  const _ItemsTab({
    required this.itemController,
    required this.priceController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final addableCategories = AppData.categories
        .where((c) => c != AppData.uncategorized)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Add item form ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "New Item",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: itemController,
                  decoration: InputDecoration(
                    hintText: "Item name",
                    hintStyle: TextStyle(color: Colors.brown.shade300),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Price (₹)",
                    hintStyle: TextStyle(color: Colors.brown.shade300),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    hintText: "Select category",
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: addableCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: onCategoryChanged,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Add Item",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Items grouped by category ────────────────────────────────────
          ...AppData.categories.map((category) {
            final items = AppData.menuItems
                .where((item) => item["category"] == category)
                .toList();

            if (items.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
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
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${items.length} item${items.length == 1 ? '' : 's'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown.shade400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Item cards
                ...items.map((item) {
                  final globalIndex = AppData.menuItems.indexWhere(
                    (m) =>
                        m["name"] == item["name"] &&
                        m["category"] == item["category"],
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.brown.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        title: Text(
                          item["name"],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          "₹${item["price"]}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.brown.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionBtn(
                              icon: Icons.edit_outlined,
                              color: Colors.brown.shade600,
                              bg: Colors.brown.shade50,
                              onTap: () => onEdit(globalIndex),
                            ),
                            const SizedBox(width: 6),
                            _actionBtn(
                              icon: Icons.delete_outline,
                              color: Colors.red.shade400,
                              bg: Colors.red.shade50,
                              onTap: () => onDelete(globalIndex),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
