import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:treemap/tree_map.dart';
import 'package:treemap/trees.dart';

import 'const.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Treemap',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Treemap'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Cell> children = List();
  DataPoint rootNode;

  @override
  void initState() {
    super.initState();
    initializeTree();
  }

  void initializeTree() {
    List data = jsonDecode(galleryJson);

    int debugChildrenNumberLimit = 10000000;
    int debugChildrenNumberCount = 0;

    DataPoint root = DataPoint(
      name: 'Root',
      size: 0,
      dataType: DataType.Root,
    );

    // Doesn't work but generates mock data anyway.

    for (dynamic memoryUsage in data) {
      if (debugChildrenNumberCount >= debugChildrenNumberLimit) break;

      String library = memoryUsage['l'];
      String className = memoryUsage['c'];
      String method = memoryUsage['n'];
      int size = memoryUsage['s'];
      root.addSize(size);
      
      if (library != null && library != '') {
        String firstLevel = library.split('/')[0];
        DataPoint libraryLevelChild = root.getChildWithName(firstLevel);
        if (libraryLevelChild != null) {
          libraryLevelChild.addSize(size);

          // if (className != null && className != '') {
          //   DataPoint classLevelChild =
          //       libraryLevelChild.getChildWithName(className);

          //   if (classLevelChild != null) {
          //     classLevelChild.addSize(size);

          //     if (method != null && method != '') {
          //       classLevelChild.addChild(
          //         DataPoint(
          //           name: method,
          //           size: size,
          //           dataType: DataType.Method,
          //         ),
          //       );
          //     }
          //   } else {
          //     libraryLevelChild.addChild(
          //       DataPoint(
          //         name: className,
          //         size: size,
          //         dataType: DataType.Class,
          //       ),
          //     );
          //   }
          // }
        } else {
          root.addChild(
            DataPoint(
              name: firstLevel,
              size: size,
              dataType: DataType.Library,
            ),
          );

          debugChildrenNumberCount += 1;
        }
      } else {
        if (method.startsWith('[Stub]')) {
          DataPoint libraryLevelChild = root.getChildWithName('Stub');
          if (libraryLevelChild != null) {
            libraryLevelChild.addSize(size);
          } else {
            root.addChild(
              DataPoint(
                name: 'Stub',
                size: size,
                dataType: DataType.Library,
              ),
            );

            debugChildrenNumberCount += 1;
          }
        } else if (method.startsWith('[unknown stub]')) {
          DataPoint libraryLevelChild = root.getChildWithName('UnknownStub');
          if (libraryLevelChild != null) {
            libraryLevelChild.addSize(size);
          } else {
            root.addChild(
              DataPoint(
                name: 'UnknownStub',
                size: size,
                dataType: DataType.Library,
              ),
            );

            debugChildrenNumberCount += 1;
          }
        }
      }
    }
    // root.printTree();
    rootNode = root;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: rootNode == null
              ? Center(child: CircularProgressIndicator())
              : TreeMap(rootNode: rootNode),
        ),
      ),
    );
  }
}

enum DataType { Root, Library, Class, Method }

class DataPoint extends TreeNode<DataPoint> {
  DataPoint({
    @required this.name,
    @required this.size,
    @required this.dataType,
  });

  final String name;
  final DataType dataType;
  int size;

  void addSize(int size) {
    this.size += size;
  }

  DataPoint getChildWithName(String name) {
    return this.children.singleWhere(
      (element) => element.name == name,
      orElse: () {
        return null;
      },
    );
  }

  void printTree() {
    printTreeHelper(this, '');
  }

  void printTreeHelper(DataPoint root, String tabs) {
    print(tabs + '$root');
    root.children.forEach((child) {
      printTreeHelper(child, tabs + '\t');
    });
  }

  @override
  String toString() {
    return '{name: $name, size: $size, dataType: $dataType}\n';
  }
}
