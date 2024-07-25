import 'package:ble_serial/app/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Test'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(
                () => TextField(
                  onChanged: (value) => controller.macAddress.value = value,
                  decoration: InputDecoration(
                    labelText: 'Dirección MAC',
                    border: const OutlineInputBorder(),
                    errorText: controller.macAddress.value.isEmpty
                        ? 'La dirección MAC no puede estar vacía'
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: controller.blsConnect,
                child: const Text('Conectar Bluetooth'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: controller.blsDisconnect,
                child: const Text('Desconectar Bluetooth'),
              ),
              const SizedBox(height: 20),
              Obx(
                () => Text(
                  controller.isConnected.value ? 'Conectado' : 'Desconectado',
                  style: TextStyle(
                    color:
                        controller.isConnected.value ? Colors.green : Colors.red,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.galones,
                decoration: const InputDecoration(
                  labelText: 'Galones',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: controller.printGalones,
                child: const Text('Imprimir Galones'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
