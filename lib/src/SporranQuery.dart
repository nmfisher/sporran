import 'package:json_object_lite/json_object_lite.dart';

class SporranQuery {
  bool localResponse;
  String operation;
  bool ok;
  dynamic payload;
  String id;
  dynamic rev;
  int errorCode;
  String errorText;
  String errorReason;

  @override 
  String toString() {
    return "localResponse=$localResponse, operation=$operation, ok=$ok, id=$id, rev=$rev, errorCode=$errorCode, errorText=$errorText, errorReason=$errorReason, payload=$payload";
  }
}

class SporranAllDocsQuery extends SporranQuery {
  int totalRows;
  List<String> keyList;
}