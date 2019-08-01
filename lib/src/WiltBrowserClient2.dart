import 'dart:convert';

import 'package:json_object_lite/json_object_lite.dart';
import 'package:sporran/src/WiltResponse.dart';
import 'package:wilt/wilt.dart';
import 'package:wilt/wilt_browser_client.dart';
import 'dart:html' as html;

class WiltBrowserClient2 extends Wilt {
  WiltBrowserClient2(host, port, scheme, [Object clientCompletion])
        : super(host, port, scheme, new WiltBrowserHTTPAdapter2(), clientCompletion);
}
      
class WiltBrowserHTTPAdapter2 extends WiltHTTPAdapter {
  
  /// User for change notification authorization
  String _user;

  /// Password for change notification authorization
  String _password;

  /// Auth Type for change notification authorization
  String _authType;

  /// Construction
  WiltBrowserHTTPAdapter2();

  /// Processes the HTTP request, returning the server's response
  /// as a future
  Future<dynamic> httpRequest(String method, String url,
      [String data = null, Map headers = null]) async {
    
    /**
     * Condition the input method string to get the HTTP method
     */
    final temp = method.split('_');
    final String httpMethod = temp[0];

    /**
     *  Query CouchDB over HTTP
     */
    try {
      html.HttpRequest response = await html.HttpRequest.request(url,
        method: httpMethod,
        withCredentials: true,
        responseType: null,
        requestHeaders: headers,
        sendData: data);
      
      /**
       *  Process the success response, note that an error response from CouchDB is
       *  treated as an error, not as a success with an 'error' field in it.
       */
      return new WiltResponse.from(response.responseText, method, response.getAllResponseHeaders(), response.responseHeaders);

    } catch(response) {
      if(response.target == null) {
        throw new Exception(response);
      }
      return new WiltResponse.fromError(response.target.responseText, response.target.status, method, response.target.getAllResponseHeaders());
    }
  }

  /// Specialised 'get' for change notifications
  Future<String> getString(String url) async {

    /* Must have authentication */
    final Map wiltHeaders = new Map<String, String>();
    wiltHeaders["Accept"] = "application/json";
    if (_user != null) {
      switch (_authType) {
        case Wilt.authBasic:
          final String authStringToEncode = "$_user:$_password";
          final String encodedAuthString =
              new Base64Encoder().convert(authStringToEncode.codeUnits);
          final String authString = "Basic $encodedAuthString";
          wiltHeaders['Authorization'] = authString;
          break;
        case Wilt.authNone:
          break;
      }
    }
    final dynamic response = await html.HttpRequest.request(url,
            method: 'GET', withCredentials: true, requestHeaders: wiltHeaders);
    return response.responseText;
  }

  /// Authentication parameters for change notification
  void notificationAuthParams(String user, String password, String authType) {
    _user = user;
    _password = password;
    _authType = authType;
  }
}
