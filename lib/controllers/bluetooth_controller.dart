import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';

class BluetoothController extends GetxController {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>();

  Future<void> scanDevices() async {
    // Start scanning
    flutterBlue.startScan(timeout: const Duration(seconds: 5));
    // Listen to scan results
    await for (var results in flutterBlue.scanResults) {
      // Print all devices' information for debugging
      for (var result in results) {
        print('Device: ${result.device.name}');
        print('RSSI: ${result.rssi}');
        for (var uuid in result.advertisementData.serviceUuids) {
          print('Service UUID: $uuid');
        }
        print('------------------------');
      }
    }

    // Listen to scan results
    await for (var results in flutterBlue.scanResults) {
      // Filter devices by service UUID containing 'CCCC'
      var filteredResults = results.where((result) => result
          .advertisementData.serviceUuids
          .any((uuid) => uuid.toLowerCase().contains('cccc')));

      // Add filtered results to the stream controller
      _scanResultsController.add(filteredResults.toList());
    }

    // Stop scanning
    flutterBlue.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;
  // Future scanDevices() async {
  //   // Start scanning
  //   flutterBlue.startScan(timeout: const Duration(seconds: 5));

  //   // Listen to scan results
  //   var subscription = flutterBlue.scanResults.listen((results) {
  //     // do something with scan results
  //     for (ScanResult r in results) {
  //       print('${r.device.name} found! rssi: ${r.rssi}');
  //     }
  //   });
  //   print('subscription: $subscription');
  //   // Stop scanning
  //   flutterBlue.stopScan();
  // }

  // // scan result stream
  // Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;

  // connect to device
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
  }

  // disconnect from device
  Future<void> disconnectFromDevice() async {
    List<BluetoothDevice> connectedDevices = await flutterBlue.connectedDevices;
    for (BluetoothDevice device in connectedDevices) {
      await device.disconnect();
    }
  }

  // Function to get the currently connected device
  Future<BluetoothDevice?> getConnectedDevice() async {
    List<BluetoothDevice> connectedDevices = await flutterBlue.connectedDevices;
    if (connectedDevices.isNotEmpty) {
      return connectedDevices.first;
    } else {
      return null;
    }
  }

  // Future<void> writeIntensityCharacteristic(int value) async {
  //   BluetoothDevice? device = await getConnectedDevice();
  //   if (device != null) {
  //     List<BluetoothService> services = await device.discoverServices();
  //     for (BluetoothService service in services) {
  //       print(service.uuid.toString());
  //       if (service.uuid.toString().contains("cccc")) {
  //         print(service.uuid.toString());
  //         List<BluetoothCharacteristic> characteristics =
  //             service.characteristics;
  //         for (BluetoothCharacteristic characteristic in characteristics) {
  //           print(characteristic.toString());
  //           if (characteristic.uuid.toString() ==
  //               "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
  //             String stringValue = value.toString();
  //             List<int> valueBytes = stringValue.codeUnits;
  //             await characteristic.write(valueBytes);
  //             break; // Exit the loop after writing
  //           }
  //         }
  //       }
  //     }
  //   }
  // }
  Future<void> sendControlData(
      bool isHeaterOn, int timerValue, double sliderValue) async {
    Map<String, dynamic> controlData = {
      "isHeaterOn": isHeaterOn,
      "timerValue": timerValue,
      "sliderValue": sliderValue,
    };

    BluetoothDevice? device = await getConnectedDevice();
    if (device != null) {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().contains("cccc")) {
          List<BluetoothCharacteristic> characteristics =
              service.characteristics;
          for (BluetoothCharacteristic characteristic in characteristics) {
            if (characteristic.uuid.toString() ==
                "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
              String dataString = jsonEncode(controlData);
              List<int> dataBytes = dataString.codeUnits;
              await characteristic.write(dataBytes);
              break; // Exit the loop after writing
            }
          }
        }
      }
    }
  }
}
