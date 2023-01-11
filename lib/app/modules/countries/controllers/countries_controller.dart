import 'dart:async';

import 'package:flustars/flustars.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/countries_model.dart';
import 'package:iptv_checker_flutter/utils/api_service.dart';
import 'package:iptv_checker_flutter/utils/log_util.dart';
import 'package:iptv_checker_flutter/utils/m3u8_helper.dart';
import 'package:m3u_nullsafe/m3u_nullsafe.dart';

class CountriesController extends GetxController {
  static const _TAG = 'CountriesController';
  final countries = <Data>[].obs;
  final countriesCount = 0.obs;
  final handleing = false.obs;

  @override
  void onInit() {
    LU.d('onInit', tag: _TAG);
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    fetchIptvCountries();
  }

  void genM3u8() async {
    handleing.value = true;
    Iterable<Data> selecteds = getSelectedCountriesList().map((e) {
      e.status.value = "等待中...";
      return e;
    });

    if (selecteds.isEmpty) {
      print('开始生成m3u8文件，无选中的国家，停止生成');
      return;
    }
    print('共选择${selecteds.length}个国家频道');
    StreamController<Data> dataController = StreamController();
    Stream<Data> stream = dataController.stream;
    List<M3uGenericEntry> allCodeEntry = [];
    int doneCount = 0;
    stream.listen((item) async {
      print("开始解析${item.name}的频道");
      item.status.value = "开始解析...";
      final listOfTracks = await getChannelByCountryCode(item.code!);
      List<M3uGenericEntry> currCodeEntry = [];
      getAvailableChannelByCountryCode(listOfTracks).listen((availableChannel) {
        currCodeEntry.add(availableChannel);
        print("${item.name}找到第${currCodeEntry.length}个可用的频道");
        item.status.value =
            "正在解析...\n共${listOfTracks.length}个频道${currCodeEntry.length}个可用";
      }).onDone(() {
        if (currCodeEntry.isNotEmpty) {
          print("${item.name}完成解析,${currCodeEntry.length}个可用的频道");
          item.status.value = "完成解析-共${currCodeEntry.length}个可用频道";
          allCodeEntry.addAll(currCodeEntry);
        } else {
          item.status.value = "完成解析-无可用频道";
        }

        doneCount += 1;
        if (doneCount == selecteds.length) {
          dataController.close();
        }
      });
    }, onDone: () async {
      Iterable<String> content = allCodeEntry.map((entry){
        return createM3uContent(entry);
      }).toSet().toList();

      print('全部频道检测完毕 ${allCodeEntry.length}个可用频道, 去重后${content.length}');
      print("开始制作m3u8文件");
      String path = await saveM3u8File(
          "#EXTM3U\n${content.join("")}", "iptv_channel", "m3u");
      print("生成m3u结束 文件保存在$path");
      handleing.value = false;
    });
    for (final item in selecteds) {
      if (item.code == null) {
        continue;
      }
      dataController.add(item);
    }
  }

  void fetchIptvCountries() async {
    handleing.value = true;
    List<String> selectedCountry =
        SpUtil.getStringList("selected_country") ?? [];
    print("fetchIptvCountries ${selectedCountry.length}");
    var content = await ApiService.fetchIptvCountries();
    if (content.data != null) {
      countries.value = content.data!.map((element) {
        element.selected.value = selectedCountry.contains(element.code);
        return element;
      }).toList();
      getSelectedCountriesList().forEach((element) {
        checkEpgUrlByCountry(element.code!.toLowerCase())
            .then((value) => element.hasEpg.value = value);
      });
      countriesCount.value = countries.length;
    } else {
      countries.value = [];
      countriesCount.value = 0;
    }
    handleing.value = false;
    // getData();
  }

  void clearSelect() {
    countries.value = countries.map((element) {
      element.selected.value = false;
      return element;
    }).toList();
  }

  checkSelectedEpg(List<Data> selectedList) async {
    for (final item in selectedList) {
      if (item.hasEpg.value) {
        continue;
      }
      print('checkSelectedEpg');
      item.hasEpg.value = await checkEpgUrlByCountry(item.code!.toLowerCase());
    }
  }

  void selectItem(int index) async {
    // LU.d('selectitem $selected $index',tag: _TAG);
    countries[index].selected.value = !countries[index].selected.value;
    if (countries[index].selected.value && countries[index].code != null) {
      print('selectItem');
      countries[index].hasEpg.value =
          await checkEpgUrlByCountry(countries[index].code!.toLowerCase());
    }
  }

  int getSelectedCount() {
    return getSelectedCountriesList().length;
  }

  List<Data> getSelectedCountriesList() {
    return countries.where((p0) => p0.selected.value).toList();
  }

  List<String> getSelectedCountriesCodeList() {
    return getSelectedCountriesList()
        .map((e) => e.code)
        .map((e) => e ?? "")
        .toList();
  }

  void saveData() {
    LU.d('saveData', tag: _TAG);
    handleing.value = true;
    // SpUtil.putString('test', 'ddddddd');
    SpUtil.putStringList('selected_country', getSelectedCountriesCodeList());
    handleing.value = false;
    // SpUtil.putObjectList(key, list)
  }
}
