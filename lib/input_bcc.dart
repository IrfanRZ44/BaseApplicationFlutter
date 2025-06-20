import 'package:flutter/services.dart';
import 'qr_scan_page.dart';
import 'package:geolocator/geolocator.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

import 'dart:io'; // For File and Directory handling
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:image_picker/image_picker.dart'; // To open the camera and pick images
import 'package:flutter_image_compress/flutter_image_compress.dart'; // To compress the image
import 'package:path/path.dart' as path; // To work with file paths
import 'package:permission_handler/permission_handler.dart'; // To request runtime permissions
import 'package:device_info_plus/device_info_plus.dart'; // To detect Android OS version

class InputBCC extends StatefulWidget {
  const InputBCC({super.key});

  @override
  State<InputBCC> createState() => _InputBCCState();
}

class _InputBCCState extends State<InputBCC> {
  bool scoutBunch = false;
  bool floodBlock = false;
  bool noHarvesters = false;
  String? tphValue;
  String? bccValue;
  String? blockValue;
  String? _selectedDivisiName;
  String? _selectedPemanenName;
  String? gpsLocation;
  String? lat;
  String? long;
  File? _capturedImage;
  String? _imagePath;

  List<String> _divisi = [''];
  List<String> _pemanen = [''];

  final TextEditingController blockController = TextEditingController();
  final TextEditingController ripeController = TextEditingController();
  final TextEditingController underRipeController = TextEditingController();
  final TextEditingController unripeController = TextEditingController();
  final TextEditingController abnormalController = TextEditingController();
  final TextEditingController emptyBunchesController = TextEditingController();
  final TextEditingController looseFruitController = TextEditingController();
  final TextEditingController longStalkController = TextEditingController();
  final TextEditingController parthenoController = TextEditingController();
  final TextEditingController bunchesPaidController = TextEditingController();

  String hkStatus = "HK";

  @override
  void initState() {
    super.initState();
    _loadDivisi();
    _loadPemanen();

    // Add listeners to relevant fields
    ripeController.addListener(_updateBunchesPaid);
    underRipeController.addListener(_updateBunchesPaid);
    unripeController.addListener(_updateBunchesPaid);
    abnormalController.addListener(_updateBunchesPaid);
    emptyBunchesController.addListener(_updateBunchesPaid);
    longStalkController.addListener(_updateBunchesPaid);
    parthenoController.addListener(_updateBunchesPaid);
  }

  Future<void> _loadDivisi() async {
    final divisiFromDb = await DatabaseHelper().getDivisi();

    setState(() {
      print(divisiFromDb);
      _divisi = divisiFromDb;
    });
  }

  Future<void> _loadPemanen() async {
    final pemanenFromDb = await DatabaseHelper().getPemanen();

    setState(() {
      print(pemanenFromDb);
      _pemanen = pemanenFromDb;
    });
  }

  void _updateBunchesPaid() {
    int parse(String text) => int.tryParse(text) ?? 0;

    final total = parse(ripeController.text) +
        parse(underRipeController.text) +
        parse(unripeController.text) +
        parse(abnormalController.text) +
        parse(emptyBunchesController.text) +
        parse(longStalkController.text) +
        parse(parthenoController.text);

    bunchesPaidController.text = total.toString();
  }

