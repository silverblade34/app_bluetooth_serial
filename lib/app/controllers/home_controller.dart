import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as thermal;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as serial;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeController extends GetxController {
  serial.BluetoothConnection? connection;
  var macAddress = '7C:9E:BD:CF:9C:A6'.obs;
  RxString macAddressPrinter = '66:22:2D:E2:D9:D6'.obs;
  TextEditingController galones = TextEditingController();
  var isConnected = false.obs;
  var isConnectedPrinter = false.obs;
  thermal.BlueThermalPrinter printer = thermal.BlueThermalPrinter.instance;
  RxList<serial.BluetoothDevice> devices = <serial.BluetoothDevice>[].obs;

  @override
  void onInit() {
    super.onInit();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetooth]?.isGranted == false ||
        statuses[Permission.bluetoothScan]?.isGranted == false ||
        statuses[Permission.bluetoothConnect]?.isGranted == false ||
        statuses[Permission.location]?.isGranted == false) {
      EasyLoading.showError("Se requieren permisos de Bluetooth y ubicación");
    }
  }

  printConnect() async {
    if (macAddressPrinter.value.isNotEmpty) {
      try {
        // Buscar el dispositivo con la dirección MAC especificada
        List<thermal.BluetoothDevice> devices =
            await printer.getBondedDevices();
        thermal.BluetoothDevice? device =
            devices.firstWhere((d) => d.address == macAddressPrinter.value);

        await printer.connect(device);
        isConnectedPrinter.value = await printer.isConnected ?? false;
      } catch (e) {
        Get.snackbar("Error", "No se pudo conectar: $e");
      }
    } else {
      Get.snackbar("Error", "La dirección MAC no puede estar vacía");
    }
  }

  printDisconnect() async {
    await printer.disconnect();
    isConnectedPrinter.value = false;
  }

  printGalones() async {
    await printConnect();
    if (isConnectedPrinter.value) {
      printer.printNewLine();
      printer.printCustom("Galones: ${galones.text}", 2, 1);
      printer.printNewLine();
      printer.printNewLine();
      printer.printNewLine();
    } else {
      Get.snackbar("Error", "No está conectado a una impresora");
    }
  }

  Future<void> blsConnect() async {
    try {
      EasyLoading.show(status: "Cargando...");
      debugPrint("Verificando disponibilidad de Bluetooth...");

      bool? isBluetoothAvailable =
          await serial.FlutterBluetoothSerial.instance.isAvailable;
      if (isBluetoothAvailable == null || !isBluetoothAvailable) {
        EasyLoading.dismiss();
        throw "El Bluetooth no está disponible en este dispositivo.";
      }

      debugPrint("Verificando si Bluetooth está habilitado...");
      bool? isBluetoothEnabled =
          await serial.FlutterBluetoothSerial.instance.isEnabled;
      if (isBluetoothEnabled == null || !isBluetoothEnabled) {
        await serial.FlutterBluetoothSerial.instance.requestEnable();
      }

      if (macAddress.value.isEmpty) {
        EasyLoading.dismiss();
        throw "La dirección MAC no puede estar vacía.";
      }

      debugPrint("Intentando conectar con MAC: ${macAddress.value}");
      connection = await serial.BluetoothConnection.toAddress(macAddress.value);
      EasyLoading.showInfo("BLS CONECTADO");
      isConnected.value = true;

      List<int> list = "1".codeUnits;
      Uint8List bytes = Uint8List.fromList(list);
      connection?.output.add(bytes);

      print(connection);
      print("sendData correcto");

      connection?.input?.listen((Uint8List data) {
        if (data.lengthInBytes >= 4) {
          var decodedValue = ascii.decode(data);
          double valueWithDecimals = double.tryParse(decodedValue) ?? 0;
          galones.text = valueWithDecimals.toStringAsFixed(2);
        }
      }).onDone(() {
        print('SE DESCONECTO');
        isConnected.value = false;
      });
    } catch (err) {
      EasyLoading.dismiss();
      debugPrint("Error: $err");
      EasyLoading.showError("No se pudo vincular al dispositivo: $err");
    }
  }

  Future<void> blsDisconnect() async {
    connection?.finish();
    isConnected.value = false;
  }
}
