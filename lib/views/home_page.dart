import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bluetooth_app/controllers/bluetooth_controller.dart';
import 'package:get/get.dart';
import 'control_page.dart';
import 'package:flutter_bluetooth_app/device_names.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text('Infratech Heater Control',
                style: TextStyle(color: Colors.white))),
        backgroundColor: Color(0xFFef4034),
      ),
      body: GetBuilder<BluetoothController>(
        init: BluetoothController(),
        builder: (controller) {
          return FutureBuilder<PermissionStatus>(
            // Request permissions
            future: _requestPermissions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData && snapshot.data!.isGranted) {
                  // Permissions granted, return your main UI
                  return _buildMainUI(controller);
                } else {
                  // Permissions denied, show an error message or another UI
                  return Center(child: Text("Permissions not granted."));
                }
              } else {
                // Still loading, show a loading indicator
                return Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
    );
  }

  Future<PermissionStatus> _requestPermissions() async {
    // Request Bluetooth permissions
    final btStatus = await Permission.bluetooth.request();
    // Request Location permissions
    final locationStatus = await Permission.location.request();
    return btStatus.isGranted && locationStatus.isGranted
        ? PermissionStatus.granted
        : PermissionStatus.denied;
  }

  Widget _buildMainUI(BluetoothController controller) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20 * 3),
          Center(
            child: ElevatedButton(
              onPressed: controller.scanDevices,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                minimumSize: const Size(350, 55),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              child: const Text(
                'Scan',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<ScanResult>>(
            stream: controller.scanResults,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final device = snapshot.data![index].device;
                    return FutureBuilder<String?>(
                      future: getCustomDeviceName(device.id.toString()),
                      builder: (context, deviceNameSnapshot) {
                        String displayName = device.name.isNotEmpty
                            ? device.name
                            : 'Unknown Device';

                        if (deviceNameSnapshot.hasData &&
                            deviceNameSnapshot.data != null) {
                          displayName = deviceNameSnapshot.data!;
                        }

                        return Card(
                          elevation: 2,
                          child: ListTile(
                            onTap: () {},
                            title: Text(displayName),
                            subtitle: Text(displayName),
                            trailing: TextButton(
                              onPressed: () {
                                controller.connectToDevice(device);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ControlPage(device: device),
                                  ),
                                );
                              },
                              child: Text(
                                  BluetoothDeviceState.connected == device.state
                                      ? 'Connected'
                                      : 'Connect'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              } else {
                return const Center(child: Text('No devices found'));
              }
            },
          ),
        ],
      ),
    );
  }
}
