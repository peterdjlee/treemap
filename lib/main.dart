import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:treemap/data_reference.dart';
import 'package:treemap/tree_map.dart';

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
  DataReference rootNode;

  @override
  void initState() {
    super.initState();
    initializeTree();
  }

  void initializeTree() {
    List data = jsonDecode(galleryJson);

    // Number of boxes at the library level we can see.
    int debugChildrenNumberLimit = 100;
    int debugChildrenNumberCount = 0;

    DataReference root = DataReference(
      name: 'Root',
      size: 0,
      dataType: DataType.Root,
    );

    // Can optimize look up / retrieve time with a hashmap

    for (dynamic memoryUsage in data) {
      if (debugChildrenNumberCount >= debugChildrenNumberLimit) break;

      String libraryName = memoryUsage['l'];
      if (libraryName == null || libraryName == '') {
        libraryName = 'Unnamed Library';
      }
      String className = memoryUsage['c'];
      if (className == null || className == '') {
        className = 'Unnamed Class';
      }
      String methodName = memoryUsage['n'];
      if (methodName == null || methodName == '') {
        methodName = 'Unnamed Method';
      }
      int size = memoryUsage['s'];
      if (size == null) {
        throw ("Size was null for $memoryUsage");
      }
      root.addSize(size);

      if (libraryName.startsWith('package:flutter/src/')) {
        libraryName = 'flutter:' + libraryName.split('/').last.replaceAll('.dart', '');
      }
      // String firstLevel = libraryName.split('/')[0];
      DataReference libraryLevelChild = root.getChildWithName(libraryName);
      if (libraryLevelChild == null) {
        root.addChild(
          DataReference(
            name: libraryName,
            size: size,
            dataType: DataType.Library,
          ),
        );

        debugChildrenNumberCount += 1;
        libraryLevelChild = root.getChildWithName(libraryName);
      } else {
        libraryLevelChild.addSize(size);
      }

      DataReference classLevelChild = libraryLevelChild.getChildWithName(className);

      if (classLevelChild == null) {
        libraryLevelChild.addChild(
          DataReference(
            name: className,
            size: size,
            dataType: DataType.Class,
          ),
        );
        classLevelChild = libraryLevelChild.getChildWithName(className);
      } else {
        classLevelChild.addSize(size);
      }

      DataReference methodLevelChild = classLevelChild.getChildWithName(methodName);

      if (methodLevelChild == null) {
        classLevelChild.addChild(
          DataReference(
            name: methodName,
            size: size,
            dataType: DataType.Method,
          ),
        );
        methodLevelChild = classLevelChild.getChildWithName(methodName);
      } else {
        methodLevelChild.addSize(size);
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
          padding: const EdgeInsets.all(16.0),
          child: rootNode == null
              ? Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return TreeMap(
                      rootNode: rootNode,
                      levelsVisible: 2,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
