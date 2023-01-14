import 'dart:async';
import 'dart:io';

import 'package:flustars/flustars.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/countries_model.dart';
import 'package:iptv_checker_flutter/config.dart';
import 'package:iptv_checker_flutter/utils/api_service.dart';
import 'package:iptv_checker_flutter/utils/file_util.dart';
import 'package:iptv_checker_flutter/utils/log_util.dart';
import 'package:iptv_checker_flutter/utils/m3u8_helper.dart';
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:worker_manager/worker_manager.dart';

class StatusInfo {
  int okCount = 0;
  int errorCount = 0;
  List<M3uGenericEntry> onlineEntryList = [];
}

Future<StatusInfo> checkStatusOnline(
    String savePath,
    String availablePath,
    File currentAllAvailableFile,
    File tmpAllAvailableFile,
    TypeSendPort port) async {
  List<M3uGenericEntry> onlineEntryList = await getOnlineChannelLocal(savePath);
  int allChannelCount = await getM3u8FileChannelCount(savePath);
  if (onlineEntryList.isNotEmpty) {
    Iterable<String> m3uDataList =
        onlineEntryList.map((e) => createM3uContent(e));
    File? file = await FileUtil().writeStringToFileOnce(
        currentAllAvailableFile, '#EXTM3U\n${m3uDataList.join("")}');
    List<M3uGenericEntry> entryList =
        await getM3u8FileChannelListLocalFile(file!);
    Iterable<String> currentAbleContent =
        entryList.map((entry) => createM3uContent(entry));
    print('currentAbleContent ${currentAbleContent.length}');
    await FileUtil().writeStringToFileAppend(
        tmpAllAvailableFile, currentAbleContent.join(""));
  }
  StatusInfo statusInfo = StatusInfo();
  // statusInfo.onlineEntryList = onlineEntryList;
  statusInfo.okCount = onlineEntryList.length;
  statusInfo.errorCount = allChannelCount - onlineEntryList.length;
  return statusInfo;
}

class CountriesController extends GetxController {
  static const _TAG = 'CountriesController';
  final countries = <Data>[].obs;
  final countriesCount = 0.obs;
  final handleing = false.obs;
  final setting = false.obs;

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

  void toggleSetting() {
    setting.value = !setting.value;
  }

  void genM3u8() async {
    FileUtil().removeDir(await FileUtil().getTmpPath());
    handleing.value = true;
    Iterable<Data> selectedList = getSelectedCountriesList();
    if (selectedList.isEmpty) {
      print('开始生成m3u8文件，无选中的国家，停止生成');
      handleing.value = false;
      return;
    }
    selectedList = selectedList.map((e) {
      e.status.value = "等待中...";
      return e;
    });
    print('共选择${selectedList.length}个国家频道');
    File tmpAllAvailableFile = await FileUtil()
        .getOrCreateFile(await FileUtil().getTmpPath(), "all_available.m3u");
    FileUtil().writeStringToFileAppend(tmpAllAvailableFile, '#EXTM3U\n');
    if (Config.isCheckRealtime()) {
      genM3u8RealTimeCheck(tmpAllAvailableFile, selectedList);
    } else {
      genM3u8StatusCheck(tmpAllAvailableFile, selectedList);
    }
  }

