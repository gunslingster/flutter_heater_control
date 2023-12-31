import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bluetooth_app/controllers/bluetooth_controller.dart';
import 'package:get/get.dart';
import 'control_page.dart';
import 'package:flutter_bluetooth_app/device_names.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
                  return const Center(child: Text("Permissions not granted."));
                }
              } else {
                // Still loading, show a loading indicator
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
    );
  }

Future<PermissionStatus> _requestPermissions() async {
  // Request Bluetooth and Location permissions using the permission_handler package
  final permissions = <Permission>[
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ];

  // Request permissions based on platform
  final permissionStatusList = await permissions.request();

  // Check the status of each permission
  if (Platform.isAndroid) {
    // On Android, check Bluetooth permissions based on Android version
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int version = androidInfo.version.sdkInt;
    if (version >= 31) {
      return (permissionStatusList[Permission.bluetoothScan]?.isGranted ?? false) &&
          (permissionStatusList[Permission.bluetoothConnect]?.isGranted ?? false)
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    } else {
      return (permissionStatusList[Permission.bluetooth]?.isGranted ?? false) &&
          (permissionStatusList[Permission.location]?.isGranted ?? false)
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    }
  } else if (Platform.isIOS) {
    // // On iOS, check Bluetooth and Location permissions
    // return (permissionStatusList[Permission.bluetoothScan]?.isGranted ?? false) &&
    //     (permissionStatusList[Permission.bluetoothConnect]?.isGranted ?? false) &&
    //     (permissionStatusList[Permission.location]?.isGranted ?? false)
    //     ? PermissionStatus.granted
    //     : PermissionStatus.denied;
    return PermissionStatus.granted;
  } else {
    // For other platforms, consider handling permissions accordingly
    return PermissionStatus.denied;
  }
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
                      future: getCustomDeviceName(device.remoteId.toString()),
                      builder: (context, deviceNameSnapshot) {
                        String displayName = device.localName.isNotEmpty
                            ? device.localName
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
                              child: Text(BluetoothConnectionState ==
                                      device.connectionState
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
