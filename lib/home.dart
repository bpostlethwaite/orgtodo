import 'package:flutter/material.dart';
import './dropbox.dart';
import 'dart:async';

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
  final TextEditingController _txtControl = new TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    this._txtControl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          ),
        ),
      ),
    );
  }
}
