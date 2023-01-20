import 'package:flutter/material.dart';
import 'package:iptv_check_manager/iptv_check_manager.dart';
import 'package:iptv_checker_flutter/types/check_state.dart';
import 'package:m3u/m3u.dart';
part 'package:iptv_checker_flutter/types/check_controller.dart';

/// Builder function for each state of file checking
/// [CheckRequest] stored and controlled internally, by providing the [CheckWidgetController] interface
class CheckUrlWidget extends StatefulWidget {
  const CheckUrlWidget(
      {super.key,
      required this.builder,
      required this.m3uEntryList,
      this.path,
      this.controller,
      this.manager})
      : super();

  /// Builder is required to build the UI based on current check state
  final Widget Function(
    BuildContext context,
    CheckWidgetController controller,
    CheckWidgetState state,
    double? progress,
    Object? error,
    CheckRequest? request,
  ) builder;

  /// File url
  final List<M3uGenericEntry> m3uEntryList;

  /// Destination file location
  final String? path;

  /// Manager instanse, if not provided the default one is used
  final CheckManager? manager;

  /// Controller, if not provided the default one is used
  final CheckWidgetController? controller;

  @override
  State<CheckUrlWidget> createState() => _CheckUrlWidgetState();
}

class _CheckUrlWidgetState extends State<CheckUrlWidget> {
  late CheckManager manager;
  late CheckWidgetController controller;
  CheckRequest? request;

  @override
  void initState() {
    super.initState();
    manager = widget.manager ?? CheckManager.instance;

    controller = widget.controller ?? CheckWidgetController();
    controller._check = _check;
    controller._cancel = _cancel;
    controller._resume = _resume;
    controller._pause = _pause;
    controller._reset = _reset;
  }

  @override
  Widget build(BuildContext context) {
    if (request == null) {
      return widget.builder(
          context, controller, CheckWidgetState.initial, null, null, request);
    }

    return StreamBuilder(
        stream: request!.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return widget.builder(context, controller, CheckWidgetState.failed,
                null, null, request);
          }

          if (snapshot.hasData) {
            final data = snapshot.data!;
            if (data is double) {
              return widget.builder(context, controller,
                  CheckWidgetState.checking, data, null, request);
            }

            switch (data as CheckState) {
              case CheckState.queued:
                return widget.builder(context, controller,
                    CheckWidgetState.queued, null, null, request);
              case CheckState.started:
              case CheckState.resumed:
                return widget.builder(context, controller,
                    CheckWidgetState.checking, null, null, request);
              case CheckState.paused:
                return widget.builder(context, controller,
                    CheckWidgetState.paused, request!.progress, null, request);
              case CheckState.cancelled:
                return widget.builder(context, controller,
                    CheckWidgetState.initial, null, null, request);
              case CheckState.finished:
                return widget.builder(context, controller,
                    CheckWidgetState.checked, 1.0, null, request);
            }
          }

          return widget.builder(context, controller, CheckWidgetState.initial,
              null, null, request);
        });
  }

  void _check() => setState(
      () => request = manager.check(widget.m3uEntryList, path: widget.path));
  void _pause() => request?.pause();
  void _resume() => request?.resume();
  void _cancel() => request?.cancel();
  void _reset() {
    _cancel();
    setState(() => request = null);
  }
}
