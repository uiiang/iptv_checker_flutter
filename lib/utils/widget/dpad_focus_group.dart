part of dpad_detector;

class DPadFocusGroup extends StatefulWidget {
  final List<FocusNode> focusNodeList;
  final Widget child;

  const DPadFocusGroup({
    Key? key,
    required this.focusNodeList,
    required this.child,
  }) : super(key: key);

  @override
  _DPadFocusGroupState createState() => _DPadFocusGroupState();
}

class _DPadFocusGroupState extends State<DPadFocusGroup> {
  int i = -1;

  FocusNode get previousFocusNode {
    i--;
    if (i < 0) {
      i = widget.focusNodeList.length - 1;
      return widget.focusNodeList.last;
    }
    return widget.focusNodeList[i];
  }

  FocusNode get nextFocusNode {
    i++;
    if (i >= widget.focusNodeList.length) {
      i = 0;
      return widget.focusNodeList[0];
    }
    return widget.focusNodeList[i];
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) {
        if (event.runtimeType != RawKeyUpEvent) {
          return;
        }
        if (event.data.logicalKey.keyId == LogicalKeyboardKey.arrowLeft.keyId ||
            event.data.logicalKey.keyId == LogicalKeyboardKey.arrowUp.keyId) {
          previousFocusNode.requestFocus();
        }
        if (event.data.logicalKey.keyId ==
            LogicalKeyboardKey.arrowRight.keyId ||
            event.data.logicalKey.keyId == LogicalKeyboardKey.arrowDown.keyId) {
          nextFocusNode.requestFocus();
        }
      },
      child: widget.child,
    );
  }
}
