import 'dart:convert';

import 'package:flutter/material.dart';
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
  Map json = {};

  @override
  void initState() {
    super.initState();
    initializeTree();
  }

  void initializeTree() {
    List data = jsonDecode(galleryJson);
    Map<String, dynamic> parsedData = Map();
    data.forEach((memoryUsage) {
      String library = memoryUsage['l'];
      String className = memoryUsage['c'];
      String method = memoryUsage['n'];
      int size = memoryUsage['s'];

      if (library != null && library != '') {
        String firstLevel = library.split('/')[0];
        if (parsedData.containsKey(firstLevel)) {
          parsedData[firstLevel]['size'] += size;
        } else {
          parsedData[firstLevel] = Map<String, dynamic>();
          parsedData[firstLevel]['size'] = size;
        }

        if (className != null && className != '') {
          if (parsedData[firstLevel].containsKey(className)) {
            parsedData[firstLevel][className]['size'] += size;
          } else {
            parsedData[firstLevel][className] = Map<String, dynamic>();
            parsedData[firstLevel][className]['size'] = size;
          }

          if (method != null && method != '') {
            if (parsedData[firstLevel][className].containsKey(method)) {
              parsedData[firstLevel][className][method]['size'] += size;
            } else {
              parsedData[firstLevel][className][method] =
                  Map<String, dynamic>();
              parsedData[firstLevel][className][method]['size'] = size;
            }
          }
        }
      }
    });

    // JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    // String prettyprint = encoder.convert(parsedData);
    // print(prettyprint);

    json = parsedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: json.isEmpty
            ? Center(child: CircularProgressIndicator())
            : TreeMap(json: json),
      ),
    );
  }
}