  Future<void> _navigateBack() async {
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _showDialogInputTPHorBCC(BuildContext context, String title) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Input $title",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _buildDialogTPHorBCCContent(context, title),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildDialogTPHorBCCContent(BuildContext context, String title) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Input $title"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("Scan QR"),
            onPressed: () {
              Navigator.of(context).pop();
              _simulateScanQrCode(title);
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Input Manually"),
            onPressed: () {
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 200), () {
                _showManualInputDialog(context, title);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog(BuildContext context, String title) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Enter $title"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Enter $title code",
              prefixIcon: Icon(Icons.numbers),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {

                final input = controller.text.trim();
                if (input.isNotEmpty) {
                  setState(() {
                    if(title == "TPH"){
                      tphValue = input;
                    }
                    else{
                      bccValue = input;
                    }
                  });

                  // ✅ Fetch block from DB
                  final block = await DatabaseHelper().getBlockFromTPH(input, _selectedDivisiName ?? "");
                  setState(() {
                    blockValue = block ?? "";
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text("OK"),
            ),


          ],
        );
      },
    );
  }

  void _simulateScanQrCode(String title) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScanPage(
          onScanned: (value) async {
            setState(() {
              if(title == "TPH"){
                tphValue = value;
              }
              else{
                bccValue = value;
              }
            });

            // ✅ Only fetch block if TPH is scanned
            if (title == "TPH") {
              final block = await DatabaseHelper().getBlockFromTPH(value, _selectedDivisiName ?? "");
              setState(() {
                blockValue = block ?? "Block not found";
              });
            }
          },
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        tphValue = result; // Set scanned QR result
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  Future<void> _getLocation() async {
    // Request permission
    var permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        setState(() {
          gpsLocation = "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get location: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
    }
  }

  // Function to capture image using camera and save it to Downloads folder
  Future<void> _captureImage() async {
    // Get the Android OS version at runtime
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;

    // Request camera permission
    var cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      // Show a message if camera permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera permission denied")),
      );
      return;
    }

    // Check storage permission depending on Android version
    bool storageGranted = false;
    if (sdkInt >= 30) {
      // For Android 11 and above, request MANAGE_EXTERNAL_STORAGE
      var storageStatus = await Permission.manageExternalStorage.request();
      storageGranted = storageStatus.isGranted;
    } else {
      // For Android 10 and below, request standard storage permission
      var storageStatus = await Permission.storage.request();
      storageGranted = storageStatus.isGranted;
    }

    // Show error message if storage permission is denied
    if (!storageGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      return;
    }

    // Open camera to capture an image
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    // If an image is successfully captured
    if (pickedFile != null) {
      final tempImage = File(pickedFile.path); // Get the image as a File

      // Define the custom folder where image will be saved
      final String customFolder = "/storage/emulated/0/Download/eBCC_Images";

      // Create the folder if it doesn't exist
      await Directory(customFolder).create(recursive: true);

      // Create full path to save the compressed image
      final String fileName = "ebcc_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String savePath = path.join(customFolder, fileName);

      // Compress the image and save to the defined path
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        tempImage.absolute.path, // Source path
        savePath,                // Destination path
        quality: 75,             // Image quality (1 to 100)
      );

      // If compression and saving is successful, update the UI
      if (compressedFile != null) {
        setState(() {
          _capturedImage = File(compressedFile.path); // Store image for display
          _imagePath = compressedFile.path;           // Store saved file path
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create eBCC")),
      body:
      SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    ElevatedButton(
                      // onPressed: () => _showDialogInputTPHorBCC(context, "TPH"),
                      onPressed: () {
                        if (_selectedDivisiName == null || _selectedDivisiName!.isEmpty) {
                          // ❌ Divisi not selected
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a division first."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // ✅ Divisi selected, proceed
                        _showDialogInputTPHorBCC(context, "TPH");
                      },
                      child: const Text("SCAN TPH"),
                    ),
                    const SizedBox(height: 4),
                    Text(tphValue ?? '-'),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _getLocation,
                      child: const Text('SCAN LOCATION'),
                    ),
                    const SizedBox(height: 4),
                    Text(gpsLocation ?? "-"),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showDialogInputTPHorBCC(context, "BCC"),
                      child: const Text("SCAN BCC"),
                    ),
                    const SizedBox(height: 4),
                    Text(bccValue ?? '-'),
                  ],
                ),
              ],
            ),

            Row(
              children: [
                Checkbox(value: scoutBunch, onChanged: (val) => setState(() => scoutBunch = val!)),
                const Text("Scout Bunch"),
                Checkbox(value: floodBlock, onChanged: (val) => setState(() => floodBlock = val!)),
                const Text("Flood Block"),
                Checkbox(
                  value: noHarvesters,
                  onChanged: (val) {
                    setState(() {
                      noHarvesters = val!;
                      if (noHarvesters) {
                        _selectedPemanenName = null; // Optional: clear selection
                      }
                    });
                  },
                ),
                const Text("No Harvesters"),
              ],
            ),

