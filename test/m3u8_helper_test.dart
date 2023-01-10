import 'package:iptv_checker_flutter/utils/m3u8_helper.dart';
import 'package:test/test.dart';

void main() {
  group("测试url连通", () {
    test("测试url连通_可用", () async {
      final sec = await checkUrlHttpClient(
          'http://39.134.115.163:8080/PLTV/88888910/224/3221225690/index.m3u8');
      expect(sec, lessThan(2000));
    });
    test("测试url连通_不可用", () async {
      //http://183.207.248.71/cntv/live1/henanstv/henanstv
      final sec = await checkUrlHttpClient(
          'http://125.210.152.18:9090/live/HNWSHD_H265.m3u8');
      expect(sec, greaterThan(2000));
    });

    test("测试获取epg", () async {
      await genEpgHelper(['cn']);
    });
  });
}
