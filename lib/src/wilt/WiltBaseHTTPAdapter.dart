
import 'dart:convert';

import 'package:sporran/src/WiltResponse.dart';
import 'package:wilt/wilt.dart';

/*
* This is a base HTTP adapter
*
*/
abstract class WiltBaseHTTPAdapter extends WiltHTTPAdapter {
  
  /// User for change notification authorization
  String _user;

  /// Password for change notification authorization
  String _password;

  /// Auth Type for change notification authorization
  String _authType;

  /// Authentication parameters for change notification
  void notificationAuthParams(String user, String password, String authType) {
    _user = user;
    _password = password;
    _authType = authType;
  }

  /// Subclasses must provide an implementation to actually perform the request
  /// Browser-based implementations may use html.HttpRequest
  /// Server-based implementations may use http.Client
  Future<dynamic> doRequest({String url, String httpMethod, String data = null, Map headers = null, bool withCredentials});

  /// Initiates the HTTP request, returning the server's response
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
    return doRequest(url:url, httpMethod:httpMethod, data:data, headers:headers);
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
    final dynamic response = await doRequest(url:url,
            httpMethod: 'GET', withCredentials: true, headers: wiltHeaders);
    return response.responseText;
  }
}