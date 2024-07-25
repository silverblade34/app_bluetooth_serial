import 'package:ble_serial/app/bindings/home_binding.dart';
import 'package:ble_serial/app/pages/home_page.dart';
import 'package:get/get.dart';
part './routes.dart';

abstract class AppPages {
  static final pages = [
    GetPage(
      name: Routes.HOME,
      page: () => HomePage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      // middlewares: [AuthMiddleware()],
    ),
  ];
}
