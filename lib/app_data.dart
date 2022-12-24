import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:app_redes/device.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart';

class AppData extends ChangeNotifier {
  final Client client = Client();
  bool notFoundForLong = false;
  List<Device> devices = [];
  Map<String, Device> currentDevices = HashMap<String, Device>();
  int lastRequest = DateTime.now().millisecondsSinceEpoch;

  Device? highestSignalDevice;

  Future<void> addDevice(BluetoothDevice deviceInfo, int rssi) async {
    currentDevices.putIfAbsent(
        deviceInfo.address, () => Device(deviceInfo: deviceInfo, rssi: rssi));
    notifyListeners();
  }

  Future<String> findCompany(String mac) async {
    final Uri url = Uri.https("api.macvendors.com", mac);

    while (DateTime.now().millisecondsSinceEpoch - lastRequest < 1000) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    lastRequest = DateTime.now().millisecondsSinceEpoch;

    return await client.get(url).then((value) {
      return value.body;
    });
  }

  Future<void> startScanning() async {
    log("Scanning...");
    bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;

    while (!(isEnabled ?? false)) {
      await Future.delayed(const Duration(seconds: 1), () {});
      await FlutterBluetoothSerial.instance.ensurePermissions();
      await FlutterBluetoothSerial.instance.requestEnable();
      isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    }

    devices = [];

    FlutterBluetoothSerial.instance.startDiscovery().listen(
        (BluetoothDiscoveryResult result) {
      if (result.device.name != null) {
        devices.add(Device(deviceInfo: result.device, rssi: result.rssi));
      }
      for (Device d in devices) {
        if (!currentDevices.containsKey(d.deviceInfo.address)) {
          addDevice(d.deviceInfo, d.rssi);
        } else {
          currentDevices[d.deviceInfo.address]!.rssi = d.rssi;
          notifyListeners();
        }
      }
    }, onDone: () async {
      log("DONE!");

      // Remove not visible devices
      List<String> knownMacs =
          devices.map((e) => e.deviceInfo.address).toList();
      currentDevices.removeWhere((key, value) => !knownMacs.contains(key));
      notifyListeners();

      if (highestSignalDevice != null) {
        Device? high = currentDevices[highestSignalDevice!.deviceInfo.address];
        highestSignalDevice!.rssi =
            high != null ? high.rssi : highestSignalDevice!.rssi;
        notifyListeners();
      }

      if (highestSignalDevice == null ||
          !currentDevices
              .containsKey(highestSignalDevice!.deviceInfo.address) ||
          highestSignalDevice!.rssi < -82) {
        if (highestSignalDevice != null && !currentDevices
            .containsKey(highestSignalDevice!.deviceInfo.address)) {
          highestSignalDevice = null;
        }
        await newHighestDevice();
        notifyListeners();
      }

      Future.delayed(const Duration(seconds: 1), startScanning);
    });
  }

  Future<void> newHighestDevice() async {
    if (currentDevices.isEmpty) return;

    currentDevices.forEach((key, value) {
      if (highestSignalDevice == null) {
        highestSignalDevice = value;
      } else if ((highestSignalDevice!.rssi) < value.rssi) {
        highestSignalDevice = value;
      }
    });
    if (highestSignalDevice!.company == null) {
      String company =
          await findCompany(highestSignalDevice!.deviceInfo.address);
      highestSignalDevice!.company = company;
      currentDevices[highestSignalDevice!.deviceInfo.address]?.company =
          company;
    }
  }
}
