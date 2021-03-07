import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'deviceConnectPage.dart';
import 'qrCodeScanConnection.dart';
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
  List<Padding> deviceTile = [];
  bool prefixFound = false;
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
      deviceTile = [];
    });
  }
  bool checkForPrefix(String deviceName, String prefix){
    for(int i=0;i<prefix.length;i++){
      if(deviceName[i].toLowerCase() != prefix[i].toLowerCase()){
        return false;
      }
    }
    return true;
  }
  void scan(String prefix) {
    setState(() {
      searching = true;
      deviceTile = [];
    });

    // Searches in already connected Devices
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        print(checkForPrefix(device.name, prefix));
        if(checkForPrefix(device.name, prefix)){
          prefixFound = true;
          _addDeviceTolist(device);
        }
      }
    });

    // Searches for other devices
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {

      for (ScanResult result in results) {
        print((result.device.name));

        if(checkForPrefix(result.device.name, prefix)){
          _addDeviceTolist(result.device);
          prefixFound = true;
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
  Widget _buildListViewOfDevices() {
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

    return prefixFound==false?Center(child: Text('No devices with prefix : ${_prefixController.value.text} found')):ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...deviceTile,
      ],
    );
  }


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
                        onPressed:(){ Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QrCodeScanner()),
                        );},
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
