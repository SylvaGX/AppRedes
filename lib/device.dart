

import 'package:my_flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Device {

  BluetoothDevice deviceInfo;
  String? company;
  int rssi;

  Device({required this.deviceInfo, required this.rssi, this.company});
}