import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:random_color/random_color.dart';
import 'package:treemap/main.dart';

class TreeMap extends StatefulWidget {
  const TreeMap({this.rootNode});

  final DataPoint rootNode;

  @override
  _TreeMapState createState() => _TreeMapState();
}

enum PivotType { pivotByMiddle, pivotBySize }

class _TreeMapState extends State<TreeMap> {
  bool shouldBeRow = true;
  PivotType pivotType = PivotType.pivotByMiddle;

  @override
  void initState() {
    super.initState();
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
    return row;
  }

  // Computes the total size of given list of data points.
  int computeSize2(List<DataPoint> children, int start, int end) {
    int sum = 0;
    for (int i = start; i <= end; i++) {
      sum += children[i].size;
    }
    return sum;
  }

  int computePivot2(List<DataPoint> children) {
    switch (pivotType) {
      case PivotType.pivotByMiddle:
        {
          return (children.length / 2).floor();
        }
      case PivotType.pivotBySize:
        {
          int pivotIndex = -1;
          double maxSize = double.negativeInfinity;
          for (int i = 0; i < children.length; i++) {
            if (children[i].size > maxSize) {
              maxSize = children[i].size.toDouble();
              pivotIndex = i;
            }
          }
          return pivotIndex;
        }
    }
    return -1;
  }

  // Divided a given list of datapoints into four parts:
  // L1, PD, L2, L3

  // PD (pivot datapoint) is the datapoint chosen to be the pivot based on the pivot type.

  // L1 inclues all datapoints before the pivot datapoint.

  // L2 and L3 combined include all datapoints after the pivot datapoinit.
  // A combination of elements are put into L2 and L3 so that
  // the aspect ratio of PD is as low as it can be.

