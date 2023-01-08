import 'package:logger/logger.dart';

class LU {
  static const String _defTag = 'common_utils';
  static bool _debugMode = true; //是否是debug模式,true: log v 不输出.
  static int _maxLen = 128;
  static String _tagValue = _defTag;
  static var logger = Logger();

  static void init({
    String tag = _defTag,
    bool isDebug = false,
    int maxLen = 128,
  }) {
    _tagValue = tag;
    _debugMode = isDebug;
    _maxLen = maxLen;
    logger = Logger(
      printer: PrettyPrinter(
          methodCount: 2,
          // number of method calls to be displayed
          errorMethodCount: 8,
          // number of method calls if stacktrace is provided
          lineLength: 120,
          // width of the output
          colors: true,
          // Colorful log messages
          printEmojis: true,
          // Print an emoji for each log message
          printTime: false // Should each log print contain a timestamp
      ),
    );
  }

  static void d(Object? object, {String? tag}) {
    if (_debugMode) {
      logger.d('$tag d | ${object?.toString()}');
    }
  }

  static void e(Object? object, {String? tag}) {
    logger.e('$tag d | ${object?.toString()}');
  }

  static void v(Object? object, {String? tag}) {
    if (_debugMode) {
      logger.v('$tag d | ${object?.toString()}');
    }
  }
}
