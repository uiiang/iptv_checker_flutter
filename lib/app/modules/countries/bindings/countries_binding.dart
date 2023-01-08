import 'package:get/get.dart';

import '../controllers/countries_controller.dart';

class CountriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CountriesController>(
      () => CountriesController(),
    );
  }
}
