import 'dart:io';

import 'package:m3u_nullsafe/m3u_nullsafe.dart';
import 'package:test/test.dart';

void main() {
  group("测试m3u操作", () {
    test("测试解析", () async {
      final fileContent = await File('test/data/ad.m3u').readAsString();
      List<M3uGenericEntry> entryList = await M3uParser.parse(fileContent);
      entryList.forEach((element) {
        print('title ${element.title} link ${element.link}');
        element.attributes.entries.forEach((attr) {
          print('attr ${attr.key} = ${attr.value}');
        });
      });
    });
    // test("测试解析online_1", () async {
    //   final fileContent = await File('test/data/cn.m3u').readAsString();
    //   List<M3uGenericEntry> channelData = await getOnlineChannel(fileContent);
    //   expect(104, equals(channelData.length));
    //   M3uGenericEntry entry = channelData.first;
    //
    //   expect('安徽卫视 (1080p)', equals(entry.title));
    // });
    // test("测试解析online_2", () async {
    //   final fileContent = await File('test/data/jp.m3u').readAsString();
    //   List<M3uGenericEntry> channelData = await getOnlineChannel(fileContent);
    //   expect(0, equals(channelData.length));
    // });

    // test("测试写文件", () async {
    //   String path = await saveM3u8File("abcd", "test_write", "txt");
    //   print('path $path');
    //   // expect("test_write.txt", endsWith(path));
    // });

    // test("测试生成m3u字符串", () async {
    //   final fileContent = await File('test/data/cn.m3u').readAsString();
    //   List<M3uGenericEntry> channelData = await getOnlineChannel(fileContent);
    //   String content = "#EXTM3U\n${createM3uContent(channelData)}";
    //   // print('content $content');
    //   final listOfTracks = await parseFile(content);
    //
    //   expect(104, equals(listOfTracks.length));
    // });
  });
}
