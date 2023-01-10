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
  print('checkUrlHttpClient $url');
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
      print(' is ok $diff');
      return diff;
    } else {
      final diff = getDiff(start);
      print('statuscode ${response.statusCode} $diff');
      return diff;
    }
  } catch (e) {
    print(e);
    final diff = getDiff(start);
    print('onError $diff');
    return diff;
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
    print('onError ${s.difference(start).inMilliseconds}');
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

String createM3uContent(List<M3uGenericEntry> m3uItem) {
  // #EXTM3U
// #EXTINF:-1 tvg-id="AnhuiSatelliteTV.cn" status="online",安徽卫视 (1080p)
// http://39.134.115.163:8080/PLTV/88888910/224/3221225691/index.m3u8
  String content = "";
  for (final item in m3uItem) {
    final tvgid = 'tvg-id="${item.attributes["tvg-id"]}"';
    final status = 'status="${item.attributes["status"]}"';
    final title = item.title;
    content += '#EXTINF:-1 $tvgid $status,$title\n';
    content += '${item.link}\n';
  }
  return content;
}

Future<List<M3uGenericEntry>> getOnlineChannel(m3uData) async {
  final listOfTracks = await parseFile(m3uData);
  final statusList =
      sortedCategories(entries: listOfTracks, attributeName: 'status');
  return statusList['online'] ?? [];
}

Future<List<M3uGenericEntry>> getOnlineChannelByCountryCode(String code) async {
  String m3uData = await ApiService.fetchIptvByCountry(code);
  List<M3uGenericEntry> channelData = await getOnlineChannel(m3uData);
  return channelData;
  // return createM3uContent(channelData);
}

Future<bool> checkEpgUrlByCountry(String code) async {
  const timeout = 5000;
  final sec = await checkUrlHttpClient(
      'https://iptv-org.github.io/epg/guides/$code.xml',
      timeout: timeout);
  return timeout > sec;
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
    // channelList.setAll(0, channel);
    // programmeList.setAll(0, programme);
    final child = xmlDoc.rootElement.childElements;
    print(
        'channel ${channel.length} programme ${programme.length} child ${child.length}');
    // for (final ch in child) {
    //   print('ch $ch');
    // }
  }
  // final builder = XmlBuilder();
  // builder.processing('tv', 'date="1.0"');
  // builder
  return true;
}

void genM3u8Helper(List<String?> codes) async {
  String content = "#EXTM3U\n";
  for (final item in codes) {
    if (item == null) {
      continue;
    }
    List<M3uGenericEntry> channelData =
        await getOnlineChannelByCountryCode(item);
    String m3uContent = createM3uContent(channelData);
    print("genM3u $m3uContent");
    if (m3uContent.isNotEmpty) {
      content += "$m3uContent\n";
    }
  }
  saveM3u8File(content, "iptv_channel", "m3u");
}