  // Example layout:
  // ----------------------------
  // |      |  PD  |            |
  // |      |      |            |
  // |  L1  |------|    L3      |
  // |      |  L2  |            |
  // |      |      |            |
  // ----------------------------
  List<Cell> buildTreeMap2(
    List<DataPoint> children,
    double width,
    double height,
    double x,
    double y,
  ) {
    bool isHorizontalRectangle = width > height;

    int totalSize = computeSize2(children, 0, children.length - 1);

    if (children.isEmpty) {
      return [
        Cell(
          x: 0,
          y: 0,
          width: 0,
          height: 0,
        )
      ];
    }
    // Make list of children ascennding in size.
    // children.shuffle();
    children.sort((a,b)=>b.size.compareTo(a.size));
    if (children.length == 1 || children.length == 2) {
      List<Cell> positionedChildren = [];
      double offset = isHorizontalRectangle ? x : y;

      RandomColor random = RandomColor();
      Color color = random.randomMaterialColor();

      children.forEach((child) {
        double ratio = child.size / totalSize;
        positionedChildren.add(
          Cell(
            x: isHorizontalRectangle ? offset : x,
            y: isHorizontalRectangle ? y : offset,
            width: isHorizontalRectangle ? ratio * width : width,
            height: isHorizontalRectangle ? height : ratio * height,
            text: child.name,
            onTap: () {
              print('${child.name} tapped!');
            },
            node: child,
            size: child.size,
            backgroundColor: color,
          ),
        );

        offset += isHorizontalRectangle ? ratio * width : ratio * height;
      });
      return positionedChildren;
    }

    int pivotIndex = computePivot2(children);
    if (pivotIndex == -1) {
      throw ('Error occurred while computing the pivot index.');
    }

    DataPoint pivotDatapoint = children[pivotIndex];
    int pdSize = pivotDatapoint.size;

    List<DataPoint> list1 = children.sublist(0, pivotIndex);
    int list1Size = computeSize2(list1, 0, list1.length - 1);

    List<DataPoint> list2 = [];
    int list2Size = 0;
    List<DataPoint> list3 = [];
    int list3Size = 0;

    // The amount of data we have from pivot + 1 (exclusive)
    // In another words, if we only put one data in l2, how many are left for l3?
    // [L1, pivotIndex, data, |d|] d = 2
    int l3MaxLength = children.length - pivotIndex - 1;
    int bestIndex = 0;
    double pivotBestWidth = 0;
    double pivotBestHeight = 0;

    // We need to be able to put at least 3 elements in l3 for this algorithm.
    if (l3MaxLength >= 3) {
      double pdBestAspectRatio = double.infinity;
      // Iterate through different combinations of list2 and list3 to find
      // the combination where the aspect ratio of pc is the lowest.
      for (int i = pivotIndex + 1; i < children.length; i++) {
        int list2Size = computeSize2(children, pivotIndex + 1, i);
        int list3Size = computeSize2(children, i + 1, children.length - 1);

        // Calculate the aspect ratio for the pivot datapoint.
        double pdAndList2Ratio = (pdSize + list2Size) / totalSize;
        double pdRatio = pdSize / (pdSize + list2Size);

        double pdWidth =
            isHorizontalRectangle ? pdAndList2Ratio * width : pdRatio * width;

        double pdHeight =
            isHorizontalRectangle ? pdRatio * height : pdAndList2Ratio * height;

        double pdAspectRatio = pdWidth / pdHeight;

        // Best aspect ratio that is the closest to 1.
        if ((1 - pdAspectRatio).abs() < (1 - pdBestAspectRatio).abs()) {
          pdBestAspectRatio = pdAspectRatio;
          bestIndex = i;
          // Kept track so it can be used to construct the pivot cell.
          pivotBestWidth = pdWidth;
          pivotBestHeight = pdHeight;
        }
      }

      // Split the rest of the data into list2 and list3
      // [L1, pivotIndex, L2 |bestIndex| L3]
      list2 = children.sublist(pivotIndex + 1, bestIndex + 1);
      list2Size = computeSize2(list2, 0, list2.length - 1);

      list3 = children.sublist(bestIndex + 1);
      list3Size = computeSize2(list3, 0, list3.length - 1);
    } else if (l3MaxLength > 0) {
      // Put all data in l2 and none in l3.
      list2 = children.sublist(pivotIndex + 1);
      list2Size = computeSize2(list2, 0, list2.length - 1);

      double pdAndList2Ratio = (pdSize + list2Size) / totalSize;
      double pdRatio = pdSize / (pdSize + list2Size);
      pivotBestWidth =
          isHorizontalRectangle ? pdAndList2Ratio * width : pdRatio * width;
      pivotBestHeight =
          isHorizontalRectangle ? pdRatio * height : pdAndList2Ratio * height;
    }

    bool stopRecursion = false;

    double list1SizeRatio = list1Size / totalSize;
    double list1Width = isHorizontalRectangle ? width * list1SizeRatio : width;
    double list1Height =
        isHorizontalRectangle ? height : height * list1SizeRatio;
    List<Cell> list1Cells;
    if (!stopRecursion)
      list1Cells = buildTreeMap2(
        list1,
        list1Width,
        list1Height,
        x,
        y,
      );

    // list2 shares the same width as the pivot.
    double list2Width =
        isHorizontalRectangle ? pivotBestWidth : width - pivotBestWidth;
    // list2's height is total height - pivot height.
    double list2Height =
        isHorizontalRectangle ? height - pivotBestHeight : pivotBestHeight;
    double list2XCoord = isHorizontalRectangle ? x + list1Width : x;
    double list2YCoord =
        isHorizontalRectangle ? y + pivotBestHeight : y + list1Height;
    List<Cell> list2Cells;
    if (!stopRecursion)
      list2Cells = buildTreeMap2(
        list2,
        list2Width,
        list2Height,
        list2XCoord,
        list2YCoord,
      );

    RandomColor random = RandomColor();
    Color color = random.randomMaterialColor();

    double pivotXCoord =
        isHorizontalRectangle ? x + list1Width : x + list2Width;
    double pivotYCorrd = isHorizontalRectangle ? y : y + list1Height;
    Cell pivotCell = Cell(
      width: pivotBestWidth,
      height: pivotBestHeight,
      x: pivotXCoord,
      y: pivotYCorrd,
      node: pivotDatapoint,
      text: pivotDatapoint.name,
      onTap: () {
        print('${pivotDatapoint.name} tapped!');
      },
      backgroundColor: color,
    );

    double list3Ratio = list3Size / totalSize;
    double list3Width = isHorizontalRectangle ? list3Ratio * width : width;
    double list3Height = isHorizontalRectangle ? height : list3Ratio * height;
    double list3XCoord =
        isHorizontalRectangle ? x + list1Width + pivotBestWidth : x;
    double list3YCoord =
        isHorizontalRectangle ? y : y + list1Height + pivotBestHeight;
    List<Cell> list3Cells;
    if (!stopRecursion)
      list3Cells = buildTreeMap2(
        list3,
        list3Width,
        list3Height,
        list3XCoord,
        list3YCoord,
      );
    // print('--------- Pivot ----------');
    // print(pivotCell);
    // print('--------- List 1 ----------');
    // print(list1);
    // print('--------- List 2 ----------');
    // print(list2);
    // print('--------- List 3 ----------');
    // print(list3);

    // Hardcoded data for debug purposes
    if (stopRecursion) {
      list1Cells = [
        Cell(
          width: list1Width,
          height: list1Height,
          x: x,
          y: y,
          text: 'List 1',
        )
      ];
      list2Cells = [
        Cell(
          width: list2Width,
          height: list2Height,
          x: list2XCoord,
          y: list2YCoord,
          text: 'List 2',
        )
      ];
      list3Cells = [
        Cell(
          width: list3Width,
          height: list3Height,
          x: list3XCoord,
          y: list3YCoord,
          text: 'List 3',
        )
      ];
    }

    return list1Cells + [pivotCell] + list2Cells + list3Cells;
  }

  List<Widget> buildTestTreeMapFromNode(
      DataPoint root, double width, double height) {
    List<DataPoint> children = root.children;
    List<Cell> positionedChildren = [];
    int totalSize = root.size;
    double xOffset = 0;
    children.forEach((child) {
      double ratio = child.size / totalSize;

      positionedChildren.add(
        Cell(
          x: xOffset,
          y: 0.0,
          width: ratio * width,
          height: height,
          text: child.name,
          onTap: () {
            print('${child.name} tapped!');
          },
          node: child,
          size: child.size,
        ),
      );

      xOffset += ratio * width;
    });
    return positionedChildren;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Stack(
            children: buildTreeMap2(
              widget.rootNode.children,
              constraints.maxWidth,
              constraints.maxHeight,
              0.0,
              0.0,
            ),
          ),
        );
      },
    );
  }
}

class Cell extends StatelessWidget {
  const Cell({
    Key key,
    @required this.width,
    @required this.height,
    @required this.x,
    @required this.y,
    this.text = '',
    this.node,
    this.onTap,
    this.size,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  // Width and height of the box
  final double width;
  final double height;

  // Origin is defined by the left top corner.
  // x is the horizontal distance from the origin.
  // y is the vertical distance from the origin.
  final double x;
  final double y;

  final String text;
  final VoidCallback onTap;
  final DataPoint node;
  // Should be deleted since size is in node already.
  final int size;

  // Color to paint the cell.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: Tooltip(
        message: text,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(width: 0.5),
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (node == null) return 'null';
    return {
      'name': text,
      'node': node,
      'width': width,
      'height': height,
      'x': x,
      'y': y,
    }.toString();
  }
}
