import 'dart:convert';

import 'package:json_object_lite/json_object_lite.dart';
import 'package:sporran/src/wilt/WiltBaseHTTPAdapter.dart';
import 'package:sporran/src/WiltResponse.dart';
import 'package:wilt/wilt.dart';
import 'package:wilt/wilt_browser_client.dart';
import 'dart:html' as html;

class WiltBrowserClient2 extends Wilt {
  WiltBrowserClient2(host, port, scheme, [Object clientCompletion])
      : super(host, port, scheme, new WiltBrowserHTTPAdapter2(),
            clientCompletion);
}

class WiltBrowserHTTPAdapter2 extends WiltBaseHTTPAdapter {
  Future<dynamic> doRequest(
      {String url,
      String httpMethod,
      String data,
      Map headers,
      bool withCredentials}) async {
    /**
     *  Process the success response, note that an error response from CouchDB is
     *  treated as an error, not as a success with an 'error' field in it.
     */
    try {
      final dynamic response = await html.HttpRequest.request(url,
          method: httpMethod,
          withCredentials: true,
          responseType: null,
          requestHeaders: headers,
          sendData: data);
      return new WiltResponse.from(response.responseText, httpMethod,
          response.getAllResponseHeaders(), response.responseHeaders);
    } catch (response) {
      if(response.target == null) {
        print("Unknown HTTP error : $response");
        throw Exception(response);
      }
      return new WiltResponse.fromError(
          response.target.responseText,
          null,
          response.target.status,
          httpMethod,
          response.target.getAllResponseHeaders());
    }
  }
}
