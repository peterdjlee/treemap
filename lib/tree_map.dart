import 'dart:collection';

import 'package:flutter/material.dart';

class TreeMap extends StatefulWidget {
  const TreeMap({this.json});

  final Map json;

  @override
  _TreeMapState createState() => _TreeMapState();
}

enum PivotType { pivotByMiddle, pivotBySize }

class _TreeMapState extends State<TreeMap> {
  bool shouldBeRow = true;
  Queue stack = Queue();
  List<Cell> cells = List();
  PivotType pivotType = PivotType.pivotBySize;

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
        cells.shuffle();
        // cells.sort((a, b) => b.size.compareTo(a.size));
      } else {
        print('Total size: ' + value.toString());
      }
    });
  }

  // Computes the total size of given list of data points.
  int computeSize(List<Cell> cells, int start, int end) {
    int sum = 0;
    for (int i = start; i <= end; i++) {
      sum += cells[i].size;
    }
    return sum;
  }

  int computePivot(List<Cell> cells) {
    if (cells.isEmpty) return -1;
    switch (pivotType) {
      case PivotType.pivotByMiddle:
        {
          return (cells.length / 2).floor();
        }
      case PivotType.pivotBySize:
        {
          int pivotIndex = -1;
          double maxSize = double.negativeInfinity;
          for (int i = 0; i < cells.length; i++) {
            if (cells[i].size > maxSize) {
              maxSize = cells[i].size.toDouble();
              pivotIndex = i;
            }
          }
          return pivotIndex;
        }
    }
    return -1;
  }

  // Divided a given list of cells into four parts:
  // L1, pc, L2, L3

  // PC (pivot cell) is the cell chosen to be the pivot based on the pivot type.

  // L1 inclues all cells before the pivot cell.

  // L2 and L3 combined include all cells after the pivot cell.
  // A combination of elements are put into L2 and L3 so that
  // the aspect ratio of PC is as low as it can be.

  // Example layout:
  // ----------------------------
  // |      |  PC  |            |
  // |      |      |            |
  // |  L1  |------|    L3      |
  // |      |  L2  |            |
  // |      |      |            |
  // ----------------------------

  Widget buildTreeMap(List<Cell> data) {
    if (data == null || data.length == 0) {
      return Container();
    }
    if (data.length == 1 || data.length == 2) {
      return Flexible(child: Row(children: data));
    }

    int pivotIndex = computePivot(data);
    // if (pivotIndex == -1) {
    //   throw ('Error occurred while computing the pivot index.');
    // }

    Cell pivotCell = data[pivotIndex];
    int pcSize = pivotCell.size;

    // Contains all data points before the pivotIndex.
    List<Cell> list1 = data.sublist(0, pivotIndex);
    int list1Size = computeSize(list1, 0, list1.length - 1);

    List<Cell> list2 = [];
    int list2Size = 0;
    List<Cell> list3 = [];
    int list3Size = 0;

    // The amount of data we have from pivot + 1 (exclusive)
    // In another words, if we only put one data in l2, how many are left for l3?
    // [L1, pivotIndex, data, |d|] d = 2
    int l3MaxLength = data.length - pivotIndex - 1;
    int bestIndex = 0;
    // We need to be able to put at least 3 elements in l3 for this algorithm.
    if (l3MaxLength >= 3) {
      double bestAspectRatio = double.infinity;
      // Iterate through different combinations of list2 and list3 to find
      // the combination where the aspect ratio of pc is the lowest.
      for (int i = pivotIndex + 1; i < data.length; i++) {
        int list2Size = computeSize(data, pivotIndex + 1, i);
        int list3Size = computeSize(data, i + 1, data.length - 1);

        // Calculate the aspect ratio for the pivot cell.
        double pcWidth =
            (pcSize + list2Size) / (list1Size + pcSize + list2Size + list3Size);
        double pcHeight = pcSize / (pcSize + list2Size);
        double pcAspectRatio = pcWidth / pcHeight;

        // Best aspect ratio that is the closest to 1.
        if ((1 - pcAspectRatio).abs() < (1 - bestAspectRatio).abs()) {
          bestAspectRatio = pcAspectRatio;
          bestIndex = i;
        }
      }

      // Split the rest of the data into list2 and list3
      // [L1, pivotIndex, L2 |bestIndex| L3]
      list2 = data.sublist(pivotIndex + 1, bestIndex + 1);
      list2Size = computeSize(list2, 0, list2.length - 1);

      list3 = data.sublist(bestIndex + 1);
      list3Size = computeSize(list3, 0, list3.length - 1);
    } else if (l3MaxLength > 0) {
      // Put all data in l2 and none in l3.
      list2 = data.sublist(pivotIndex + 1);
      list2Size = computeSize(list2, 0, list2.length - 1);
    }

    // Need to check if horizontal/vertical rectangle and
    // switch to Row/Column accordingly.
    Widget row = Row(
      children: [
        Flexible(
          flex: list1Size,
          child: Column(
            children: [
              buildTreeMap(list1),
            ],
          ),
        ),
        Flexible(
          flex: pcSize + list2Size,
          child: Column(
            children: [pivotCell, buildTreeMap(list2)],
          ),
        ),
        Flexible(
          flex: list3Size,
          child: Column(
            children: [
              buildTreeMap(list3),
            ],
          ),
        ),
      ],
    );
    if (data.length == cells.length) print('Finished first call');
    return row;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: buildTreeMap(cells)
        // children: cells.isEmpty
        //     ? [
        //         Cell(
        //           text: stack.last,
        //           lastCell: true,
        //         )
        //       ]
        //     : cells,
        );
  }
}

class DataUsage {
  const DataUsage({this.library, this.className, this.method, this.size});

  final String library;
  final String className;
  final String method;
  final int size;
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
