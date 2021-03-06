import 'package:flutter/material.dart';

import 'data_reference.dart';

class TreeMap extends StatefulWidget {
  const TreeMap({
    this.rootNode,
    this.levelsVisible,
    this.width,
    this.height,
    this.onTap,
  });

  final DataReference rootNode;

  // The depth of children visible from this treemap widget.
  // For example, levelsVisible = 2
  // ---------------
  // |    l = 1    |
  // |  ---------  |
  // |  | l = 2 |  |
  // |  |       |  |
  // |  |       |  |
  // |  ---------  |
  // ---------------
  final int levelsVisible;

  final double width;
  final double height;

  final VoidCallback onTap;

  @override
  _TreeMapState createState() => _TreeMapState();
}

enum PivotType { pivotByMiddle, pivotBySize }

class _TreeMapState extends State<TreeMap> {
  PivotType pivotType = PivotType.pivotBySize;
  static const double minWidthToDisplayText = 110.0;

  DataReference rootNode;

  @override
  void initState() {
    super.initState();
    rootNode = widget.rootNode;
  }

  void cellOnTap(String name) {
    DataReference child = rootNode.getChildWithName(name);
    if (child != null) {
      print('changing $rootNode to child node named $name');
      setState(() {
        rootNode = rootNode.getChildWithName(name);
      });
    }
  }

  // Computes the total size of a given list of data references.
  int computeSize(List<DataReference> children, int start, int end) {
    int sum = 0;
    for (int i = start; i <= end; i++) {
      sum += children[i].size;
    }
    return sum;
  }

