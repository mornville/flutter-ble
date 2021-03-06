import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class DeviceConnect extends StatefulWidget {
  final BluetoothDevice device;
  List<BluetoothService> services;
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  DeviceConnect({Key key, @required this.device, @required this.services}) : super(key: key);
  @override
  _DeviceConnectState createState() => _DeviceConnectState();
}

class _DeviceConnectState extends State<DeviceConnect> {
  List<ElevatedButton> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ElevatedButton> buttons = [];
    final _ssidController = TextEditingController();
    final _passwordController = TextEditingController();

    if (characteristic.properties.read) {
      buttons.add(
  ElevatedButton(
              child: Text('READ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                sub.cancel();
              },

        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
      ElevatedButton(
              child: Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Write"),
                        content: Container(
                          height: 200,
                          child: Column(
                            children: <Widget>[

                              Expanded(
                                child: TextField(
                                  controller: _ssidController,
                                  decoration: InputDecoration(
                                    labelText: 'WiFi SSID',

                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',

                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Send"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(_ssidController.value.text +',' +_passwordController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),

      );
    }
    if (characteristic.properties.notify) {
      buttons.add(

          ElevatedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                characteristic.value.listen((value) {
                  widget.readValues[characteristic.uuid] = value;
                });
                await characteristic.setNotifyValue(true);
              },
            ),
      );
    }

    return buttons;
  }

  ListView _buildConnectDeviceView() {
    List<Container> containers = [];

    for (BluetoothService service in widget.services) {
      List<ListTile> tiles = [];

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        tiles.add(
       ListTile(
              title: Text('Char ID: ' +  characteristic.uuid.toString(), style: TextStyle(fontSize: 12.0),),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 10,
                  ),
                  Text('Actions Available: '),
                  ..._buildReadWriteNotifyButton(characteristic),
                  Text('Read Value: ' +
                      widget.readValues[characteristic.uuid].toString()),
                ],
              ),
            ),



        );
      }
      containers.add(
        Container(
          child: ExpansionTile(
              title: Text(service.uuid.toString()),
              children: tiles),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
    title: Text(widget.device.name.toString()),
      ),
      body: _buildConnectDeviceView(),
    );
  }
}
