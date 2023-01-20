import 'package:flutter/material.dart';
import 'package:iptv_check_manager/iptv_check_manager.dart';
import 'package:iptv_checker_flutter/types/check_state.dart';

/// Builder function for each state of file checking
/// You take control of [CheckRequest] storing and controlling the check process
/// Warning: Request's event stream shouldn't be in use
class CheckWidget extends StatelessWidget {
  const CheckWidget({super.key, required this.builder, this.request}) : super();

  /// Builder is required to build the UI based on current check state
  final Widget Function(BuildContext context, CheckWidgetState state,
      double? progress, Object? error) builder;

  /// The check request
  final CheckRequest? request;

  @override
  Widget build(BuildContext context) {
    if (request == null) {
      return builder(context, CheckWidgetState.initial, null, null);
    }

    return StreamBuilder(
        stream: request!.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return builder(
                context, CheckWidgetState.failed, null, snapshot.error);
          }

          if (snapshot.hasData) {
            final data = snapshot.data!;
            if (data is double) {
              return builder(context, CheckWidgetState.checking, data, null);
            }

            switch (data as CheckState) {
              case CheckState.queued:
                return builder(context, CheckWidgetState.queued, null, null);
              case CheckState.started:
              case CheckState.resumed:
                return builder(context, CheckWidgetState.checking, null, null);
              case CheckState.paused:
                return builder(
                    context, CheckWidgetState.paused, request!.progress, null);
              case CheckState.cancelled:
                return builder(context, CheckWidgetState.initial, null, null);
              case CheckState.finished:
                return builder(context, CheckWidgetState.checked, 1.0, null);
            }
          }

          return builder(context, CheckWidgetState.initial, null, null);
        });
  }
}
