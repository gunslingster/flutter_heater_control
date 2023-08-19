import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bluetooth_app/controllers/bluetooth_controller.dart';
import 'dart:math';
import 'dart:async';

class ControlPage extends StatefulWidget {
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

  void _startTimer() {
    if (_remainingTime.inSeconds == 0) {
      _remainingTime = Duration(minutes: _selectedMinutes);
    }
    _timer?.cancel(); // Cancel any existing timers
    setState(() {
      _timerRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - Duration(seconds: 1);
        } else {
          _stopTimer();
        }
      });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Control Page'),
      ),
      body: GetBuilder<BluetoothController>(
        init: BluetoothController(),
        builder: (controller) {
          return Center(
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
              ],
            ),
          );
        },
      ),
    );
  }
}
