import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/controllers/countries_controller.dart';
import 'package:iptv_checker_flutter/app/modules/countries/views/handle_view.dart';

import '../../../../utils/widget/dpad_detector.dart';
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
              ? "Iptv Checker"
              : controller.logList.value.isNotEmpty
                  ? controller.logList.value.last
                  : "已选择${controller.getSelectedCount()}个频道")),
          centerTitle: true,
        ),
        // body: CountriesView(),
        body: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: CountriesView(),
            ),
            Container(
              alignment: Alignment.topCenter,
              child: HandleView(),
            ),
          ],
        ));
  }
}

// body: Row(children: [
// CountriesView(),
// Expanded(
// child: SizedBox(
// height: 200.0,
// child: ListView.builder(
// shrinkWrap: true,
// itemCount: 5,
// itemBuilder: (BuildContext context, int index) {
// // final item = controller.selecteds[index];
// return Text('badafsdfa');
// })),
// ),
// ])
