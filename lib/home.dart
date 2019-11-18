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
  String _status = '';
  bool _isBusy = false;
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
    todos = fetchTodos();
  }

  void submitTodoState() async {
    var todoText = _txtControl.text;
    setState(() {
      _status = '';
      _isBusy = true;
    });
    if (todoText.length > 1) {
      Status status;
      try {
        status = await Dropbox().addTodo(todoText);
      } catch (e) {
        status = Status(999, e.toString());
      }
      setState(() {
        if (status.isOK()) {
          _status = SUCCESS_TEXT;
        } else {
          _status = FAILURE_TEXT;
        }
        _isBusy = false;
      });

      // reset the input box
      _txtControl.clear();

      // set success / failure animation
      new Timer(Duration(seconds: 2), () {
        setState(() {
          _status = '';
        });
      });
    }
  }

  Widget todoWidget() {
    return FutureBuilder<List<Todo>>(
      future: todos,
      builder: (BuildContext context, AsyncSnapshot<List<Todo>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Container();
          case ConnectionState.done:
            if (snapshot.hasError)
              return Text('Error: ${snapshot.error}');
            return ListView(
              padding: const EdgeInsets.all(8),
              children: snapshot.data.map((todo) => Container(
                height: 50,
                child: Text(todo.text),
              ),
              ).toList(),
            );
        }
        return null; // unreachable
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title:Row(
            children: <Widget>[
              Text(widget.title),
              Padding(
                padding: EdgeInsets.only(left:20.0),
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
                    onPressed: submitTodoState,
                    iconSize: 48,
                    color: Colors.blue,
                  ),
                ),
                Visibility(
                    visible: _isBusy,
                    child: CircularProgressIndicator(
                      value: null,
                    )),
                AnimatedOpacity(
                    opacity: _status.length > 0 ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color:
                            _status == SUCCESS_TEXT ? Colors.green : Colors.red,
                      ),
                    )),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                ),
                Expanded(
                  child: todoWidget(),
                )
              ],
            ),
          ),
        );
  }
}
