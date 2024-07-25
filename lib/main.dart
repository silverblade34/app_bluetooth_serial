import 'package:ble_serial/app/routes/pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(GetMaterialApp(
    title: "App Testo Ble",
    debugShowCheckedModeBanner: false,
    initialRoute: Routes.HOME,
    theme: ThemeData(
      fontFamily: 'Onest',
      useMaterial3: true,
      colorSchemeSeed: Colors.white,
    ),
    defaultTransition: Transition.fade,
    getPages: AppPages.pages,
    builder: (context, myWidget) {
      myWidget = EasyLoading.init()(context, myWidget);
      return myWidget;
    },
  ));
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}
