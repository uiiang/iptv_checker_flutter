import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:iptv_checker_flutter/utils/file_util.dart';

import '../app/modules/categories/categories_model.dart';
import '../app/modules/countries/countries_model.dart';

class ApiService {
  static const _TAG = 'ApiService';

  static Future<String> fetchIptvEpg(String url) async {
    print('url $url');
    //https://iptv-org.github.io/epg/guides/af.xml
    Dio().get(url).then((value) {
      print('response ${value}');
    }).onError((error, stackTrace) {
      print(error);
    });
    // Dio().close();
    return '';
  }

  static Future<String> downloadIptvDailyUpdateByCountry(String code) async {
    // final url =
    //     "https://ghproxy.net/https://raw.githubusercontent.com/iptv-org/iptv/master/streams/$code.m3u";
    // final url = "https://github.com/iptv-org/iptv/blob/master/streams/$code.m3u";
    // final url = "https://jsd.cdn.zzko.cn/gh/iptv-org/iptv@master/streams/$code.m3u";
    final url =
        "https://raw.fastgit.org/iptv-org/iptv/master/streams/$code.m3u";
    // final url = "https://raw.kgithub.com/iptv-org/iptv/master/streams/$code.m3u";
    final savePath =
        '${await FileUtil().getDirectory()}/tmp/source/daily_$code.m3u';
    print('downloadIptvDailyUpdateByCountry code $code');
    final response = await Dio().download(url, savePath);
    Dio().close();
    if (response.statusCode == 200) {
      return savePath;
    } else {
      return "";
    }
  }

  static Future<String> downloadIptvByCountry(String code) async {
    final savePath = '${await FileUtil().getDirectory()}/tmp/source/$code.m3u';
    final response = await Dio().download(
        "https://iptv-org.github.io/iptv/countries/$code.m3u", savePath);
    Dio().close();
    if (response.statusCode == 200) {
      return savePath;
    } else {
      return "";
    }
  }

  static Future<String> fetchIptvByCountry(String code) async {
    //  https://iptv-org.github.io/iptv/countries/af.m3u
    // https://raw.fastgit.org/iptv-org/iptv/master/streams/cn_cctv.m3u
    var response =
        await Dio().get("https://iptv-org.github.io/iptv/countries/$code.m3u");
    Dio().close();
    // print('response $response');
    return response.toString();
  }

  static Future<Countries> loadIptvCountries() async {
    //  https://iptv-org.github.io/api/countries.json
    // var response = await Dio().get(
    //     "https://iptv-org.github.io/api/categories.json");
    var response = await rootBundle.loadString("assets/countries.json");
    return Countries.fromJson(json.decode(response.toString()));
  }

  static Future<Categories> loadIptvCategories() async {
    //  https://iptv-org.github.io/api/categories.json
    //   var response = await Dio().get(
    //       "https://iptv-org.github.io/api/categories.json");
    //   var response = '{"data": [{"id":"auto","name":"Auto"},{"id":"animation","name":"Animation"},{"id":"business","name":"Business"},{"id":"classic","name":"Classic"},{"id":"comedy","name":"Comedy"},{"id":"cooking","name":"Cooking"},{"id":"culture","name":"Culture"},{"id":"documentary","name":"Documentary"},{"id":"education","name":"Education"},{"id":"entertainment","name":"Entertainment"},{"id":"family","name":"Family"},{"id":"general","name":"General"},{"id":"kids","name":"Kids"},{"id":"legislative","name":"Legislative"},{"id":"lifestyle","name":"Lifestyle"},{"id":"movies","name":"Movies"},{"id":"music","name":"Music"},{"id":"news","name":"News"},{"id":"outdoor","name":"Outdoor"},{"id":"relax","name":"Relax"},{"id":"religious","name":"Religious"},{"id":"series","name":"Series"},{"id":"science","name":"Science"},{"id":"shop","name":"Shop"},{"id":"sports","name":"Sports"},{"id":"travel","name":"Travel"},{"id":"weather","name":"Weather"},{"id":"xxx","name":"XXX"}]}';
    var response = await rootBundle.loadString("assets/categories.json");
    // LogUtil.d(response, tag: _TAG);
    return Categories.fromJson(json.decode(response));
  }
}
