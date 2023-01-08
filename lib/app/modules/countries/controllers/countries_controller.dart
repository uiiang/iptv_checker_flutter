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
  final logList = <String>[].obs;

  @override
  void onInit() {
    LU.d('onInit', tag: _TAG);
    super.onInit();
    fetchIptvCountries();
  }

  void genM3u8() async {
    logList.clear();
    String content = "#EXTM3U\n";
    Iterable<Data> selecteds =
        countries.where((p0) => p0.selected.value == true);
    List<String> countryCodes = selecteds.map((e) => e.code ?? "").toList();
    SpUtil.putStringList("selected_country", countryCodes);
    if (selecteds.isNotEmpty) {
      logList.add('共选择${selecteds.length}个国家频道');
      print('共选择${selecteds.length}个国家频道');
      for (final item in selecteds) {
        if (item.code != null) {
          logList.add("开始解析${item.name}的频道");
          print("开始解析${item.name}的频道");
          List<M3uGenericEntry> channelData =
              await getOnlineChannelByCountryCode(item.code!);
          logList.add("共找到${channelData.length}个可用的频道");
          print("共找到${channelData.length}个可用的频道");
          if (channelData.isNotEmpty) {
            logList.add("开始生成${item.name}的m3u8内容");
            print("开始生成${item.name}的m3u8内容");
            content += createM3uContent(channelData);
          } else {
            logList.add("${item.name}频道无可用 跳过");
            print("${item.name}频道无可用 跳过");
          }
        }
      }
      // print('content $content');
      // genM3u8Helper(codes);
      String path = await saveM3u8File(content, "iptv_channel", "m3u");
      logList.add("生成m3u结束 文件保存在$path");
      print("生成m3u结束 文件保存在$path");
    }
  }

  void fetchIptvCountries() async {
    List<String> selectedCountry =
        SpUtil.getStringList("selected_country") ?? [];
    print("fetchIptvCountries ${selectedCountry.length}");
    var content = await ApiService.fetchIptvCountries();
    if (content.data != null) {
      countries.value = content.data!.map((element) {
        element.selected.value = selectedCountry.contains(element.code);
        return element;
      }).toList();
      countriesCount.value = countries.length;
    } else {
      countries.value = [];
      countriesCount.value = 0;
    }
    // getData();
  }

  int getSelectedCount() {
    return countries.where((p0) => p0.selected.value == true).length;
  }

  void clearSelect() {
    countries.value = countries.map((element) {
      element.selected.value = false;
      return element;
    }).toList();
  }

  void selectItem(int index) {
    // LU.d('selectitem $selected $index',tag: _TAG);
    countries.value[index].selected.value =
        !countries.value[index].selected.value;
  }

  void saveData() {
    LU.d('saveData', tag: _TAG);
    // SpUtil.putString('test', 'ddddddd');
    SpUtil.putObjectList('countries', countries.value);
    // SpUtil.putObjectList(key, list)
  }

  void getData() {
    LU.d('in getData', tag: _TAG);
    // LU.d(SpUtil.getString('test'),tag:_TAG);
    var i = SpUtil.getObjectList('countries');
    LU.d(i, tag: _TAG);
    countries.value = i!.cast<Data>();
    countriesCount.value = countries.length;
  }
}
