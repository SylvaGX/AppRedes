import 'package:app_redes/device.dart';
import 'package:app_redes/app_data.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 1000), () {
      Provider.of<AppData>(context, listen: false).startScanning();
    });
  }

  Widget getImageWidget() {
    String? companyName;

    Device? highest =
        Provider.of<AppData>(context, listen: false).highestSignalDevice;

    if (highest?.company?.startsWith("Apple") ?? false) {
      companyName = "apple.png";
    } else if (highest?.company?.startsWith("Samsung") ?? false) {
      companyName = "samsung.png";
    }

    return companyName == null
        ? const Icon(
            Icons.smart_display_outlined,
            size: 128,
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image(
                image: AssetImage('assets/company/$companyName'), height: 128),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Redes"),
      ),
      body: Column(
        children: [
          Consumer<AppData>(builder: (c, app, child) {
            return getImageWidget();
          }),
          Expanded(
            child: Consumer<AppData>(builder: (c, app, child) {
              if (app.notFoundForLong) {
                return const Center(
                  child: Text("Devices not found"),
                );
              }

              if (app.currentDevices.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              List<Device> devices = app.currentDevices.values.toList();

              return ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  Device item = devices[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.deviceInfo.name ?? "Name Unavailable",
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            item.deviceInfo.address,
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            "RSSI: ${item.rssi} dBm",
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          item.company != null
                              ? Text(
                                  item.company!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