  int computePivot2(List<DataReference> children) {
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

  // Divided a given list of data references into four parts:
  // L1, P, L2, L3

  // P (pivot) is the data references chosen to be the pivot based on the pivot type.

  // L1 inclues all data references before the pivot data reference.

  // L2 and L3 combined include all data references after the pivot data references.
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
  List<Cell> buildTreeMap(
    List<DataReference> children,
    double width,
    double height,
    double x,
    double y,
  ) {
    final bool isHorizontalRectangle = width > height;

    final int totalSize = computeSize(children, 0, children.length - 1);

    if (children.isEmpty) {
      return [];
    }
    // Make list of children descending in size.
    // children.shuffle();
    children.sort((a, b) => b.size.compareTo(a.size));
    if (children.length == 1 || children.length == 2) {
      List<Cell> positionedChildren = [];
      double offset = isHorizontalRectangle ? x : y;

      children.forEach((child) {
        double ratio = child.size / totalSize;
        positionedChildren.add(
          Cell(
            key: UniqueKey(),
            x: isHorizontalRectangle ? offset : x,
            y: isHorizontalRectangle ? y : offset,
            width: isHorizontalRectangle ? ratio * width : width,
            height: isHorizontalRectangle ? height : ratio * height,
            onTap: () => cellOnTap(child.name),
            node: child,
            levelsVisible: widget.levelsVisible - 1,
          ),
        );

        offset += isHorizontalRectangle ? ratio * width : ratio * height;
      });
      return positionedChildren;
    }

    final int pivotIndex = computePivot2(children);
    if (pivotIndex == -1) {
      throw 'Error occurred while computing the pivot index.';
    }

    final DataReference pivotDataReference = children[pivotIndex];
    final int pSize = pivotDataReference.size;

    final List<DataReference> list1 = children.sublist(0, pivotIndex);
    final int list1Size = computeSize(list1, 0, list1.length - 1);

    List<DataReference> list2 = [];
    int list2Size = 0;
    List<DataReference> list3 = [];
    int list3Size = 0;

    // The amount of data we have from pivot + 1 (exclusive)
    // In another words, if we only put one data in l2, how many are left for l3?
    // [L1, pivotIndex, data, |d|] d = 2
    final int l3MaxLength = children.length - pivotIndex - 1;
    int bestIndex = 0;
    double pivotBestWidth = 0;
    double pivotBestHeight = 0;

    // We need to be able to put at least 3 elements in l3 for this algorithm.
    if (l3MaxLength >= 3) {
      double pBestAspectRatio = double.infinity;
      // Iterate through different combinations of list2 and list3 to find
      // the combination where the aspect ratio of pivot is the lowest.
      for (int i = pivotIndex + 1; i < children.length; i++) {
        final int list2Size = computeSize(children, pivotIndex + 1, i);
        final int list3Size = computeSize(children, i + 1, children.length - 1);

        // Calculate the aspect ratio for the pivot data references.
        final double pAndList2Ratio = (pSize + list2Size) / totalSize;
        final double pRatio = pSize / (pSize + list2Size);

        final double pWidth =
            isHorizontalRectangle ? pAndList2Ratio * width : pRatio * width;

        final double pHeight =
            isHorizontalRectangle ? pRatio * height : pAndList2Ratio * height;

        final double pAspectRatio = pWidth / pHeight;

        // Best aspect ratio that is the closest to 1.
        if ((1 - pAspectRatio).abs() < (1 - pBestAspectRatio).abs()) {
          pBestAspectRatio = pAspectRatio;
          bestIndex = i;
          // Kept track of width and height to construct the pivot cell.
          pivotBestWidth = pWidth;
          pivotBestHeight = pHeight;
        }
      }
      // Split the rest of the data into list2 and list3
      // [L1, pivotIndex, [L2 bestIndex] L3]
      list2 = children.sublist(pivotIndex + 1, bestIndex + 1);
      list2Size = computeSize(list2, 0, list2.length - 1);

      list3 = children.sublist(bestIndex + 1);
      list3Size = computeSize(list3, 0, list3.length - 1);
    } else {
      // Put all data in l2 and none in l3.
      list2 = children.sublist(pivotIndex + 1);
      list2Size = computeSize(list2, 0, list2.length - 1);

      final double pdAndList2Ratio = (pSize + list2Size) / totalSize;
      final double pdRatio = pSize / (pSize + list2Size);
      pivotBestWidth =
          isHorizontalRectangle ? pdAndList2Ratio * width : pdRatio * width;
      pivotBestHeight =
          isHorizontalRectangle ? pdRatio * height : pdAndList2Ratio * height;
    }

    // If true, the treemap will only show the divison between L1, L2, P, and L3.
    final bool stopRecursion = false;

    final double list1SizeRatio = list1Size / totalSize;
    final double list1Width =
        isHorizontalRectangle ? width * list1SizeRatio : width;
    final double list1Height =
        isHorizontalRectangle ? height : height * list1SizeRatio;
    List<Cell> list1Cells;
    if (!stopRecursion)
      list1Cells = buildTreeMap(
        list1,
        list1Width,
        list1Height,
        x,
        y,
      );

    final double list2Width =
        isHorizontalRectangle ? pivotBestWidth : width - pivotBestWidth;
    final double list2Height =
        isHorizontalRectangle ? height - pivotBestHeight : pivotBestHeight;
    final double list2XCoord = isHorizontalRectangle ? x + list1Width : x;
    final double list2YCoord =
        isHorizontalRectangle ? y + pivotBestHeight : y + list1Height;
    List<Cell> list2Cells;
    if (!stopRecursion)
      list2Cells = buildTreeMap(
        list2,
        list2Width,
        list2Height,
        list2XCoord,
        list2YCoord,
      );

    final double pivotXCoord =
        isHorizontalRectangle ? x + list1Width : x + list2Width;
    final double pivotYCorrd = isHorizontalRectangle ? y : y + list1Height;
    final Cell pivotCell = Cell(
      key: UniqueKey(),
      width: pivotBestWidth,
      height: pivotBestHeight,
      x: pivotXCoord,
      y: pivotYCorrd,
      node: pivotDataReference,
      onTap: () => cellOnTap(pivotDataReference.name),
      levelsVisible: widget.levelsVisible - 1,
    );

    final double list3Ratio = list3Size / totalSize;
    final double list3Width =
        isHorizontalRectangle ? list3Ratio * width : width;
    final double list3Height =
        isHorizontalRectangle ? height : list3Ratio * height;
    final double list3XCoord =
        isHorizontalRectangle ? x + list1Width + pivotBestWidth : x;
    final double list3YCoord =
        isHorizontalRectangle ? y : y + list1Height + pivotBestHeight;
    List<Cell> list3Cells;
    if (!stopRecursion)
      list3Cells = buildTreeMap(
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
          node: DataReference(name: 'List 1', size: null, dataType: null),
          levelsVisible: 0,
        )
      ];
      list2Cells = [
        Cell(
          width: list2Width,
          height: list2Height,
          x: list2XCoord,
          y: list2YCoord,
          node: DataReference(name: 'List 2', size: null, dataType: null),
          levelsVisible: 0,
        )
      ];
      list3Cells = [
        Cell(
          width: list3Width,
          height: list3Height,
          x: list3XCoord,
          y: list3YCoord,
          node: DataReference(name: 'List 3', size: null, dataType: null),
          levelsVisible: 0,
        )
      ];
    }

    return list1Cells + [pivotCell] + list2Cells + list3Cells;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.levelsVisible > 0 ? 1.0 : 0.0),
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 0.5)),
        child: Column(
          children: [
            if (widget.width > minWidthToDisplayText &&
                widget.levelsVisible > 0)
              Center(
                child: Text(
                  rootNode.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.0),
                ),
              ),
            Expanded(
              child: widget.levelsVisible == 0
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                      ),
                    )
                  : widget.levelsVisible != 1
                      ? buildNestedTreeMap()
                      : GestureDetector(
                          onTap: widget.onTap,
                        child: Tooltip(
                            message: rootNode.name,
                            child: buildNestedTreeMap(),
                          ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  LayoutBuilder buildNestedTreeMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Stack(
            children: buildTreeMap(
              rootNode.children,
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
    @required this.levelsVisible,
    this.node,
    this.onTap,
  }) : super(key: key);

  // Width and height of the box
  final double width;
  final double height;

  // Origin is defined by the left top corner.
  // x is the horizontal distance from the origin.
  // y is the vertical distance from the origin.
  final double x;
  final double y;

  final VoidCallback onTap;
  final DataReference node;

  final int levelsVisible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: TreeMap(
        rootNode: node,
        levelsVisible: levelsVisible,
        width: width,
        height: height,
        onTap: onTap,
      ),
    );
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (node == null) return 'null';
    return {
      'width': width,
      'height': height,
      'x': x,
      'y': y,
      'node': node,
    }.toString();
  }
}
