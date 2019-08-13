import 'dart:convert';

import 'package:http/http.dart';
import 'package:json_object_lite/json_object_lite.dart';
import 'package:sporran/src/WiltResponse.dart';
import 'package:wilt/wilt.dart';
import 'package:http/http.dart' as http;
import 'package:sporran/src/wilt/WiltBaseHTTPAdapter.dart';


class WiltServerClient2 extends Wilt {
  WiltServerClient2(host, port, scheme, [Object clientCompletion])
        : super(host, port, scheme, new WiltServerHTTPAdapter2(), clientCompletion);
}
      
class WiltServerHTTPAdapter2 extends WiltBaseHTTPAdapter {

  /// HTTP client
  final http.Client _client = new http.Client();

  Future<dynamic> doRequest({String url, String httpMethod, String data = null, Map headers = null, bool withCredentials}) async {

    try {
      /**
       *  Query CouchDB over HTTP
       */
            print("doing request url=$url httpMethod=$httpMethod data=$data headers=$headers withCredentials=$withCredentials");

      Response response;
      switch (httpMethod) {
        case "GET":
          response = await _client.get(url, headers: headers);
          break;
        case "PUT":
          response = await _client.put(url, headers: headers, body: data);
          break;
        case "POST":
          response = await _client.post(url, headers: headers, body: data);
          break;
        case "HEAD":
          response = await _client.head(url, headers: headers);
          break;
        case "DELETE":
          response = await _client.delete(url, headers:headers);
          break;
        case "COPY": // TODO - this is not tested.
          final Uri encodedUrl = Uri.parse(url);
          final request = new http.Request("COPY", encodedUrl);
          request.headers.addAll(headers);
          final StreamedResponse streamedResponse = await _client.send(request);
          return new WiltResponse.from(await streamedResponse.stream.toBytes(), httpMethod, null, response.headers, response.statusCode);
      }
      return new WiltResponse.from(response.bodyBytes, httpMethod,
          null, response.headers, response.statusCode);
    } catch(err) {
      
      if(err.message == null) {
        print("Unknown HTTP error : $err");
      }
      return new WiltResponse.fromError(
          "Invalid HTTP response",
          err.message,
          null,
          httpMethod,
          null);
    }
  }

}
