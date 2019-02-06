import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import './properties.dart';

class Status {
  int statusCode;
  String msg;

  Status(this.statusCode, this.msg);

  bool isOK() => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> toJson() {
    return jsonDecode(msg);
  }

  String toString() {
    var lines = msg.split('\n');
    var truncatedMsg = '';
    if (lines.length >= 7) {
      truncatedMsg = lines.sublist(0, 3).join('n') +
          '\n' +
          lines.sublist(lines.length - 3, lines.length).join('\n');
    } else {
      truncatedMsg = msg;
    }

    return "code: $statusCode\nmsg: $truncatedMsg";
  }
}

class Dropbox {
  Property token;
  Property path;

  Dropbox() {
    this.token = new Property('accessToken');
    this.path = new Property('dropboxOrgFilePath');
  }

  Future<Status> responseStatus(HttpClientResponse res) async {
    var msg = '';
    await for (var contents in res.transform(Utf8Decoder())) {
      msg += contents;
    }
    return Status(res.statusCode, msg);
  }

  Future<Status> dropboxRequest(String domain, String urlPath, String arg) async {
    var uri = new Uri.https(domain, urlPath);
    var request = await new HttpClient().postUrl(uri);
    request.headers.add('Authorization', 'Bearer ${token.value}');
    if (domain.startsWith('content')) {
      request.headers.add('Dropbox-API-Arg', arg);
    } else {
      request.headers.contentType = new ContentType('application', 'json');
      request.write(arg);
    }

    var response = await request.close();
    return await responseStatus(response);
  }

  Future<Status> getFileMetaData() async {
    final arg = json.encode({'path': path.value});
    return await dropboxRequest(
        'api.dropboxapi.com', '/2/files/get_metadata', arg);
  }

  Future<Status> loadFileContent() async {
    final arg = json.encode({'path': path.value});
    return await dropboxRequest(
        'content.dropboxapi.com', '/2/files/download', arg);
  }

  Future<Status> uploadFile(String content, String rev) async {
    final arg = json.encode({
      'path': path.value,
      'mode': {'.tag': 'update', 'update': rev},
    });
    var uri = new Uri.https('content.dropboxapi.com', '/2/files/upload');
    var request = await new HttpClient().postUrl(uri);

    request.headers.add('Authorization', 'Bearer ${token.value}');
    request.headers.add('Dropbox-API-Arg', arg);
    request.headers.contentType =
        new ContentType('application', 'octet-stream');

    request.add(Utf8Encoder().convert(content));

    var response = await request.close();
    return responseStatus(response);
  }

  Future<Status> addTodo(todoText) async {
    Status metaStatus = await getFileMetaData();
    debugPrint('metaStatus: $metaStatus');
    if (!metaStatus.isOK()) {
      return metaStatus;
    }
    var metaJson = metaStatus.toJson();
    var rev = metaJson['rev'];

    Status contentStatus = await loadFileContent();
    debugPrint('contentStatus: $contentStatus');
    if (!contentStatus.isOK()) {
      return contentStatus;
    }
    var lines = contentStatus.msg.split('/n');
    var todoLine = '* TODO $todoText';
    lines.add(todoLine);

    var scheduleLine = 'SCHEDULED: <${formatDateAsOrg(getNextWeekday())}>';
    lines.add(scheduleLine);

    Status uploadStatus = await uploadFile(lines.join('\n'), rev);
    debugPrint('uploadStatus: $uploadStatus');

    return uploadStatus;
  }
}

DateTime getNextWeekday() {
  var now = DateTime.now();
  var tomorrow = now.add(Duration(days: 1));
  if (tomorrow.weekday == DateTime.saturday) {
    return tomorrow.add(Duration(days: 2));
  } else if (tomorrow.weekday == DateTime.sunday) {
    return tomorrow.add(Duration(days: 1));
  }
  return tomorrow;
}

String formatDateAsOrg(DateTime datetime) {
  var formatter = new DateFormat('yyyy-MM-dd E');
  return formatter.format(datetime);
}