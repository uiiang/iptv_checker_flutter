import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/controllers/countries_controller.dart';
import 'package:iptv_checker_flutter/app/modules/countries/views/widget_kit.dart';
import 'package:iptv_checker_flutter/utils/widget/dpad_detector.dart';
import 'package:settings_ui/settings_ui.dart';

class HandleView extends StatelessWidget {
  static const _TAG = 'HandleView';

  const HandleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CountriesController controller = Get.put(CountriesController());

    final selectedListPanel = Obx(() {
      final selectList = controller.getSelectedCountriesList();
      // controller.checkSelectedEpg(selectList);
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
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: ListTile(
                  title: getCountryItemRow(item, fontSize: 12.0),
                  subtitle: Obx(() {
                    return Text(
                      '${item.channelCount.value}个频道 ${item.status.value}',
                      style: const TextStyle(fontSize: 12),
                    );
                  }),
                  trailing: Obx(() => Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // buildEpgFlag(item.hasEpg.value),
                          buildStatusPanel(
                              item.okCount.value.toString(), 'ok'),
                          buildStatusPanel(
                              item.errorCount.value.toString(), 'error'),
                        ],
                      ))));
        },
      );
    });

    Row btnPanel = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        //设置
        Obx(() => DPadDetector(
              enabled: !controller.handleing.value,
              onTap: () {
                print('setting ${controller.setting.value}');
                controller.toggleSetting();
              },
              child: buildHandleBtn(controller.setting.isFalse?"设置":"关闭设置", disable: controller.handleing.value),
            )),
        //清除
        Obx(() => DPadDetector(
              enabled: !controller.handleing.value,
              onTap: () {
                print('clear');
                controller.clearSelect();
              },
              child: buildHandleBtn("清除", disable: controller.handleing.value),
            )),
        //生成
        Obx(() => DPadDetector(
              enabled: !controller.handleing.value,
              onTap: () {
                controller.saveData();
                controller.genM3u8RealTimeCheck();
              },
              child: buildHandleBtn(controller.handleing.value ? '生成中' : '生成',
                  disable: controller.handleing.value),
            )),
      ],
    );

    return Column(
      children: [
        btnPanel,
        Expanded(
            child: SizedBox(height: 300, width: 200, child: selectedListPanel)),
      ],
    );
  }
}
