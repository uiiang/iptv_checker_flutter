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
    fetchIptvCountries();
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

  /// ??????m3u8??????
  void genM3u8() async {
    FileUtil().removeDir(await FileUtil().getTmpPath());
    handleing.value = true;
    Iterable<Data> selectedList = getSelectedCountriesList();
    if (selectedList.isEmpty) {
      print('????????????m3u8??????????????????????????????????????????');
      handleing.value = false;
      return;
    }
    selectedList = selectedList.map((e) {
      e.status.value = "?????????...";
      return e;
    });
    print('?????????${selectedList.length}???????????????');
    if (Config.isCheckRealtime()) {
      print('??????????????????');
      initIsolateCheck();
      final availablePath = await FileUtil().getTmpAvailablePath();
      List<M3uGenericEntry> allAbleEntryList = [];
      // ??????????????????????????????????????????????????????
      selectedList.forEach((element) async {
        final request = CheckManager.instance.check(
          await getM3u8FileChannelListLocal(element.savePath),
          // path: '$availablePath/${element.code}.m3u'
        );

        // ??????????????????
        request.events.listen((event) async {
          if (event is CheckState) {
            print("event: $event");
            switch (event) {
              case CheckState.started:
                element.status.value = '????????????';
                break;
              case CheckState.finished:
                print('${element.name}????????????1');
                element.status.value = '????????????';
                break;
              case CheckState.allFinished:
                print('??????????????????1');
                finshCheckIsolate(); //??????????????????
                //??????????????????????????????
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
          element.status.value = '????????????';
          finshCheckIsolate();
        }, onDone: () async {
          print('${element.name}????????????2');
          element.status.value = '????????????';
          finshCheckIsolate();
        });
      });
    } else {
      print('??????????????????');
      File tmpAllAvailableFile = await FileUtil()
          .getOrCreateFile(await FileUtil().getTmpPath(), "all_available.m3u");
      FileUtil().writeStringToFileAppend(tmpAllAvailableFile, '#EXTM3U\n');
      genM3u8StatusCheck(tmpAllAvailableFile, selectedList);
    }
  }

  /// ??????m3u8????????????status???????????????online?????????????????????????????????????????????
  void genM3u8StatusCheck(
      File tmpAllAvailableFile, Iterable<Data> selectedList) async {
    StreamController<Data> dataController = StreamController();
    Stream<Data> stream = dataController.stream;
    int doneCount = 0;
    stream.listen((item) async {
      print("????????????${item.name}????????? savePath ${item.savePath}");
      item.status.value = "????????????...";
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
        item.status.value = item.okCount.value > 0 ? "????????????" : "????????????-???????????????";
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
        print("??????m3u?????? ???????????????$iptvChannelPath");
      } else {
        print("genM3u8StatusCheck ????????????????????????????????????");
        handleing.value = false;
      }
    });
    for (final item in selectedList) {
      dataController.add(item);
    }
    // handleing.value = false;
    print('genM3u8StatusCheck4');
  }

  /// ?????????????????????????????????????????????????????????????????????????????????
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

  ///????????????????????????????????????
  void toggleItem(int index) async {
    final item = countries[index];
    item.selected.value = !item.selected.value;
    if (item.selected.isFalse) {
      FileUtil().removeFile(item.availablePath);
      FileUtil().removeFile(item.savePath);
    }
    if (item.selected.value && item.code != null) {
      // ????????????????????????m3u?????????????????????????????????????????????
      loadChannelInfoToUI(item);
      // countries[index].hasEpg.value =
      //     await checkEpgUrlByCountry(countries[index].code!.toLowerCase());
    }
  }

  /// ????????????????????????m3u?????????????????????????????????????????????
  loadChannelInfoToUI(Data item) async {
    item.savePath = await downloadIptvFile(item.code!);
    M3uGenericEntryWarp entryWarp =
        await getM3u8FileChannelWrapLocal(item.savePath);
    item.channelCount.value = entryWarp.entryList.length;
    // entryWarp.headerEntry.attributes.entries.forEach((element) {
    //   print('${item.name} ${element.key}-${element.value}');
    // });
    // EPG??????
    // var attributes = entryWarp.headerEntry.attributes;

    // String xTvgUrls =
    //     attributes.containsKey('x-tvg-url') ? attributes['x-tvg-url']! : '';
    // if (xTvgUrls.isNotEmpty) {
    //   List<String> epgUrlList = xTvgUrls.split(',');
    //   convertEptUrl(epgUrlList);
    // }
  }

  /// ?????????????????????
  int getSelectedCount() {
    return getSelectedCountriesList().length;
  }

  /// ????????????????????????
  List<Data> getSelectedCountriesList() {
    return countries.where((p0) => p0.selected.value).toList();
  }

  /// ??????????????????????????????
  List<String> getSelectedCountriesCodeList() {
    return getSelectedCountriesList()
        .map((e) => e.code)
        .map((e) => e ?? "")
        .toList();
  }

  /// ???????????????????????????????????????
  void saveData() {
    LU.d('saveData', tag: _TAG);
    handleing.value = true;
    SpUtil.putStringList('selected_country', getSelectedCountriesCodeList());
    handleing.value = false;
  }
}
