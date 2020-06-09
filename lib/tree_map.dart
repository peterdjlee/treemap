import 'dart:collection';

import 'package:flutter/material.dart';

class TreeMap extends StatefulWidget {
  const TreeMap({this.json});

  final Map json;

  @override
  _TreeMapState createState() => _TreeMapState();
}

class _TreeMapState extends State<TreeMap> {
  bool shouldBeRow = true;
  Queue stack = Queue();
  List<Cell> cells = List();

  @override
  void initState() {
    super.initState();
    getChildren();
  }

  void onTap(String name) {
    setState(() {
      stack.addLast(name);
    });
    getChildren();
  }

  void getChildren() {
    Map json = widget.json;
    if (stack.isNotEmpty) {
      stack.forEach((element) {
        json = json[element];
      });
    }

    cells.clear();

    json.forEach((key, value) {
      if (key != 'size') {
        int size = json[key]['size'];
        cells.add(Cell(
          text: key,
          size: size,
          onTap: () {
            onTap(key);
          },
        ));
      } else {
        print('Total size: ' + value.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: Row(
        children: cells.isEmpty
            ? [
                Cell(
                  text: stack.last,
                  lastCell: true,
                )
              ]
            : cells,
      ),
    );
  }
}

class Cell extends StatelessWidget {
  const Cell({
    Key key,
    this.size = 1,
    this.text,
    this.onTap,
    this.lastCell = false,
  }) : super(key: key);

  final int size;
  final String text;
  final VoidCallback onTap;
  final bool lastCell;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: text,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(),
            ),
            child: lastCell ? Center(child: Text(text)) : Container(),
          ),
        ),
      ),
      flex: size,
    );
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return {'name': text, 'size': size}.toString();
  }
}
