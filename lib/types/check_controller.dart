part of '../widgets/check_url.dart';

/// Controller allows to expose the object outside of builder's body
class CheckWidgetController {
  CheckWidgetController();

  /// Interface to start the checking
  void Function()? _check;
  void check() {
    _check?.call();
  }

  /// Interface to pause the checking
  void Function()? _pause;
  void pause() {
    _pause?.call();
  }

  /// Interface to continue the checking
  void Function()? _resume;
  void resume() {
    _resume?.call();
  }

  /// Interface to cancel the checking
  void Function()? _cancel;
  void cancel() {
    _cancel?.call();
  }

  /// Interface to reset the [CheckRequest] stored in widget internally
  void Function()? _reset;
  void reset() {
    _reset?.call();
  }
}
