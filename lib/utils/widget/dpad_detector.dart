library dpad_detector;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_animations/simple_animations.dart';

part 'dpad_focus_group.dart';

class DPadDetector extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final Color focusColor;
  final double focusRadius;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final void Function()? onMenuTap;
  final void Function()? onVolumeUpTap;
  final void Function()? onVolumeDownTap;

  /// Passed along to the [FocusableActionDetector]
  final bool autoFocus;

  /// Passed to [FocusableActionDetector]. Controls whether this widget will accept focus or input of any kind.
  final bool enabled;

  DPadDetector({
    Key? key,
    required this.child,
    this.focusNode,
    this.focusColor = Colors.blue,
    this.focusRadius = 5.0,
    this.onTap,
    this.onLongPress,
    this.onMenuTap,
    this.onVolumeUpTap,
    this.onVolumeDownTap,
    this.enabled = true,
    this.autoFocus = false,
  }) : super(key: key);

  @override
  _DPadDetectorState createState() => _DPadDetectorState();
}

class _DPadDetectorState extends State<DPadDetector> {
  late FocusNode focusNode;
  bool hasFocus = false;

  @override
  void initState() {
    super.initState();
    focusNode = widget.focusNode ?? FocusNode();
    focusNode.addListener(didChangeFocusNode);
  }

  void didChangeFocusNode() {
    if (hasFocus != focusNode.hasFocus) {
      setState(() {
        hasFocus = focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create the core FocusableActionDetector
    // Widget content = FocusableActionDetector(
    //   enabled: widget.enabled,
    //   autofocus: widget.autoFocus,
    //   child: widget.builder(context, this),
    // );
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (event) {
        if (event.runtimeType != RawKeyUpEvent) {
          return;
        }
        if (event.physicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select) {
          widget.onTap?.call();
        }
        if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
            event.logicalKey == LogicalKeyboardKey.space) {
          widget.onMenuTap?.call();
        }
        if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
          widget.onVolumeUpTap?.call();
        }
        if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
          widget.onVolumeDownTap?.call();
        }
      },
      child: GestureDetector(
        onLongPressStart: (_) {
          widget.onLongPress?.call();
        },
        onTapDown: (_) {
          focusNode.requestFocus();
        },
        onTapUp: (_) {
          focusNode.unfocus();
          widget.onTap?.call();
        },
        onTapCancel: () {
          focusNode.unfocus();
        },
        onLongPress: () {
          widget.onMenuTap?.call();
        },
        child: PlayAnimationBuilder<double>(
          tween: Tween(begin: 2.0, end: 1.0),
          duration: const Duration(seconds: 1),
          child: widget.child,
          // builder: (context, value, child) {
          //   return Container(
          //     width: value,
          //     height: value,
          //     color: Colors.green,
          //     child: child, // use child inside the animation
          //   );
          // },
          builder: (context, value, child) {
            return Container(
              margin: EdgeInsets.all(value * 2),
              // color: Colors.transparent,
              decoration: BoxDecoration(
                color: hasFocus
                    ? widget.focusColor.withOpacity(value * 0.4)
                    : Colors.transparent,
                border: Border.all(
                  color: widget.focusColor.withOpacity(value * 0.1),
                  width: hasFocus ? value * 4 : value,
                ),
                borderRadius: BorderRadius.circular(widget.focusRadius),
              ),
              child: widget.child,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(didChangeFocusNode);
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
