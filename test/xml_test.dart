import 'dart:convert';

import 'package:iptv_checker_flutter/utils/m3u8_helper.dart';
import 'package:test/test.dart';
import 'dart:io' show File, Directory;

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

void main() {
  String rootDirectory = "${Directory.current.path}/test";
  final String dataDirectory = "$rootDirectory/data";
  test("测试url连通_可用", () {
    print('dataDirectory $dataDirectory');
    final xmlDocFile = File('$dataDirectory/epg.xml');
    // final document = XmlDocument.parse(xmlDocFile.readAsStringSync());
    parseEvents(xmlDocFile.readAsStringSync())
        .whereType<XmlCDATAEvent>()
        .map((event) => event.text.trim())
        .where((text) => text.isNotEmpty)
        .forEach(print);
    // print(document.rootElement.childElements);
    // writeEpgFile('$dataDirectory/gen_epg.xml', document.rootElement.innerXml);
    // convertEptUrl(['https://iptv-org.github.io/epg/guides/cs/m.tv.sms.cz.xml']);
  });
}
