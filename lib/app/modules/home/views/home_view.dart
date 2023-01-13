import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/controllers/countries_controller.dart';
import 'package:iptv_checker_flutter/app/modules/countries/views/handle_view.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../countries/views/countries_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);
  Container buildSetting(){
    return Container(
      padding: EdgeInsets.all(10),
      child:  SettingsList(
        contentPadding: EdgeInsets.zero,
        sections: [
          SettingsSection(
            // margin: EdgeInsetsDirectional.all(5),
            title: const Text('设置'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                description: const Text("超时设置越长，可能检测到更多频道，但检测时间长，收看时容易卡顿"),
                title: const Text(
                  '超时',
                  style: TextStyle(fontSize: 14),
                ),
                value: const Text('English', style: TextStyle(fontSize: 14)),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {},
                description: const Text("自动下载epg文件，用于显示电视节目表"),
                initialValue: true,
                title: const Text(
                  '生成epg',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    CountriesController controller = Get.put(CountriesController());
    return Scaffold(
        appBar: AppBar(
          title:Text("请在左侧选择"),
          // title: Obx(() => Text(controller.getSelectedCount() == 0
          //     ? "请在左侧选择"
          //     : "已选择${controller.getSelectedCount()}个频道")),
          centerTitle: true,
        ),
        // body: CountriesView(),
        body: Row(
          children: [
            // Text("data"),
            Obx(() {
              return AspectRatio(
                  aspectRatio: 1,
                  child: controller.setting.isFalse
                      ? const CountriesView()
                      : buildSetting());
            }),
            Container(
              padding: const EdgeInsets.all(10),
              alignment: Alignment.topCenter,
              child: const HandleView(),
            ),
          ],
        ));
  }
}