  /// 检测m3u8文件中的status标签，返回online，但是有些文件中不包含这个标签
  void genM3u8StatusCheck(
      File tmpAllAvailableFile, Iterable<Data> selectedList) async {
    StreamController<Data> dataController = StreamController();
    Stream<Data> stream = dataController.stream;
    int doneCount = 0;
    stream.listen((item) async {
      print("开始检测${item.name}的频道");
      item.status.value = "开始检测...";
      print('${item.name} savePath ${item.savePath}');
      final availablePath =
          '${await FileUtil().getTmpAvailablePath()}/${item.code}.m3u';
      item.availablePath = availablePath;
      File currentAllAvailableFile = File(availablePath);
      Executor()
          .execute(
              arg1: item.savePath,
              arg2: item.availablePath,
              arg3: currentAllAvailableFile,
              arg4: tmpAllAvailableFile,
              fun4: checkStatusOnline)
          .then((value) {
        print('Executor ${value.okCount}');
        item.status.value = item.okCount.value > 0 ? "完成检测" : "完成检测-无可用频道";
        item.okCount.value = value.okCount;
        item.errorCount.value = value.errorCount;
        doneCount += 1;
        if (doneCount == selectedList.length) {
          dataController.close();
        }
      });
    }).onDone(() async {
      final iptvChannelPath =
          '${await FileUtil().getDirectory()}/iptv_channel.m3u';
      await FileUtil().removeFile(iptvChannelPath);
      getM3u8FileChannelListLocal(tmpAllAvailableFile.path)
          .then((m3uEntryList) async {
        Map<String, String> m3uEntryMap = {};
        m3uEntryList.forEach((element) {
          m3uEntryMap[element.link] = createM3uContent(element);
        });
        print('全部频道检测完毕 ${m3uEntryList.length}个可用频道, 去重后${m3uEntryMap.length}');
        print("开始制作m3u8文件...");
        await FileUtil().writeStringToFileOnce(
            File(iptvChannelPath), '#EXTM3U\n${m3uEntryMap.values.join("")}');
        handleing.value = false;
        print("生成m3u结束 文件保存在$iptvChannelPath");
      });
    });
    for (final item in selectedList) {
      dataController.add(item);
    }
    // handleing.value = false;
    print('genM3u8StatusCheck4');
  }

  void genM3u8RealTimeCheck(tmpAllAvailableFile, selectedList) async {
    HttpClient httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(milliseconds: 2000);
    for (final item in selectedList) {
      print('${item.name} savePath ${item.savePath}');
    }
  }

  /// 实时检测m3u8频道是否可用
  // void genM3u8RealTimeCheck(tmpAllAvailableFile, selectedList) async {
  //   HttpClient httpClient = HttpClient();
  //   httpClient.connectionTimeout = const Duration(milliseconds: 2000);
  //   StreamController<Data> dataController = StreamController();
  //   Stream<Data> stream = dataController.stream;
  //   int doneCount = 0;
  //   stream.listen((item) async {
  //     print("开始检测${item.name}的频道");
  //     item.status.value = "开始检测...";
  //     //解析m3u文件到list，如果本地有保存文件直接解析，如果没有重新下载再解析
  //     final listOfTracks = await getChannelList(item);
  //     item.channelCount.value = listOfTracks.length;
  //     // List<M3uGenericEntry> currCodeEntry = [];
  //     int errorCount = 0;
  //     int okCount = 0;
  //     final availablePath =
  //         '${await FileUtil().getTmpAvailablePath()}/${item.code}.m3u';
  //     item.availablePath = availablePath;
  //     print('availablePath $availablePath');
  //     File currentAllAvailableFile = File(availablePath);
  //     FileUtil().writeStringToFileAppend(currentAllAvailableFile, '#EXTM3U\n');
  //     getAvailableChannelByCountryCode(httpClient, listOfTracks).listen(
  //         (availableChannel) {
  //       if (availableChannel != null) {
  //         FileUtil().writeStringToFileAppend(
  //             currentAllAvailableFile, createM3uContent(availableChannel));
  //         okCount += 1;
  //       } else {
  //         errorCount += 1;
  //       }
  //       item.okCount.value = okCount;
  //       item.errorCount.value = errorCount;
  //       item.status.value = "正在检测...";
  //     }, onError: (err) {
  //       print('check ${item.name}频道发生错误, $err');
  //     }).onDone(() {
  //       if (item.okCount.value > 0) {
  //         print("${item.name}完成检测,${item.okCount.value}个可用的频道");
  //         item.status.value = "完成检测";
  //         // allCodeEntry.addAll(currCodeEntry);
  //       } else {
  //         item.status.value = "完成检测-无可用频道";
  //       }
  //       getM3u8FileChannelListLocal(item.availablePath)
  //           .then((m3uEntryList) async {
  //         List<String> currentAbleContent = m3uEntryList
  //             .map((entry) => createM3uContent(entry))
  //             .toSet()
  //             .toList();
  //         await FileUtil().writeStringToFileAppend(
  //             tmpAllAvailableFile, currentAbleContent.join(""));
  //         // FileUtil().writeStringToFileOnce(tmpAllAvailableFile, content.join(""));
  //       }).then((value) {
  //         doneCount += 1;
  //         if (doneCount == selectedList.length) {
  //           dataController.close();
  //         }
  //       });
  //     });
  //   }, onError: (e) {
  //     print('check all onError $e');
  //   }, onDone: () async {
  //     final iptvChannelPath =
  //         '${await FileUtil().getDirectory()}/iptv_channel.m3u';
  //     await FileUtil().removeFile(iptvChannelPath);
  //     getM3u8FileChannelListLocal(tmpAllAvailableFile.path)
  //         .then((m3uEntryList) async {
  //       Map<String, String> m3uEntryMap = {};
  //       m3uEntryList.forEach((element) {
  //         m3uEntryMap[element.link] = createM3uContent(element);
  //       });
  //       print('全部频道检测完毕 ${m3uEntryList.length}个可用频道, 去重后${m3uEntryMap.length}');
  //       print("开始制作m3u8文件...");
  //       await FileUtil().writeStringToFileOnce(
  //           File(iptvChannelPath), '#EXTM3U\n${m3uEntryMap.values.join("")}');
  //       handleing.value = false;
  //       print("生成m3u结束 文件保存在$iptvChannelPath");
  //     });
  //   });
  //   for (final item in selectedList) {
  //     if (item.code == null) {
  //       continue;
  //     }
  //     dataController.add(item);
  //   }
  // }

