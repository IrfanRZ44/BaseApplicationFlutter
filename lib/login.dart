// lib/login.dart

import 'dart:convert'; // For base64 encoding
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'main_screen.dart';
import 'database_helper.dart';

// Stateful widget for login screen
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); // Key to validate form

  // Controllers to capture user input
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _imeiController = TextEditingController();
  List<Map<String, dynamic>> _estates = [];
  String? _selectedEstateName;

  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadEstates();
  }

  Future<void> _loadEstates() async {
    final estatesFromDb = await DatabaseHelper().getEstates();
    setState(() {
      _estates = [
        {'code': '', 'name': 'Choose Estate'},
        ...estatesFromDb.map((e) => {
          'code': e['estate_code'],
          'name': e['estate_name'],
        })
      ];

      _selectedEstateName = _estates[0]['name'];
    });
  }

  // Function to handle form submission
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Validate estate selection
      if (_selectedEstateName == null ||
          _selectedEstateName!.isEmpty ||
          _selectedEstateName == 'Choose Estate') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Validation Error"),
            content: const Text("Please choose an estate."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
        return;
      }

      final loadingMessage = ValueNotifier<String>("Logging in...");
      _showLoadingDialog(loadingMessage);

      try {
        final estateCode = await DatabaseHelper().getEstateCodeByName(_selectedEstateName!);

        final response = await ApiService.login(
          username: _usernameController.text,
          password: base64Encode(utf8.encode(_passwordController.text)),
          estate: estateCode ?? '',
          imei: _imeiController.text,
          apkVersion: "1.0.0",
          clientId: "your_client_id",
          clientSecret: "your_client_secret",
        );

        if (response.success) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("is_logged_in", true);
          await prefs.setString("username", _usernameController.text);

          // ✅ Insert m_tph
          final tphList = response.data['m_tph'] as List<dynamic>;
          loadingMessage.value = "Saving TPH data...";
          for (var i = 0; i < tphList.length; i++) {
            await DatabaseHelper().insertTph(tphList[i]);
            if (i % 100 == 0 || i == tphList.length - 1) {
              loadingMessage.value = "Saving TPH... ${i + 1}/${tphList.length}";
            }
          }

          // ✅ Insert m_pemanen
          final pemanenList = response.data['m_pemanen'] as List<dynamic>;
          loadingMessage.value = "Saving pemanen data...";
          for (var i = 0; i < pemanenList.length; i++) {
            await DatabaseHelper().insertPemanen(pemanenList[i]);
            if (i % 100 == 0 || i == pemanenList.length - 1) {
              loadingMessage.value = "Saving pemanen... ${i + 1}/${pemanenList.length}";
            }
          }

          // ✅ Insert m_block
          final blockList = response.data['m_block'] as List<dynamic>;
          loadingMessage.value = "Saving block data...";
          for (var i = 0; i < blockList.length; i++) {
            await DatabaseHelper().insertBlock(blockList[i]);
            if (i % 100 == 0 || i == blockList.length - 1) {
              loadingMessage.value = "Saving block... ${i + 1}/${blockList.length}";
            }
          }

          // ✅ Insert m_divisi
          final divisiList = response.data['m_divisi'] as List<dynamic>;
          loadingMessage.value = "Saving divisi data...";
          for (var i = 0; i < divisiList.length; i++) {
            await DatabaseHelper().insertDivisi(divisiList[i]);
            if (i % 100 == 0 || i == divisiList.length - 1) {
              loadingMessage.value = "Saving divisi... ${i + 1}/${divisiList.length}";
            }
          }

          // ✅ Close loading dialog safely
          Future.microtask(() {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });

          Navigator.of(context).pop(); // Close loading dialog
          Future.delayed(Duration.zero, () {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          });
        } else {
          // ❌ Login failed, close dialog and show error
          Future.microtask(() {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      } catch (e) {
        // ❗ Unexpected error (network, parsing, etc.)
        Future.microtask(() {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showLoadingDialog(ValueNotifier<String> messageNotifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: messageNotifier,
                  builder: (context, value, _) => Text(value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/ic_palm.png', height: 100),
                    const SizedBox(height: 16),
                    const Text(
                      "Welcome Back",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter username' : null,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter password' : null,
                    ),
                    const SizedBox(height: 16),

                    // Estate
                    DropdownButtonFormField<String>(
                      value: (_selectedEstateName != null && _selectedEstateName!.isNotEmpty)
                          ? _selectedEstateName
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Estate',
                        border: OutlineInputBorder(),
                      ),
                      items: _estates.map<DropdownMenuItem<String>>((estate) {
                        return DropdownMenuItem<String>(
                          value: estate['name'] ?? '',
                          child: Text(
                            estate['name'] ?? '',
                            style: TextStyle(color: Colors.black), // 👈 Ensure visible text
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEstateName = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty || value == 'Choose Estate') {
                          return 'Please choose estate';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // IMEI
                    TextFormField(
                      controller: _imeiController,
                      decoration: const InputDecoration(
                        labelText: 'IMEI',
                        prefixIcon: Icon(Icons.perm_identity),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter IMEI' : null,
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
