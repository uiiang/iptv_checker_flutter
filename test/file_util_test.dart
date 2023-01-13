import 'package:iptv_checker_flutter/utils/file_util.dart';
import 'package:test/test.dart';

void main() {
  group("测试文件辅助类", () {
    test("测试获取临时文件-检测可用文件", () async {
      final path = '${await FileUtil().getDirectory()}/tmp/available';
      final tmpAvailablePath = await FileUtil().getTmpAvailablePath();
      expect(path, equals(tmpAvailablePath));
    });
  });
}
