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
  RxString macAddressPrinter = '66:22:2D:E2:D9:D6'.obs;
  TextEditingController galones = TextEditingController();
  TextEditingController macElectronica =
      TextEditingController(text: '7C:9E:BD:CF:9C:A6');
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

  Future<void> printConnect() async {
    // Desconectar el ESP32 antes de conectarte a la impresora térmica
    await blsDisconnect();
    if (macAddressPrinter.value.isNotEmpty) {
      try {
        // Buscar el dispositivo con la dirección MAC especificada
        List<thermal.BluetoothDevice> devices =
            await printer.getBondedDevices();
        print("----------------------------------------");
        print("Dispositivos vinculados:");
        for (var device in devices) {
          print("Nombre: ${device.name}, Dirección MAC: ${device.address}");
        }
        print("----------------------------------------");

        thermal.BluetoothDevice? device =
            devices.firstWhere((d) => d.address == macAddressPrinter.value);

        await printer.connect(device);
        isConnectedPrinter.value = await printer.isConnected ?? false;
        if (!isConnectedPrinter.value) {
          Get.snackbar("Error", "No se pudo conectar a la impresora");
        }
      } catch (e) {
        print(e.toString());
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

  Future<void> printGalones() async {
    try {
      // Mostrar el indicador de progreso
      EasyLoading.showProgress(0.0, status: 'Conectando a la impresora...');

      // Conectar a la impresora
      await printConnect();

      // Actualizar el progreso
      EasyLoading.showProgress(0.5, status: 'Imprimiendo...');

      if (isConnectedPrinter.value) {
        printer.printNewLine();
        printer.printCustom("Galones: ${galones.text}", 2, 1);
        printer.printNewLine();
        printer.printNewLine();
        printer.printNewLine();

        // Actualizar el progreso al 100%
        EasyLoading.showProgress(1.0, status: 'Finalizando...');

        // Desconectar la impresora después de imprimir
        await printDisconnect();

        // Ocultar el indicador de progreso
        EasyLoading.dismiss();
      } else {
        // Ocultar el indicador de progreso en caso de error
        EasyLoading.dismiss();
        Get.snackbar("Error", "No está conectado a una impresora");
      }
    } catch (e) {
      // Ocultar el indicador de progreso en caso de excepción
      EasyLoading.dismiss();
      Get.snackbar("Error", "Se produjo un error: $e");
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

      if (macElectronica.text.isEmpty) {
        EasyLoading.dismiss();
        throw "La dirección MAC no puede estar vacía.";
      }

      debugPrint("Intentando conectar con MAC: ${macElectronica.text}");
      connection =
          await serial.BluetoothConnection.toAddress(macElectronica.text);
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
      EasyLoading.showError("No se pudo vincular a la electronica");
    }
  }

  Future<void> blsDisconnect() async {
    connection?.finish();
    isConnected.value = false;
  }
}
