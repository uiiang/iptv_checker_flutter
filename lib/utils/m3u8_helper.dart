import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:iptv_checker_flutter/utils/api_service.dart';
import 'package:m3u_nullsafe/m3u_nullsafe.dart';

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
