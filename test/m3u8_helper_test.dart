import 'dart:io';

import 'package:iptv_checker_flutter/utils/m3u8_helper.dart';
import 'package:test/test.dart';

void main() {
  HttpClient httpClient = HttpClient();
  httpClient.connectionTimeout = Duration(milliseconds: 2000);
  group("测试url连通", () {
    test("测试url连通_可用", () async {
      final sec = await checkUrlHttpClient(httpClient,
          'http://39.134.115.163:8080/PLTV/88888910/224/3221225690/index.m3u8');
      expect(sec, lessThan(2000));
    });
    test("测试url连通_不可用", () async {
      //http://183.207.248.71/cntv/live1/henanstv/henanstv
      final sec = await checkUrlHttpClient(
          httpClient, 'http://125.210.152.18:9090/live/HNWSHD_H265.m3u8');
      expect(sec, greaterThan(2000));
    });

    test("测试url连通_可用-使用dio", () async {
      final sec = await checkUrl(
          'http://39.134.115.163:8080/PLTV/88888910/224/3221225691/index.m3u8');
      print("测试url连通_可用-使用dio $sec");
      expect(sec, lessThan(5000));
    });
    test("测试url连通_不可用-使用dio", () async {
      //http://183.207.248.71/cntv/live1/henanstv/henanstv
      final sec = await checkUrl(
          'https://bloomberg.com/media-manifest/streams/asia-event.m3u8',
          timeout: 10);
      print("测试url连通_不可用-使用dio $sec");
      expect(sec, equals(true));
    });

    // test("测试获取epg", () async {
    //   await genEpgHelper(['cn']);
    // });
  });
}
