/*
Copyright 2019 The dahliaOS Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utopia_wm/wm.dart';

class TaskbarItem extends StatefulWidget {
  final WindowEntry entry;
  final Color color;

  TaskbarItem({
    @required this.entry,
    this.color,
  });

  @override
  _TaskbarItemState createState() => _TaskbarItemState();
}

class _TaskbarItemState extends State<TaskbarItem>
    with SingleTickerProviderStateMixin {
  AnimationController _ac;
  Animation<double> _anim;
  bool _hovering = false;
  Timer _overlayTimer;

  GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _anim = CurvedAnimation(
      parent: _ac,
      curve: Curves.ease,
      reverseCurve: Curves.ease,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _ac.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.entry,
      builder: (context, _) {
        final entry = context.watch<WindowEntry>();
        final hierarchy = context.watch<WindowHierarchyState>();
        final windows = hierarchy.entriesByFocus;

        bool focused = windows.length > 1 ? windows.last.id == entry.id : true;
        bool showSelected = focused && !entry.minimized;

        if (showSelected) {
          _ac.animateTo(1);
        } else {
          _ac.animateBack(0);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox.fromSize(
              size: Size.square(constraints.maxHeight),
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  key: _globalKey,
                  onSecondaryTap: () => openDockMenu(context),
                  child: InkWell(
                    onTap: () => _onTap(context),
                    hoverColor: widget.color.withOpacity(0.1),
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (context, _) {
                        return Stack(
                          children: [
                            FadeTransition(
                              opacity: _anim,
                              child: SizeTransition(
                                sizeFactor: _anim,
                                axis: Axis.vertical,
                                axisAlignment: 1,
                                child: Container(
                                  color: widget.color.withOpacity(0.3),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Image(
                                image: entry.icon,
                              ),
                            ),
                            AnimatedPositioned(
                              duration: Duration(milliseconds: 150),
                              curve: Curves.ease,
                              bottom: 0,
                              left: showSelected || _hovering
                                  ? 0
                                  : constraints.maxHeight / 2 - 8,
                              right: showSelected || _hovering
                                  ? 0
                                  : constraints.maxHeight / 2 - 8,
                              height: 2,
                              child: Material(
                                color: widget.color,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onTap(BuildContext context) {
    final entry = context.read<WindowEntry>();
    final hierarchy = context.read<WindowHierarchyState>();
    final windows = hierarchy.entriesByFocus;

    bool focused = windows.last.id == entry.id;

    _overlayTimer?.cancel();
    _overlayTimer = null;
    setState(() {});
    if (focused && !entry.minimized) {
      entry.minimized = true;
      if (windows.length > 1) {
        hierarchy.requestWindowFocus(
          windows[windows.length - 2],
        );
      }
    } else {
      entry.minimized = false;
      hierarchy.requestWindowFocus(entry);
    }
  }

  void openDockMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.topLeft(Offset.zero),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    var result = await showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          child: Text("Normal"),
          value: WindowDock.NORMAL,
        ),
        PopupMenuItem(
          child: Text("Top left"),
          value: WindowDock.TOP_LEFT,
        ),
        PopupMenuItem(
          child: Text("Top"),
          value: WindowDock.TOP,
        ),
        PopupMenuItem(
          child: Text("Top right"),
          value: WindowDock.TOP_RIGHT,
        ),
        PopupMenuItem(
          child: Text("Left"),
          value: WindowDock.LEFT,
        ),
        PopupMenuItem(
          child: Text("Right"),
          value: WindowDock.RIGHT,
        ),
        PopupMenuItem(
          child: Text("Bottom left"),
          value: WindowDock.BOTTOM_LEFT,
        ),
        PopupMenuItem(
          child: Text("Bottom"),
          value: WindowDock.BOTTOM,
        ),
        PopupMenuItem(
          child: Text("Bottom right"),
          value: WindowDock.BOTTOM_RIGHT,
        ),
      ],
    );

    if (result != null) {
      widget.entry.windowDock = result;
    }
  }
}