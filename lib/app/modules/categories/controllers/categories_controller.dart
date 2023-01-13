import 'package:get/get.dart';

import '../../../../utils/api_service.dart';
import '../categories_model.dart';

class CategoriesController extends GetxController {

  final categories = Categories().obs;
  @override
  void onInit() {
    super.onInit();
    fetchIptvCategories();
  }

  void fetchIptvCategories() async {
    var content = await ApiService.loadIptvCategories();
    // LogUtil.d(content.data?.length, tag: _TAG);
    categories.value = content;
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
