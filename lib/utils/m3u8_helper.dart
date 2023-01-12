import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:iptv_checker_flutter/utils/api_service.dart';
import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:xml/xml.dart';

Future<int> checkUrlHttpClient(url, {timeout = 2000}) async {
  var start = DateTime.now();
  // print('checkUrlHttpClient $url');
  // final client = RetryClient(http.Client(), retries: retryTime);
  // try {
  //   client.get(Uri.parse(url));
  // } finally {
  //   client.close();
  // }
  try {
    HttpClient httpClient = HttpClient();
    httpClient.connectionTimeout = Duration(milliseconds: timeout);
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    if (response.statusCode == 200) {
      final diff = getDiff(start);
      // print('checkUrlHttpClient ok duration:$diff');
      return diff;
    } else {
      final diff = getDiff(start);
      print(
          'checkUrlHttpClient error duration:$diff statusCode:${response.statusCode} ');
      return -1;
    }
  } catch (e) {
    final diff = getDiff(start);
    print('onError duration:$diff expetion $e');
    return -1;
  }
}

int getDiff(DateTime start) {
  var end = DateTime.now().millisecondsSinceEpoch;
  var s = DateTime.fromMillisecondsSinceEpoch(end);
  return s.difference(start).inMilliseconds;
}

// dio的超时设置无效，使用checkUrlHttpClient方法来检测
Future<bool> checkUrl(url) async {
  var start = DateTime.now();
  try {
    final response = await Dio()
        .get(url, options: Options(sendTimeout: 1, receiveTimeout: 1),
            onReceiveProgress: (count, total) {
      print('count $count total $total');
    });
    if (response.statusCode == 200) {
      var end = DateTime.now().millisecondsSinceEpoch;
      var s = DateTime.fromMillisecondsSinceEpoch(end);
      print(' is ok ${s.difference(start).inMilliseconds}');
      // return start
      //     .difference(s)
      //     .inSeconds;
      return true;
    }
  } catch (e) {
    print(e);
    var end = DateTime.now().millisecondsSinceEpoch;
    var s = DateTime.fromMillisecondsSinceEpoch(end);
    print('ontimeout ${s.difference(start).inMilliseconds}');
    // return -1;
    return false;
  }
  // return -1;
  return false;
}

Future<String> saveM3u8File(content, filename, ext) async {
  List<int> textBytes = utf8.encode(content);

  String path = await FileSaver.instance.saveFile(
      filename, Uint8List.fromList((textBytes)), ext,
      mimeType: MimeType.TEXT);
  print('path $path');
  return path;
}

String createM3uContent(M3uGenericEntry m3uItem) {
  // #EXTM3U
// #EXTINF:-1 tvg-id="AnhuiSatelliteTV.cn" status="online",安徽卫视 (1080p)
// http://39.134.115.163:8080/PLTV/88888910/224/3221225691/index.m3u8
  String content = "";
  // for (final item in m3uItem) {
  final tvgid = 'tvg-id="${m3uItem.attributes["tvg-id"]}"';
  final status = 'status="${m3uItem.attributes["status"]}"';
  final title = m3uItem.title;
  content += '#EXTINF:-1 $tvgid $status,$title\n';
  content += '${m3uItem.link}\n';
  // }
  return content;
}

// 检查m3u文件中的status，返回online的数据，
// 不通过http请求测试连通性，速度快，但有些文件中没有status
Future<List<M3uGenericEntry>> getOnlineChannel(m3uData) async {
  final listOfTracks = await parseFile(m3uData);
  final statusList =
      sortedCategories(entries: listOfTracks, attributeName: 'status');
  return statusList['online'] ?? [];
}

Stream<List<M3uGenericEntry>> getAvailableChannel(m3uData) async* {
  List<M3uGenericEntry> availableList = [];
  final listOfTracks = await parseFile(m3uData);
  const timeout = 2000;
  // for (final item in listOfTracks) {
  for (var item in listOfTracks) {
    final duration = await checkUrlHttpClient(item.link, timeout: timeout);
    if (duration > 0 && timeout > duration) {
      availableList.add(item);
    }
    yield availableList;
  }
  // return availableList;
}

Future<List<M3uGenericEntry>> getChannelByCountryCode(String code) async {
  String m3uData = await ApiService.fetchIptvByCountry(code);
  return await parseFile(m3uData);
}

Stream<M3uGenericEntry?> getAvailableChannelByCountryCode(
    List<M3uGenericEntry> listOfTracks) async* {
  const timeout = 2000;
  for (final item in listOfTracks) {
    final duration = await checkUrlHttpClient(item.link, timeout: timeout);
    if (duration > 0 && timeout > duration) {
      // availableList.add(item);
      yield item;
    } else {
      yield null;
    }
  }
  // return channelData;
}

Future<List<M3uGenericEntry>> getOnlineChannelByCountryCode(String code) async {
  String m3uData = await ApiService.fetchIptvByCountry(code);
  List<M3uGenericEntry> channelData = await getOnlineChannel(m3uData);
  return channelData;
}

// 检测该国家code是否包含epg文件
Future<bool> checkEpgUrlByCountry(String code) async {
  const timeout = 5000;
  final sec = await checkUrlHttpClient(
      'https://iptv-org.github.io/epg/guides/$code.xml',
      timeout: timeout);
  return sec > 0 && timeout > sec;
}

Future<XmlDocument> getEpgByCountryCode(String code) async {
  String epgStr = await ApiService.fetchIptvEpg(code);
  return XmlDocument.parse(epgStr);
}

Future<bool> genEpgHelper(List<String?> codes) async {
  String content = "";
  for (final code in codes) {
    if (code == null) {
      continue;
    }
    print('start code $code');
    final xmlDoc = await getEpgByCountryCode(code);
    final channel = xmlDoc.findAllElements('channel');
    final programme = xmlDoc.findAllElements('programme');
    final child = xmlDoc.rootElement.childElements;
    print(
        'channel ${channel.length} programme ${programme.length} child ${child.length}');
  }
  return true;
}

// void genM3u8Helper(List<String?> codes) async {
//   String content = "#EXTM3U\n";
//   for (final item in codes) {
//     if (item == null) {
//       continue;
//     }
//     List<M3uGenericEntry> channelData =
//         await getOnlineChannelByCountryCode(item);
//     String m3uContent = createM3uContent(channelData);
//     print("genM3u $m3uContent");
//     if (m3uContent.isNotEmpty) {
//       content += "$m3uContent\n";
//     }
//   }
//   saveM3u8File(content, "iptv_channel", "m3u");
// }
