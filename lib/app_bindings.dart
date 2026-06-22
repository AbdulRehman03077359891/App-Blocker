import 'package:get/get.dart';
import 'package:zo_app_blocker_demo/controllers/blocker_controller.getx.dart';
import 'package:zo_app_blocker_demo/controllers/home_controller.getx.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Inject core business logic controllers permanent in memory
    Get.put(BlockerController(), permanent: true);

    // Inject UI/Screen specific controllers
    Get.lazyPut(() => HomeController());
  }
}
