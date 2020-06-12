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

  int debugChildrenNumberCount = 0;

  DataReference addChild(
    DataReference parent,
    String name,
    int size,
    DataType dataType,
  ) {
    DataReference child = parent.getChildWithName(name);
    if (child == null) {
      parent.addChild(
        DataReference(
          name: name,
          size: size,
          dataType: dataType,
        ),
      );

      if (dataType == DataType.Library) debugChildrenNumberCount += 1;
      child = parent.getChildWithName(name);
    } else {
      child.addSize(size);
    }
    return child;
  }

  void initializeTree() {
    final List data = jsonDecode(galleryJson);

    // Number of boxes at the library level we can see.
    const int debugChildrenNumberLimit = 100;

    final DataReference root = DataReference(
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
      final int size = memoryUsage['s'];
      if (size == null) {
        throw 'Size was null for $memoryUsage';
      }
      root.addSize(size);

      DataReference libraryLevelChild;
      if (libraryName.startsWith('package:flutter/src/')) {
        final String package =
            libraryName.replaceAll('package:flutter/src/', '');
        final List<String> packageSplit = package.split('/');
        libraryLevelChild =
            addChild(root, 'package:flutter', size, DataType.Library);
        for (String level in packageSplit) {
          libraryLevelChild =
              addChild(libraryLevelChild, level, size, DataType.Library);
        }
      } else {
        libraryName = libraryName.split('/')[0];
        libraryLevelChild = addChild(root, libraryName, size, DataType.Library);
      }
      final DataReference classLevelChild =
          addChild(libraryLevelChild, className, size, DataType.Class);
      final DataReference methodLevelChild =
          addChild(classLevelChild, methodName, size, DataType.Method);
    }
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