            // Show Status HK only if floodBlock is checked
            if (floodBlock)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Status HK: "),
                  Row(
                    children: [
                      Radio(
                        value: "HK",
                        groupValue: hkStatus,
                        onChanged: (val) => setState(() => hkStatus = val!),
                      ),
                      const Text("HK"),
                      Radio(
                        value: "Tonnage",
                        groupValue: hkStatus,
                        onChanged: (val) => setState(() => hkStatus = val!),
                      ),
                      const Text("Tonnage"),
                    ],
                  )
                ],
              ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Division: "),
                const SizedBox(width: 5),
                const Text("Block: "),
                SizedBox(
                    width: 150, // <-- set your desired width here
                    child: const Text("Harvesters: ")
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedDivisiName,
                  hint: const Text("Choose Division"),
                  items: _divisi.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedDivisiName = val),
                ),
                Text(blockValue ?? ''),
                IgnorePointer(
                  ignoring: noHarvesters, // disables interaction
                  child: Opacity(
                    opacity: noHarvesters ? 0.5 : 1.0, // visual feedback
                    child: DropdownButton<String>(
                      value: _selectedPemanenName,
                      hint: const Text("Choose Harvester"),
                      items: _pemanen
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedPemanenName = val),
                    ),
                  ),
                ),
              ],
            ),

            Column(
              children: [
                const Divider(height: 20),

                Row(
                  children: [
                    Expanded(child: _buildEditableRow("Ripe", ripeController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEditableRow("Under Ripe", underRipeController)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildEditableRow("Unripe", unripeController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEditableRow("Abnormal Bunches", abnormalController)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildEditableRow("Empty Bunches", emptyBunchesController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEditableRow("Loose Fruit (Kg)", looseFruitController)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildEditableRow("Long Stalk", longStalkController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEditableRow("Partheno Carp", parthenoController)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200, // or adjust as needed
                      child: _buildEditableRow("Bunches Paid", bunchesPaidController, editable: false),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: GestureDetector(
                onTap: _captureImage,
                child: _capturedImage != null
                    ? Image.file(_capturedImage!, width: 150, height: 150, fit: BoxFit.cover)
                    : Icon(Icons.camera_alt, size: 150, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _navigateBack, child: const Text("CANCEL")),
                ElevatedButton(
                  onPressed: () async {
                    // 1. Validate mandatory fields
                    if ((_selectedDivisiName ?? '').isEmpty) {
                      _showError("Please select Divisi");
                      return;
                    }
                    if ((tphValue ?? '').isEmpty) {
                      _showError("Please scan/input TPH");
                      return;
                    }
                    if ((bccValue ?? '').isEmpty) {
                      _showError("Please scan/input BCC");
                      return;
                    }
                    if (!noHarvesters && (_selectedPemanenName ?? '').isEmpty) {
                      _showError("Please enter Harvester name");
                      return;
                    }
                    if ((gpsLocation ?? '').isEmpty) {
                      _showError("Location not detected");
                      return;
                    }
                    if ((_imagePath ?? '').isEmpty) {
                      _showError("Please capture/upload picture");
                      return;
                    }

                    // 2. Check if user entered only loose fruit
                    bool hasAnyBunch = [
                      ripeController,
                      underRipeController,
                      unripeController,
                      abnormalController,
                      emptyBunchesController,
                      longStalkController,
                      parthenoController
                    ].any((c) => (int.tryParse(c.text) ?? 0) > 0);

                    final flagBrondolan = !hasAnyBunch && (int.tryParse(looseFruitController.text) ?? 0) > 0 ? "1" : "0";

                    if ((gpsLocation ?? '').isNotEmpty && gpsLocation!.contains(',')) {
                      final parts = gpsLocation!.split(',');
                      lat = parts[0].trim();
                      long = parts[1].trim();
                    } else {
                      lat = '';
                      long = '';
                    }

                    // 3. Save data
                    final db = await DatabaseHelper().db;
                    await db.insert('t_input', {
                      'oph_generate': '', // set if you have
                      'code_tph': tphValue,
                      'code_bcc': bccValue,
                      'tanggal': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'divisi': _selectedDivisiName,
                      'block': blockValue ?? '',
                      'pemanen': _selectedPemanenName,
                      'matang': ripeController.text,
                      'kurang_matang': underRipeController.text,
                      'abnormal': abnormalController.text,
                      'tandan_kosong': emptyBunchesController.text,
                      'brondolan': looseFruitController.text,
                      'tangkai_panjang': longStalkController.text,
                      'jumlah_tandan': bunchesPaidController.text,
                      'partheno': parthenoController.text,
                      'status_load': '0',
                      'picture_tph': _imagePath,
                      'lat': lat,
                      'long': long,
                      'flag_brondolan': flagBrondolan,
                      'flag_gps_location': '1',
                      'status_hk': hkStatus, // set if needed
                    });

                    _showSuccess("Data saved successfully.");
                    await _navigateBack();
                  },
                  child: const Text("SAVE"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller, {bool editable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.green)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              readOnly: !editable,
              keyboardType: TextInputType.number,
              inputFormatters: editable
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : [],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
              style: TextStyle(
                color: editable ? Colors.black : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    ripeController.dispose();
    underRipeController.dispose();
    unripeController.dispose();
    abnormalController.dispose();
    emptyBunchesController.dispose();
    looseFruitController.dispose();
    longStalkController.dispose();
    parthenoController.dispose();
    bunchesPaidController.dispose();
    super.dispose();
  }
}