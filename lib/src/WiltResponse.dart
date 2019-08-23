import 'dart:convert';
import 'dart:typed_data';
import 'package:wilt/wilt.dart';

class WiltResponse {
  WiltResponse.from(Uint8List responseBody, this.method, this.allResponseHeaders,
      Map<String, String> headers, int statusCode) {
    try {
      responseText = utf8.decode(responseBody);
    /**
     * Check the header, if application/json try and decode it,
     * otherwise its just raw data, ie an attachment.
     */
      if (headers.containsValue('application/json')) {
        final dynamic responseJson = json.decode(responseText);
        /* If the request itself was successful but the response contains an error */
        if (responseJson is Map && responseJson != null && responseJson["error"] != null) {
          print("Processing error response : $responseJson");
          error = true;
          jsonCouchResponse = Map<String,String>();
          jsonCouchResponse["reason"] = responseJson['reason'];
          jsonCouchResponse["error"] = responseJson['reason'];
          errorCode = statusCode;
        } else if (method != Wilt.headd) {
          jsonCouchResponse = responseJson;
        }
      } else {
        jsonCouchResponse = jsonDecode("{\"ok\":true, \"contentType\": \"${headers['content-type']}\"}");
      }
    } catch (e) {
      print("JSON decode error : $e");
      print("Stacktrace : ${e.stackTrace}");
      error = true;
      jsonCouchResponse = {
        "error":"json Decode Error",
        "reason":"None"
      };
    }
  }

  WiltResponse.fromError(this.responseText, this.errorText, this.errorCode, this.method, this.allResponseHeaders) {
    error = true;
    if ((errorCode != 0) && (method != Wilt.headd)) {
      jsonCouchResponse = jsonDecode(responseText);
    } else {
      jsonCouchResponse = jsonDecode("{\"error\":\"Invalid HTTP response\", \"reason\":\"HEAD or status code of 0\"}");
    }
  }

  @override 
  String toString() {
    return "error: $error, errorCode: $errorCode, successText:$successText, errorText:$errorText, allResponseHeaders:$allResponseHeaders, method:$method, responseText:$responseText, jsonCouchResponse: $jsonCouchResponse";
  }

  bool error = false;
  int errorCode = 0;
  String successText;
  String errorText;
  String allResponseHeaders;
  String method;
  String responseText;
  dynamic jsonCouchResponse;
}
