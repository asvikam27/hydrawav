import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ble/presentation/providers/ble_scan_provider.dart';

class ManualEntrySheet extends ConsumerStatefulWidget {
  final Future<void> Function(String, String) onSubmit;
  final VoidCallback onInitializeDiscovery;

  const ManualEntrySheet({
  super.key,
  required this.onSubmit,
  required this.onInitializeDiscovery,
});

  @override
  ConsumerState<ManualEntrySheet> createState() =>
      _ManualEntrySheetState();
}

class _ManualEntrySheetState
    extends ConsumerState<ManualEntrySheet> {

  int selectedTab = 1;
  int selectedFilter = 1;

  final TextEditingController macController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    macController.addListener(validate);
    nameController.addListener(validate);
  }

  void validate() {
  final mac = macController.text.replaceAll(":", "");
  final name = nameController.text.trim();

  setState(() {
    isValid = name.isNotEmpty && mac.length == 12;
  });
}

  bool isValidMac(String mac) {
  final cleaned = mac.replaceAll(":", "");
  return cleaned.length == 12;
}

  String formatMac(String input) {
    input = input.replaceAll(":", "").toUpperCase();

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      buffer.write(input[i]);
      if ((i % 2 == 1) && i != input.length - 1) {
        buffer.write(":");
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [

          /// HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2A32),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Register New Hardware",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                )
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// TABS
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildTab("AUTO SCAN (BLE)", 0),
                _buildTab("MANUAL ENTRY", 1),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: selectedTab == 1
                ? _buildManualEntry()
                : _buildAutoScan(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 AUTO SCAN
  Widget _buildAutoScan() {
    final scanResults = ref.watch(bleScanResultsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          /// FILTER TOGGLE
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedFilter = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedFilter == 0
                            ? const Color(0xFF0F2A32)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          "Hydrawav3 Devices Only",
                          style: TextStyle(
                            color: selectedFilter == 0
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedFilter = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedFilter == 1
                            ? const Color(0xFF0F2A32)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          "All Devices",
                          style: TextStyle(
                            color: selectedFilter == 1
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// BUTTON
          ElevatedButton(
            onPressed: () {
  _showScanDialog(context);
},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2A32),
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text("INITIALIZE DISCOVERY"),
          ),

          const SizedBox(height: 16),

          /// RESULTS
          Expanded(
            child: scanResults.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return Center(
                    child: Text(
                      "No devices detected.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (_, i) {
  final d = devices[i];

  final rawName = d.device.platformName.trim();

String name;

if (rawName.isNotEmpty &&
    rawName != "(no name)") {
  name = rawName;
} else {
  name =
      "Unknown or Unsupported Device (${formatMac(d.device.remoteId.str)})";
}


  return ListTile(
    leading: const Icon(Icons.bluetooth),
    title: Text(name),
    subtitle: Text(d.device.remoteId.str),
  );
},
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text("Error: $e"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
  return SingleChildScrollView(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// WARNING BOX
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Manual entry is restricted to verified clinical MAC identifiers only.",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// DEVICE NAME
        const Text(
          "Device Name",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),

        TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "e.g. Clinic_Device_01",
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// MAC IDENTIFIER
        const Text(
          "MAC Identifier",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),

        TextField(
          controller: macController,
          style: const TextStyle(color: Colors.black),
          onChanged: (value) {
            final formatted = formatMac(value);
            macController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(
                offset: formatted.length,
              ),
            );
          },
          decoration: InputDecoration(
            hintText: "00:00:00:00:00:00",
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        const SizedBox(height: 30),

        /// REGISTER BUTTON
SizedBox(
  width: double.infinity,
  height: 58,
  child: ElevatedButton(
    onPressed: () {
  if (!isValid) return;

  final name = nameController.text.trim();
  final mac = macController.text.trim();

  widget.onSubmit(name, mac);

},
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: isValid
          ? const Color(0xFF0F2A32)
          : const Color(0xFFB8BDC2),
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFB8BDC2),
      disabledForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    child: const Text(
      "REGISTER ASSET",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Colors.white,
      ),
    ),
  ),
),

        const SizedBox(height: 40),
      ],
    ),
  );
}

  void _showScanDialog(BuildContext context) {
  ref.read(startScanProvider)();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {


          final scanResults =
    ref.watch(bleScanResultsProvider);

          return Dialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 420,
              child: Column(
                children: [

                  const Text(
                    "Scanning for devices",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: scanResults.when(
                      data: (devices) {

                        if (devices.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (_, i) {

                            final d = devices[i];

                            final rawName =
                                d.device.platformName.trim();

                            final mac =
                                formatMac(d.device.remoteId.str);

                            String name;

                            if (rawName.isNotEmpty &&
                                rawName != "(no name)") {
                              name = rawName;
                            } else {
                              name =
                                  "Unknown or Unsupported Device";
                            }

                            return ListTile(
                              leading: const Icon(
                                Icons.bluetooth,
                                color: Colors.white,
                              ),

                              title: Text(
                                "$name ($mac)",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),

                              onTap: () {
                                nameController.text = name;
                                macController.text = mac;

                                Navigator.pop(context);

                                setState(() {});
                              },
                            );
                          },
                        );
                      },

                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                        ),
                      ),

                      error: (e, _) => Center(
                        child: Text(
                          e.toString(),
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
    }