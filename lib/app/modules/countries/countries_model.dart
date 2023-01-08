import 'package:get/get.dart';

class Countries {
  List<Data>? data;

  Countries({this.data});

  Countries.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
      });
    }
  }
}

class Data {
  String? name;
  String? code;
  List<String>? languages;
  String? flag;
  final selected=false.obs;
  late final focused = false.obs;

  Data({this.name, this.code, this.languages, this.flag});

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    code = json['code'];
    languages = json['languages'].cast<String>();
    flag = json['flag'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['name'] = name;
    data['code'] = code;
    data['languages'] = languages;
    data['flag'] = flag;
    return data;
  }
}
