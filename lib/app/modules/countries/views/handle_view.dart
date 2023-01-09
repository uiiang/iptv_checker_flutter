import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/controllers/countries_controller.dart';
import 'package:iptv_checker_flutter/app/modules/countries/views/widget_kit.dart';
import 'package:iptv_checker_flutter/utils/widget/dpad_detector.dart';

class HandleView extends StatelessWidget {
  static const _TAG = 'HandleView';

  const HandleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CountriesController controller = Get.put(CountriesController());
    final selectedListPanel = Obx(() {
      final selectList = controller.getSelectedCountriesList();
      return ListView.builder(
        shrinkWrap: true,
        itemCount: selectList.length,
        itemBuilder: (BuildContext context, int index) {
          final item = selectList[index];
          return Container(
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: ListTile(
                title: getCountryItemRow(item),
                subtitle: Obx(() => Text(
                      item.status.value,
                      style: const TextStyle(fontSize: 12),
                    )),
              ));
        },
      );
    });

    Row btnPanel = Row(
      children: [
        //清除
        DPadDetector(
          onTap: () {
            print('clear');
            controller.clearSelect();
          },
          child: buildHandleBtn("清除"),
        ),
        //生成
        DPadDetector(
          onTap: () {
            print('generator 2');
            // controller.saveData();
            // controller.genM3u8();
          },
          child: buildHandleBtn(
            controller.handleing.value ? '生成中' : '生成',
          ),
        ),
      ],
    );

    return Column(
      children: [
        Expanded(
            child: SizedBox(
          height: 300,
          width: 200,
          child: selectedListPanel,
        )),
        btnPanel,
      ],
    );
  }
}
