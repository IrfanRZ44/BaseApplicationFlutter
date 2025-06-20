import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'dart:io';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> _items = [];
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    final data = await DatabaseHelper().getBCC();
    setState(() => _items = data);
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper().deleteItem(id);
    await _refreshList();
  }

  Future<void> _logout() async {
    // Clear local database tables
    await DatabaseHelper().clearAllTables();

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    // Navigate to login screen
    // Navigator.pushReplacementNamed(context, '/login');
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out and remove all saved data?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Dismiss dialog
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _logout(); // Call your logout logic
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateInputBCC() async {
    Navigator.pushReplacementNamed(context, '/input_bcc');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simple CRUD App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _confirmLogout,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _navigateInputBCC,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text("Input BCC"),
            ),
            const SizedBox(height: 12),
            // Expanded(
            //   child: _items.isEmpty
            //       ? const Center(child: Text("No items yet."))
            //       : ListView.builder(
            //     itemCount: _items.length,
            //     itemBuilder: (context, index) {
            //       final item = _items[index];
            //       return Card(
            //         margin: const EdgeInsets.symmetric(vertical: 6),
            //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            //         elevation: 2,
            //         child: ListTile(
            //           title: Text(item['code_bcc']),
            //           trailing: IconButton(
            //             icon: const Icon(Icons.delete, color: Colors.red),
            //             onPressed: () => _deleteItem(item['id']),
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text("No items yet."))
                  : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dates
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("No BCC : ${item['code_bcc']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Harvest Date:\n${item['tanggal'] ?? '-'}"),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Confirm Delete"),
                                      content: const Text("Are you sure you want to delete this item?"),
                                      actions: [
                                        TextButton(
                                          child: const Text("Cancel"),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                        TextButton(
                                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                          onPressed: () {
                                            Navigator.of(context).pop(); // close the dialog
                                            _deleteItem(item['id']); // perform delete
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),

                          // Truck Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Division\n${item['divisi']}"),
                              Text("Block\n${item['block']}"),
                              Text("TPH\n${item['code_tph']}"),
                              Text("Harvesters\n${item['pemanen'] ?? ''}"),
                            ],
                          ),
                          const Divider(),

                          // Fruit Conditions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCount("Ripe", item['matang']),
                              _buildCount("Under Ripe", item['kurang_matang']),
                              _buildCount("Unripe", '0'),
                              _buildCount("Abnormal", item['abnormal']),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Bottom Conditions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCount("Empty Bunches", item['tandan_kosong']),
                              _buildCount("Loose Fruit (Kg)", item['brondolan']),
                              _buildCount("Stem Length", item['tangkai_panjang']),
                              _buildCount("Partheno", item['partheno']),
                            ],
                          ),
                          const Divider(),

                          // Bunch Quantity
                          // Inside Center in your Card
                          Center(
                            child: Column(
                              children: [
                                const Text("Bunch Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text("${item['jumlah_tandan']}", style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 12),

                                _buildImage(item['picture_tph']), // <-- use the current item's path
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? path) {
    print('Loading image from: $path');

    if (path == null || path.isEmpty) {
      return const Text("No image available");
    }

    final file = File(path);
    if (!file.existsSync()) {
      return const Text("Image not found");
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        file,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }


  Widget _buildCount(String label, dynamic value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text("${value ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}