import 'package:flutter/material.dart';
import './dropbox.dart';
import 'dart:async';
import './properties.dart';
import './cloudapi.dart';
import 'package:flutter/foundation.dart';

const String SUCCESS_TEXT = "Success!";
const String FAILURE_TEXT = "Failure";
const String INPUT_PLACEHOLDER = 'Enter Todo';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isBusy = false;
  bool _todoTextActive = false;
  Property dropboxOrgFilePath = new Property('dropboxOrgFilePath');
  Future<List<Todo>> todos;

  final TextEditingController _txtControl = new TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    this._txtControl.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _txtControl.addListener(setTodoTextActive);
    todos = fetchTodos();
  }

  void setTodoTextActive() {
    if (_todoTextActive && _txtControl.text.length == 0) {
      setState(() {
        _todoTextActive = false;
      });
    } else if (!_todoTextActive && _txtControl.text.length > 0) {
      setState(() {
        _todoTextActive = true;
      });
    }
  }

  void submitTodoState() async {
    var todoText = _txtControl.text;
    if (todoText.length > 0) {
      setState(() {
        _isBusy = true;
        todos = null;
      });
      try {
        await Dropbox().addTodo(todoText);
        todos = fetchTodos();
      } catch (e) {
        debugPrint(e.toString());
      }
      setState(() {
        _isBusy = false;
      });

      // reset the input box
      _txtControl.clear();
    }
  }

  void markTodoDone(String todoText) async {
    if (todoText.length > 0) {
      setState(() {
        _isBusy = true;
        todos = null;
      });
      try {
        await Dropbox().markTodoAsDone(todoText);
        todos = fetchTodos();
      } catch (e) {
        debugPrint(e.toString());
      }
      setState(() {
        _isBusy = false;
      });

      // reset the input box
      _txtControl.clear();
    }
  }

  Future<void> refreshTodos() async {
    setState(() {
      _isBusy = true;
      todos = null;
    });
    setState(() {
      todos = fetchTodos();
      _isBusy = false;
    });
  }

  Widget todoItemWidget(Todo todo) {
    return ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        leading: Container(
          padding: EdgeInsets.only(right: 10.0),
          decoration: new BoxDecoration(
              border: new Border(
                  right: new BorderSide(width: 1.0, color: Colors.white24))),
          child: IconButton(
            icon: Icon(Icons.check, color: Colors.grey),
            onPressed: () => markTodoDone(todo.text),
          ),
        ),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            todo.text,
            overflow: TextOverflow.clip,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ));
  }

  Widget todoListWidget() {
    return FutureBuilder<List<Todo>>(
      future: todos,
      builder: (BuildContext context, AsyncSnapshot<List<Todo>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Container();
          case ConnectionState.done:
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            return RefreshIndicator(
                onRefresh: refreshTodos,
                child: ListView(
                  //padding: const EdgeInsets.all(8),
                  children: snapshot.data.map(todoItemWidget).toList(),
                ));
        }
        return null; // unreachable
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Text(widget.title),
            Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Text('Syncing to',
                    style: TextStyle(
                      fontSize: 12,
                    ))),
            Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Text(dropboxOrgFilePath.value,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    )))
          ],
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(hintText: INPUT_PLACEHOLDER),
              controller: _txtControl,
              enabled: !_isBusy,
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
            ),
            Visibility(
              visible: !_isBusy,
              child: IconButton(
                icon: Icon(Icons.add),
                tooltip: 'Add Todo',
                onPressed: _todoTextActive ? submitTodoState : null,
                iconSize: 48,
                color: _todoTextActive ? Colors.blue : Colors.grey,
              ),
            ),
            Visibility(
                visible: _isBusy,
                child: CircularProgressIndicator(
                  value: null,
                )),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
            ),
            Expanded(
              child: todoListWidget(),
            )
          ],
        ),
      ),
    );
  }
}
