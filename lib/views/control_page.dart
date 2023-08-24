import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bluetooth_app/controllers/bluetooth_controller.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bluetooth_app/device_names.dart';

class ControlPage extends StatefulWidget {
  final BluetoothDevice device; // Accepting the device as a parameter

  ControlPage({required this.device});

  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  double _sliderValue = 50; // Initial slider value
  bool _isHeaterOn = false; // Heater status
  int _selectedMinutes = 240; // Timer interval in minutes (4 hours)
  Duration _remainingTime =
      Duration(minutes: 240); // Initial remaining time (4 hours)
  bool _timerRunning = false;

  Timer? _timer;
  late final BluetoothController _bluetoothController;

  TextEditingController _deviceNameController = TextEditingController();
  // late StreamSubscription _heaterStatusSubscription;

  @override
  void initState() {
    super.initState();
    setupBluetooth();
  }

  Future<void> setupBluetooth() async {
    print("In init state");
    _bluetoothController = Get.find<BluetoothController>();

    print("In init state 2");
    // Ensure the device is connected before discovering services
    if (widget.device.state != BluetoothDeviceState.connected) {
      await widget.device.connect();
    }

    // Now get the heater status. Since you're reading it once, you can wait for the value to be available.
    Map<String, dynamic> status =
        await _bluetoothController.subscribeToHeaterStatus(widget.device);
    print("In init state 3");
    print("Received Data from ESP32: $status");
    if (mounted) {
      // Check if the widget is still in the tree
      // Check if the widget is still in the tree
      setState(() {
        _isHeaterOn = status["isHeaterOn"] ?? false;
        _selectedMinutes = status["timerValue"] ?? 240;
        _sliderValue = (status["sliderValue"] ?? 50.0).toDouble();

        // Get remaining time from the received data
        int hours = status["remainingHours"] ?? 0;
        int minutes = status["remainingMinutes"] ?? 0;
        int seconds = status["remainingSeconds"] ?? 0;
        _remainingTime =
            Duration(hours: hours, minutes: minutes, seconds: seconds);

        print("Updated _isHeaterOn: $_isHeaterOn");
        print("Updated _selectedMinutes: $_selectedMinutes");
        print("Updated _sliderValue: $_sliderValue");
        print(
            "Remaining Time: ${_remainingTime.inHours}h ${_remainingTime.inMinutes.remainder(60)}m ${_remainingTime.inSeconds.remainder(60)}s");

        // If the heater is on, start the countdown timer
        if (_isHeaterOn) {
          _startTimer();
        }
      });
    }

    // Rest of your code...
  }

  @override
  void dispose() {
    _timer?.cancel();
    // _heaterStatusSubscription.cancel(); // Cancel the subscription
    _bluetoothController.disconnectFromDevice();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingTime.inSeconds == 0) {
      _remainingTime = Duration(minutes: _selectedMinutes);
    }
    _timer?.cancel(); // Cancel any existing timers
    setState(() {
      _timerRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        // <-- Add this check
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = _remainingTime - Duration(seconds: 1);
          } else {
            _stopTimer();
          }
        });
      } else {
        timer.cancel(); // Cancel the timer if widget is no longer mounted
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
    });
  }

  void _resetTimer() {
    setState(() {
      _selectedMinutes = 240; // Reset timer to 4 hours
      _remainingTime = Duration(minutes: _selectedMinutes);
    });
  }

  void _toggleHeater(bool newValue) {
    if (newValue) {
      _startTimer();
      // Code to turn the heater on
    } else {
      _stopTimer();
      // Code to turn the heater off
    }
    setState(() {
      _isHeaterOn = newValue;
      _resetTimer();
      if (!_isHeaterOn) {
        _sliderValue = 50; // Reset slider value to 50 when heater is off
      }
    });
  }

  void _incrementMinutes() {
    setState(() {
      if (_isHeaterOn && _selectedMinutes < 240) {
        _selectedMinutes += 30;
        _remainingTime = Duration(minutes: _selectedMinutes);
      } else if (!_isHeaterOn && _selectedMinutes < 240) {
        _selectedMinutes += 30;
        _remainingTime = Duration(minutes: _selectedMinutes);
      }
    });
  }

  void _decrementMinutes() {
    setState(() {
      if (_isHeaterOn && _selectedMinutes > 30) {
        _selectedMinutes -= 30;
        _remainingTime = Duration(minutes: _selectedMinutes);
      } else if (!_isHeaterOn && _selectedMinutes > 30) {
        _selectedMinutes -= 30;
        _remainingTime = Duration(minutes: _selectedMinutes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _bluetoothController.disconnectFromDevice();
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset:
            true, // This is true by default, but adding it here for clarity
        appBar: AppBar(
          title: FutureBuilder<String?>(
            future: getCustomDeviceName(widget.device.id.toString()),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Text(snapshot.data!);
              }
              return Text(widget.device.name);
            },
          ),
        ),
        body: GetBuilder<BluetoothController>(
          init: BluetoothController(),
          builder: (controller) {
            return SingleChildScrollView(
                child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Slider(
                    value: _sliderValue,
                    onChanged: (_isHeaterOn)
                        ? (newValue) {
                            setState(() {
                              _sliderValue = newValue;
                            });
                          }
                        : null,
                    onChangeEnd: (newValue) {
                      controller.sendControlData(
                          _isHeaterOn, _selectedMinutes, _sliderValue);
                    },
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '$_sliderValue',
                    activeColor: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          _incrementMinutes();
                          controller.sendControlData(
                              _isHeaterOn, _selectedMinutes, _sliderValue);
                        },
                        icon: Icon(Icons.arrow_upward),
                        color: _isHeaterOn ? Colors.green : Colors.grey,
                      ),
                      Text(
                        '${_remainingTime.inHours.toString().padLeft(2, '0')}:${(_remainingTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 24),
                      ),
                      IconButton(
                        onPressed: () {
                          _decrementMinutes();
                          controller.sendControlData(
                              _isHeaterOn, _selectedMinutes, _sliderValue);
                        },
                        icon: Icon(Icons.arrow_downward),
                        color: _isHeaterOn ? Colors.red : Colors.grey,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isHeaterOn ? 'ON' : 'OFF'),
                      Switch(
                        value: _isHeaterOn,
                        onChanged: (newValue) {
                          _toggleHeater(newValue);
                          controller.sendControlData(
                              newValue, _selectedMinutes, _sliderValue);
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _resetTimer();
                      controller.sendControlData(
                          _isHeaterOn, _selectedMinutes, _sliderValue);
                    },
                    child: Text('Reset Timer'),
                  ),
                  // ... Your existing buttons ...
                  TextField(
                    controller: _deviceNameController,
                    decoration:
                        InputDecoration(labelText: "Set custom device name"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await setCustomDeviceName(widget.device.id.toString(),
                          _deviceNameController.text);
                      setState(() {}); // to refresh the UI
                    },
                    child: Text('Set Name'),
                  )
                ],
              ),
            ));
          },
        ),
      ),
    );
  }
}
