import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/categories/categories_model.dart';
import 'package:iptv_checker_flutter/utils/api_service.dart';
import 'package:iptv_checker_flutter/utils/log_util.dart';

import '../../countries/countries_model.dart';

class HomeController extends GetxController {
  static const _TAG = 'HomeController';

  @override
  void onInit() {
    LU.d('onInit', tag: _TAG);
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
