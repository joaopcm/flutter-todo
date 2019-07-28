import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((String data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();

      newToDo['title'] = _toDoController.text;
      _toDoController.text = "";
      newToDo['ok'] = false;

      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh () async {
    await Future.delayed(Duration(milliseconds: 300));

    setState(() {
      _toDoList.sort((first, second) {
        if (first['ok'] && !second['ok']) return 1;
        else if (!first['ok'] && second['ok']) return -1;
        else return 0;
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Lista de tarefas"),
            backgroundColor: Colors.blueAccent),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                          controller: _toDoController,
                          decoration: InputDecoration(
                              labelText: "Nova tarefa",
                              labelStyle:
                                  TextStyle(color: Colors.blueAccent)))),
                  RaisedButton(
                    color: Colors.blueAccent,
                    child: Text("Adcicionar"),
                    textColor: Colors.white,
                    onPressed: _addToDo,
                  )
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 20),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem,
                    ),
                    onRefresh: _refresh))
          ],
        ));
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
              alignment: Alignment(-0.9, 0),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ))),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(
              _toDoList[index]["ok"] ? Icons.check : Icons.hourglass_empty,
              color: Colors.white),
          backgroundColor:
              _toDoList[index]['ok'] ? Colors.blueAccent : Colors.grey,
        ),
        onChanged: (check) {
          setState(() {
            _toDoList[index]['ok'] = check;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (error) {
      return null;
    }
  }
}
