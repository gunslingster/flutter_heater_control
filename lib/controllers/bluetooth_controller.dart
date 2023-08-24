import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';

class BluetoothController extends GetxController {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>();

  StreamController<Map<String, dynamic>> _heaterStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get heaterStatus =>
      _heaterStatusController.stream;

  Future<Map<String, dynamic>> subscribeToHeaterStatus(
      BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString().contains("cccc")) {
        List<BluetoothCharacteristic> characteristics = service.characteristics;
        for (BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.uuid.toString() ==
              "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
            List<int> value = await characteristic.read();
            print("Received value from characteristic: $value");
            String dataString = String.fromCharCodes(value);
            Map<String, dynamic> dataJson = jsonDecode(dataString);

            // Return the dataJson directly instead of pushing to a stream
            return dataJson;
          }
        }
      }
    }

    // If the function doesn't find the expected UUIDs or there's an issue, return an empty map.
    return {};
  }

  Future<void> scanDevices() async {
    // Start scanning
    flutterBlue.startScan(timeout: const Duration(seconds: 5));

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
