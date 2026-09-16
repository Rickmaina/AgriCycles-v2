import 'package:flutter/foundation.dart';

/// Debug-gated logger. Never use print() / debugPrint() directly.
class Logger {
  Logger._(this._name);
  final String _name;

  static Logger of(String name) => Logger._(name);

  void info(String message) => _log('INFO', message);
  void warn(String message) => _log('WARN', message);

  void error(String message, [Object? error, StackTrace? stack]) {
    _log('ERROR', message);
    if (error != null && kDebugMode) {
      // ignore: avoid_print
      print('  ↳ $error');
      if (stack != null) {
        // ignore: avoid_print
        print('  ↳ $stack');
      }
    }
  }

  void _log(String level, String message) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[$level] $_name: $message');
  }
}
