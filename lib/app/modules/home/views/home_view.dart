import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/controllers/countries_controller.dart';
import 'package:iptv_checker_flutter/app/modules/countries/views/handle_view.dart';

import '../../countries/views/countries_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CountriesController controller = Get.put(CountriesController());
    // CountriesController controller = Get.find();
    return Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(controller.getSelectedCount() == 0
              ? "请在左侧选择"
              : "已选择${controller.getSelectedCount()}个频道")),
          centerTitle: true,
        ),
        // body: CountriesView(),
        body: Row(
          children: [
            const AspectRatio(
              aspectRatio: 1,
              child: CountriesView(),
            ),
            Container(
              alignment: Alignment.topCenter,
              child: const HandleView(),
            ),
          ],
        ));
  }
}