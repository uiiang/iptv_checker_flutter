import 'dart:async';
import 'dart:io';

import 'package:flustars/flustars.dart';
import 'package:get/get.dart';
import 'package:iptv_check_manager/iptv_check_manager.dart';
import 'package:iptv_checker_flutter/app/modules/countries/countries_model.dart';
import 'package:iptv_checker_flutter/config.dart';
import 'package:iptv_checker_flutter/utils/api_service.dart';
import 'package:iptv_checker_flutter/utils/file_util.dart';
import 'package:iptv_checker_flutter/utils/log_util.dart';
import 'package:iptv_checker_flutter/utils/m3u8_helper.dart';
import 'package:m3u/m3u.dart';
import 'package:worker_manager/worker_manager.dart';

class StatusInfo {
  int okCount = 0;
  int errorCount = 0;
  List<M3uGenericEntry> onlineEntryList = [];
}

Future<StatusInfo> checkStatusOnline(
    String savePath,
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
    StatusInfo statusInfo = StatusInfo();
    // statusInfo.onlineEntryList = onlineEntryList;
    statusInfo.okCount = onlineEntryList.length;
    statusInfo.errorCount = allChannelCount - onlineEntryList.length;
    return statusInfo;
  } else {
    return StatusInfo();
  }
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
    // fetchIptvCountries();
  }

  @override
  void onClose() {
    CheckManager.instance.dispose();
    super.onClose();
  }

  void toggleSetting() {
    setting.value = !setting.value;
  }

  void initIsolateCheck() async {
    CheckManager.instance
        .init(isolates: 2, directory: await FileUtil().getTmpPath());
  }

  void finshCheckIsolate() async {
    await Future.delayed(const Duration(seconds: 1));
    CheckManager.instance.dispose().then((value) {
      handleing.value = false;
    });
  }

  /// 生成m3u8文件
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
    if (Config.isCheckRealtime()) {
      print('使用实时检测');
      initIsolateCheck();
      final availablePath = await FileUtil().getTmpAvailablePath();
      List<M3uGenericEntry> allAbleEntryList = [];
      // 将选中的国家代码加载到线程中等待检测
      selectedList.forEach((element) async {
        final request = CheckManager.instance.check(
          await getM3u8FileChannelListLocal(element.savePath),
          // path: '$availablePath/${element.code}.m3u'
        );

        // 监听检测状态
        request.events.listen((event) async {
          if (event is CheckState) {
            print("event: $event");
            switch (event) {
              case CheckState.started:
                element.status.value = '正在检测';
                break;
              case CheckState.finished:
                print('${element.name}检测完毕1');
                element.status.value = '检测完毕';
                break;
              case CheckState.allFinished:
                print('全部检测完毕1');
                finshCheckIsolate(); //关闭检测线程
                //将可用数据保存到文件
                final iptvChannelPath =
                    '${await FileUtil().getDirectory()}/iptv_channel.m3u';
                writeM3uEntryListToFile(allAbleEntryList, iptvChannelPath);
                break;
            }
          } else if (event is ProgressStatus) {
            if (event.taskState == TaskState.success) {
              element.okCount.value += 1;
              allAbleEntryList.add(event.channel!);
            } else {
              element.errorCount.value += 1;
            }
          }
        }, onError: (error) {
          element.status.value = '检测出错';
          finshCheckIsolate();
        }, onDone: () async {
          print('${element.name}检测完毕2');
          element.status.value = '检测完毕';
          finshCheckIsolate();
        });
      });
    } else {
      print('使用状态检测');
      File tmpAllAvailableFile = await FileUtil()
          .getOrCreateFile(await FileUtil().getTmpPath(), "all_available.m3u");
      FileUtil().writeStringToFileAppend(tmpAllAvailableFile, '#EXTM3U\n');
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
      print("开始检测${item.name}的频道 savePath ${item.savePath}");
      item.status.value = "开始检测...";
      final availablePath =
          '${await FileUtil().getTmpAvailablePath()}/${item.code}.m3u';
      item.availablePath = availablePath;
      File currentAllAvailableFile = File(availablePath);
      Executor()
          .execute(
              arg1: item.savePath,
              arg2: currentAllAvailableFile,
              arg3: tmpAllAvailableFile,
              fun3: checkStatusOnline)
          .then((value) {
        // print('Executor ${value}');
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
      bool genSuccess =
          await genChannelToM3uFile(tmpAllAvailableFile.path, iptvChannelPath);
      if (genSuccess) {
        handleing.value = false;
        print("生成m3u结束 文件保存在$iptvChannelPath");
      } else {
        print("genM3u8StatusCheck 生成最终文件失败，请重试");
        handleing.value = false;
      }
    });
    for (final item in selectedList) {
      dataController.add(item);
    }
    // handleing.value = false;
    print('genM3u8StatusCheck4');
  }

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
        loadChannelInfoToUI(element);
      });
      countriesCount.value = countries.length;
    } else {
      countries.value = [];
      countriesCount.value = 0;
    }
    handleing.value = false;
  }

  void clearSelect() {
    countries.value = countries.map((element) {
      element.selected.value = false;
      FileUtil().removeFile(element.availablePath);
      FileUtil().removeFile(element.savePath);
      return element;
    }).toList();
  }

  ///切换是否选择选择一个国家
  void toggleItem(int index) async {
    final item = countries[index];
    item.selected.value = !item.selected.value;
    if (item.selected.isFalse) {
      FileUtil().removeFile(item.availablePath);
      FileUtil().removeFile(item.savePath);
    }
    if (item.selected.value && item.code != null) {
      // 根据国家代码下载m3u文件到临时目录，并解析频道数量
      loadChannelInfoToUI(item);
      // countries[index].hasEpg.value =
      //     await checkEpgUrlByCountry(countries[index].code!.toLowerCase());
    }
  }

  /// 根据国家代码下载m3u文件到临时目录，并解析频道数量
  loadChannelInfoToUI(Data item) async {
    item.savePath = await downloadIptvFile(item.code!);
    M3uGenericEntryWarp entryWarp =
        await getM3u8FileChannelWrapLocal(item.savePath);
    item.channelCount.value = entryWarp.entryList.length;
    // entryWarp.headerEntry.attributes.entries.forEach((element) {
    //   print('${item.name} ${element.key}-${element.value}');
    // });
    // EPG文件
    // var attributes = entryWarp.headerEntry.attributes;

    // String xTvgUrls =
    //     attributes.containsKey('x-tvg-url') ? attributes['x-tvg-url']! : '';
    // if (xTvgUrls.isNotEmpty) {
    //   List<String> epgUrlList = xTvgUrls.split(',');
    //   convertEptUrl(epgUrlList);
    // }
  }

  /// 选中的国家数量
  int getSelectedCount() {
    return getSelectedCountriesList().length;
  }

  /// 过滤出选中的国家
  List<Data> getSelectedCountriesList() {
    return countries.where((p0) => p0.selected.value).toList();
  }

  /// 过滤出选中的国家代码
  List<String> getSelectedCountriesCodeList() {
    return getSelectedCountriesList()
        .map((e) => e.code)
        .map((e) => e ?? "")
        .toList();
  }

  /// 将选中的国家代码保存到缓存
  void saveData() {
    LU.d('saveData', tag: _TAG);
    handleing.value = true;
    SpUtil.putStringList('selected_country', getSelectedCountriesCodeList());
    handleing.value = false;
  }
}
