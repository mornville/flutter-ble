import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'deviceConnectPage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter ESP32',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter ESP32'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = [];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _prefixController = TextEditingController();
  bool searching = false;
  List<BluetoothService> _services;
  BluetoothState state;
  String text = '';
  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    FlutterBlue.instance.state.listen((state) {
      if (state == BluetoothState.off) {
        setState(() {
          text = 'Turn on Bluetooth';
        });
      } else {
        setState(() {
          text = '';
        });
      }
    });
    super.initState();
  }

  void stop() {
    setState(() {
      searching = false;
      widget.flutterBlue.stopScan();
    });
  }

  void scan(String prefix) {
    setState(() {
      searching = true;
    });

    // Searches in already connected Devices
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        if (device.name
            .toString()
            .toLowerCase()
            .contains(prefix.toLowerCase())) {
          _addDeviceTolist(device);
        }
      }
    });

    // Searches for other devices
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name
            .toString()
            .toLowerCase()
            .contains(prefix.toLowerCase())) {
          _addDeviceTolist(result.device);
          print(result.device);
        }
      }
    });
    widget.flutterBlue.startScan();
  }

  // Widget _bluetoothOffScreen(){
  //   return Center(
  //     child: Container(
  //       color: Colors.blue,
  //       child: Center(
  //         child:Icon(Icons.bluetooth_disabled_sharp, size:150.0, color: Colors.white,)
  //       )),
  //   );
  // }
  ListView _buildListViewOfDevices() {
    List<Padding> deviceTile = [];
    for (BluetoothDevice device in widget.devicesList) {
      deviceTile.add(
        Padding(
          padding: EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(device.name == '' ? '(unknown device)' : device.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.id.toString()),
                Text(device.type.toString())
              ],
            ),
            trailing: FlatButton(
              color: Colors.blue,
              child: Text(
                'Connect',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                widget.flutterBlue.stopScan();
                setState(() {
                  searching = false;
                });
                try {
                  await device.connect();
                } catch (e) {
                  if (e.code != 'already_connected') {
                    throw e;
                  }
                } finally {
                  _services = await device.discoverServices();
                }
                setState(() {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DeviceConnect(device: device, services: _services),
                      ));
                });
              },
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...deviceTile,
      ],
    );
  }

  void selectConnectionMethod() {}
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            !searching && text == ''
                ? Container()
                : searching && text == ''
                    ? IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          stop();
                        },
                      )
                    : Container()
          ],
        ),
        body: searching
            ? _buildListViewOfDevices()
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: selectConnectionMethod,
                        child: Text('Add a Device Using QR Code')),
                    ElevatedButton(
                      child: Text('Add device Using Prefix',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("PREFIX"),
                                content: Container(
                                  height: 200,
                                  child: Column(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextField(
                                          controller: _prefixController,
                                          decoration: InputDecoration(
                                            labelText: 'Type Prefix Here...',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text("Search"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      scan(_prefixController.value.text
                                          .toString());
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                    ),
                  ],
                ),
              ),
      );
}
