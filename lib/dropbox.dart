import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import './properties.dart';
import './utils.dart';

class Dropbox implements Backend {
  Property token;
  Property dropboxOrgFilePath;

  Dropbox() {
    this.token = new Property('accessToken');
    this.dropboxOrgFilePath = new Property('dropboxOrgFilePath');
  }

  Future<Status> responseStatus(HttpClientResponse res) async {
    var msg = '';
    await for (var contents in res.transform(Utf8Decoder())) {
      msg += contents;
    }
    return Status(res.statusCode, msg);
  }

  Future<Status> dropboxRequest(
      String domain, String urlPath, String arg) async {
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
    final arg = json.encode({'path': dropboxOrgFilePath.value});
    return await dropboxRequest(
        'api.dropboxapi.com', '/2/files/get_metadata', arg);
  }

  Future<Status> loadFileContent() async {
    final arg = json.encode({'path': dropboxOrgFilePath.value});
    return await dropboxRequest(
        'content.dropboxapi.com', '/2/files/download', arg);
  }

  Future<Status> uploadFile(String content, String rev) async {
    final arg = json.encode({
      'path': dropboxOrgFilePath.value,
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

  Future<Status> updateFile(String Function(String) transform) async {
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

    var content = transform(contentStatus.msg);

    Status uploadStatus = await uploadFile(content, rev);
    debugPrint('uploadStatus: $uploadStatus');

    return uploadStatus;
  }
}
