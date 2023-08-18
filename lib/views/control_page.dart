import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bluetooth_app/controllers/bluetooth_controller.dart';
import 'dart:math';

class ControlPage extends StatefulWidget {
  @override
  _ControlPageState createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  double _sliderValue = 50; // Initial slider value
  bool _isSliderActive = false;

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
                      onChanged: (newValue) {
                        setState(() {
                          _sliderValue = newValue;
                          _isSliderActive = true;
                        });
                      },
                      onChangeEnd: (newValue) async {
                        if (_isSliderActive) {
                          _isSliderActive = false;
                          await controller.writeIntensityCharacteristic(
                              newValue.toInt().floor());
                        }
                      },
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '$_sliderValue',
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await controller.disconnectFromDevice();
                      },
                      child: Text('Disconnect'),
                    )
                  ],
                ),
              );
            }));
  }
}