  /// 读取国家列表，根据上次保存的选择列表，修改默认选中状态
  void fetchIptvCountries() async {
    print('storage path = ${await FileUtil().getTmpPath()}');
    print('tmp path = ${await FileUtil().getTmpPath()}');
    print('tmp able path = ${await FileUtil().getTmpAvailablePath()}');
    handleing.value = true;
    // await isolateManager.start();
    var countryList = await ApiService.loadIptvCountries();
    if (countryList.data != null) {
      List<String> selectedCountry =
          SpUtil.getStringList("selected_country") ?? [];
      print("fetchIptvCountries ${selectedCountry.length}");
      countries.value = countryList.data!.map((element) {
        element.selected.value = selectedCountry.contains(element.code);
        return element;
      }).toList();
      if (Config.checkEpg()) {
        // getSelectedCountriesList().forEach((element) {
        //   checkEpgUrlByCountry(element.code!.toLowerCase())
        //       .then((value) => element.hasEpg.value = value);
        // });
      }
      getSelectedCountriesList().forEach((element) {
        loadChannelCountToUI(element);
      });
      countriesCount.value = countries.length;
    } else {
      countries.value = [];
      countriesCount.value = 0;
    }
    handleing.value = false;
  }

  /// 根据国家代码下载m3u文件到临时目录，并解析频道数量
  void loadChannelCountToUI(Data element) async {
    final savePath = Config.isCheckRealtime()
        ? await downloadIptvByCountryToLocal(element.code!)
        : await downloadIptvDailyUpdateByCountry(element.code!);
    if (savePath.isNotEmpty) {
      element.savePath = savePath;
      getM3u8FileChannelCount(savePath)
          .then((value) => element.channelCount.value = value);
    }
  }

  void clearSelect() {
    countries.value = countries.map((element) {
      element.selected.value = false;
      FileUtil().removeFile(element.availablePath);
      FileUtil().removeFile(element.savePath);
      return element;
    }).toList();
  }

  checkSelectedEpg(List<Data> selectedList) async {
    HttpClient httpClient = HttpClient();
    httpClient.connectionTimeout = Duration(milliseconds: 2000);
    for (final item in selectedList) {
      if (item.hasEpg.value) {
        continue;
      }
      print('checkSelectedEpg');
      item.hasEpg.value = await checkEpgUrlByCountry(httpClient, item.code!);
    }
  }

  void selectItem(int index) async {
    final item = countries[index];
    item.selected.value = !item.selected.value;
    if (item.selected.isFalse) {
      FileUtil().removeFile(item.availablePath);
      FileUtil().removeFile(item.savePath);
    }
    if (item.selected.value && item.code != null) {
      loadChannelCountToUI(item);
      // countries[index].hasEpg.value =
      //     await checkEpgUrlByCountry(countries[index].code!.toLowerCase());
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
