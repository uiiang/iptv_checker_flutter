import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/views/widget_kit.dart';
import 'package:iptv_checker_flutter/utils/widget/dpad_detector.dart';

import '../controllers/countries_controller.dart';

class CountriesView extends GetView<CountriesController> {
  static const _TAG = 'CountriesView';

  const CountriesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => GridView.builder(
      shrinkWrap: false,
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 5 / 2),
      primary: false,
      itemCount: controller.countriesCount.value,
      itemBuilder: (BuildContext context, int index) {
        final item = controller.countries[index];
        return Obx(() => DPadDetector(
          enabled: !controller.handleing.value,
          focusColor: Colors.blue,
            onMenuTap: () {},
            onTap: () {
              controller.selectItem(index);
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.selected.value
                    ? Colors.orange.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color:
                        item.selected.value ? Colors.black : Colors.transparent,
                    width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: getCountryItemRow(item),
              ),
            )));
      },
    ));
  }
}
