import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../app/modules/categories/categories_model.dart';
import '../app/modules/countries/countries_model.dart';

class ApiService {
  static const _TAG = 'ApiService';

  static Future<String> fetchIptvEpg(String flag) async {
    //https://iptv-org.github.io/epg/guides/af.xml
    var response =
        await Dio().get('https://iptv-org.github.io/epg/guides/$flag.xml');
    return response.toString();
  }

  static Future<String> fetchIptvByCountry(String flag) async {
    //  https://iptv-org.github.io/iptv/countries/af.m3u
    // https://raw.fastgit.org/iptv-org/iptv/master/streams/cn_cctv.m3u
    var response = await Dio().get(
        "https://raw.fastgit.org/iptv-org/iptv/master/streams/${flag.toLowerCase()}.m3u");
    // print('response $response');
    return response.toString();
  }

  static Future<Countries> fetchIptvCountries() async {
    //  https://iptv-org.github.io/api/countries.json
    // var response = await Dio().get(
    //     "https://iptv-org.github.io/api/categories.json");
    var response = await rootBundle.loadString("assets/countries.json");
    return Countries.fromJson(json.decode(response.toString()));
  }

  static Future<Categories> fetchIptvCategories() async {
    //  https://iptv-org.github.io/api/categories.json
    //   var response = await Dio().get(
    //       "https://iptv-org.github.io/api/categories.json");
    //   var response = '{"data": [{"id":"auto","name":"Auto"},{"id":"animation","name":"Animation"},{"id":"business","name":"Business"},{"id":"classic","name":"Classic"},{"id":"comedy","name":"Comedy"},{"id":"cooking","name":"Cooking"},{"id":"culture","name":"Culture"},{"id":"documentary","name":"Documentary"},{"id":"education","name":"Education"},{"id":"entertainment","name":"Entertainment"},{"id":"family","name":"Family"},{"id":"general","name":"General"},{"id":"kids","name":"Kids"},{"id":"legislative","name":"Legislative"},{"id":"lifestyle","name":"Lifestyle"},{"id":"movies","name":"Movies"},{"id":"music","name":"Music"},{"id":"news","name":"News"},{"id":"outdoor","name":"Outdoor"},{"id":"relax","name":"Relax"},{"id":"religious","name":"Religious"},{"id":"series","name":"Series"},{"id":"science","name":"Science"},{"id":"shop","name":"Shop"},{"id":"sports","name":"Sports"},{"id":"travel","name":"Travel"},{"id":"weather","name":"Weather"},{"id":"xxx","name":"XXX"}]}';
    var response = await rootBundle.loadString("assets/categories.json");
    // LogUtil.d(response, tag: _TAG);
    return Categories.fromJson(json.decode(response));
  }
}
