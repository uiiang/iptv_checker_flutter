import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path_provider_android/path_provider_android.dart'
    as pathProviderAndroid;
import 'package:path_provider_linux/path_provider_linux.dart'
    as pathProviderLinux;
import 'package:path_provider_windows/path_provider_windows.dart'
    as pathProvderWindows;

class FileUtil {
  Future<File?> writeStringToFileOnce(File file, String content) async {
    try {
      return await file.writeAsString(content, mode: FileMode.write);
    } catch (e) {
      e.printError();
      return null;
    }
  }

  Future<File?> writeStringToFileAppend(File file, String appendContent) async {
    // File file = File(path);
    try {
      return await file.writeAsString(appendContent,
          mode: FileMode.append, flush: true);
    } catch (e) {
      e.printError();
      return null;
    }
  }

  Future<bool> dirIsExists(String path) async {
    final dir = Directory(path);
    return await dir.exists();
  }

  Future<bool> fileIsExists(String path) async {
    final file = File(path);
    return await file.existsSync();
  }

  Future<String> loadFileContent(String path) async {
    var file = File(path);
    return await file.readAsString();
  }

  Future<File> getOrCreateFile(String dir, String filename) async {
    final dirPath = await getOrCreatePath(dir);
    final file = File('$dirPath/$filename');
    if (file.existsSync()) {
      file.createSync();
    }
    return file;
  }

  Future<String> getOrCreatePath(String path) async {
    final tmpAvailablePath = '${await FileUtil().getDirectory()}/tmp/available';
    final isExists = await dirIsExists(tmpAvailablePath);
    if (isExists) {
      print('tmpAvailablePath isExists');
      return tmpAvailablePath;
    } else {
      try {
        final dir = await Directory(tmpAvailablePath).create(recursive: true);
        print('tmpAvailablePath not Exists and create ${dir.path}');
        return dir.path;
      } catch (e) {
        e.printError();
        print('tmpAvailablePath not Exists but create error');
        return "";
      }
    }
  }

  Future<FileSystemEntity> removeDir(String path) async {
    return (await Directory(path).delete(recursive: true));
  }

  Future<bool> removeFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await File(path).delete();
      return true;
    } else {
      return true;
    }
  }

  Future<String> getTmpPath() async {
    return getOrCreatePath('tmp');
  }

  Future<String> getTmpAvailablePath() async {
    return getOrCreatePath('tmp/available');
  }

  ///This method provides [Directory] for the file for Android, iOS, Linux, Windows, macOS
  Future<String?> getDirectory() async {
    String? _path = "";
    try {
      if (Platform.isIOS) {
        _path = (await path.getApplicationDocumentsDirectory()).path;
      } else if (Platform.isMacOS) {
        _path = (await path.getDownloadsDirectory())?.path;
      } else if (Platform.isWindows) {
        pathProvderWindows.PathProviderWindows pathWindows =
            pathProvderWindows.PathProviderWindows();
        _path = await pathWindows.getDownloadsPath();
      } else if (Platform.isLinux) {
        pathProviderLinux.PathProviderLinux pathLinux =
            pathProviderLinux.PathProviderLinux();
        _path = await pathLinux.getDownloadsPath();
      } else if (Platform.isAndroid) {
        pathProviderAndroid.PathProviderAndroid pathAndroid =
            pathProviderAndroid.PathProviderAndroid();
        _path = await pathAndroid.getExternalStoragePath();
      }
    } on Exception catch (e) {
      print("Something wemt worng while getting directories");
      print(e);
    }
    return _path;
  }
}
