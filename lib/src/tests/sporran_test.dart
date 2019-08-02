/*
 * Package : Sporran
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/02/2014
 * Copyright :  S.Hamblett@OSCF
 */

import 'dart:async';

import 'package:sporran/lawndart.dart';
import 'package:json_object_lite/json_object_lite.dart';
import 'package:sporran/src/Sporran.dart';
import 'package:sporran/src/SporranException.dart';
import 'package:sporran/src/SporranInitialiser.dart';
import 'package:sporran/src/SporranQuery.dart';
import 'package:wilt/wilt.dart';
import 'package:test/test.dart';

typedef SporranFactory = Future<Sporran> Function(SporranInitialiser initialiser);

void logMessage(String message) {
  print("CONSOLE : $message");
}

void run(Wilt wilt, SporranInitialiser initialiser, SporranFactory getSporran) async {

  /* Group 2 - Sporran constructor/ invalid parameter tests */
  group("2. Constructor/Invalid Parameter Tests - ", ()  {
    Sporran sporran;

    test("0. Sporran Initialisation", () async {
      print("2.0");
      sporran = await getSporran(initialiser);
      sporran.autoSync = false;
      expect(sporran, isNotNull);
      expect(sporran.dbName, initialiser.dbName);
      expect(sporran.online, true);
    });

    test("2. Construction Existing Database ", () async {
      print("2.2");
      Sporran sporran22 = await getSporran(initialiser);
      expect(sporran22, isNotNull);
      expect(sporran22.dbName, initialiser.dbName);
    });

    // Wilt has a bug whereby HttpRequest errors (like authentication failures) aren't cleanly caught.
    // These errors propagate up and will cause the test to fail, even though everything's working as intended.
    // To run successfully, this test requires a patch to Wilt that hasn't been submitted yet - so don't worry if the test fails for now :)
    test("3. Construction Invalid Authentication ", () async {
      print("2.3");
      var password = initialiser.password;
      initialiser.password = 'none';
      Sporran sporran23 = await getSporran(initialiser);
      
      // reset the initialiser password so later tests can properly connect
      initialiser.password = password;
      expect(sporran23, isNotNull);
      expect(sporran23.dbName, initialiser.dbName);
    });

    test("4. Put No Doc Id ", () async {
      print("2.4");

      var pred = predicate((e) => 
        e.runtimeType.toString() ==  'SporranException' &&
        e.toString() == SporranException.headerEx + SporranException.putNoDocIdEx
      );
      expect(
        () async => await sporran.put(null, null), 
        throwsA(pred)
      );
    });

    test("5. Get No Doc Id ", () {
      print("2.5");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.getNoDocIdEx);
      });

      sporran.get(null, null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("6. Delete No Doc Id ", () {
      print("2.6");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.deleteNoDocIdEx);
      });

      sporran.delete(null, null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("7. Put Attachment No Doc Id ", () {
      print("2.7");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.putAttNoDocIdEx);
      });

      sporran.putAttachment(null, null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("8. Put Attachment No Attachment ", () {
      print("2.8");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.putAttNoAttEx);
      });

      sporran.putAttachment('billy', null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("9. Delete Attachment No Doc Id ", () {
      print("2.9");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.deleteAttNoDocIdEx);
      });

      sporran.deleteAttachment(null, null, null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("10. Delete Attachment No Attachment Name ", () {
      print("2.10");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.deleteAttNoAttNameEx);
      });

      sporran.deleteAttachment('billy', null, null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("11. Delete Attachment No Revision ", () {
      print("2.11");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.deleteAttNoRevEx);
      });
      //sporran.online = false;
      sporran.deleteAttachment('billy', 'fred', null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("12. Get Attachment No Doc Id ", () {
      print("2.12");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.getAttNoDocIdEx);
      });

      sporran.getAttachment(null, null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("13. Get Attachment No Attachment Name ", () {
      print("2.13");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.getAttNoAttNameEx);
      });

      sporran.getAttachment('billy', null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("14. Bulk Create No Document List ", () {
      print("2.14");

      final completer = expectAsync1((e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.bulkCreateNoDocListEx);
      });

      sporran.bulkCreate(null)
        ..then((_) {}, onError: (e) {
          completer(e);
        });
    });

    test("15. Login invalid user ", () {
      print("2.15");

      try {
        sporran.login(null, 'password');
      } catch (e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.invalidLoginCredsEx);
      }
    });

    test("16. Login invalid password ", () {
      print("2.16");

      try {
        sporran.login('billy', null);
      } catch (e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.invalidLoginCredsEx);
      }
    });

    test("17. Null Initialiser ", () async {
      print("2.17");

      try {
        final Sporran bad = await getSporran(null);
        bad.toString();
      } catch (e) {
        expect(e.runtimeType.toString(), 'SporranException');
        expect(e.toString(),
            SporranException.headerEx + SporranException.noInitialiserEx);
      }
    });
  }, skip: false);

  /* Group 3 - Sporran document put/get tests */
  group("3. Document Put/Get/Delete Tests - ", () {
    Sporran sporran3;

    final String docIdPutOnline = "putOnlineg3";
    final String docIdPutOffline = "putOfflineg3";
    final dynamic onlineDoc = new JsonObjectLite();
    final dynamic offlineDoc = new JsonObjectLite();
    String onlineDocRev;

    test("1. Create and Open Sporran", () async {
      print("3.1");
      await wilt.deleteDatabase(initialiser.dbName);
      wilt.db = initialiser.dbName;
      sporran3 = await getSporran(initialiser);
      sporran3.online = true;
      sporran3.autoSync = false;
      expect(sporran3.dbName, initialiser.dbName);
      expect(sporran3.lawnIsOpen, isTrue);
    });

    test("2. Put Document Online docIdPutOnline", () async {
      print("3.2");
      onlineDoc.name = "Online";
      sporran3.online = true;
      SporranQuery res = await sporran3.put(docIdPutOnline, onlineDoc);
      print(res);
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.putc);
      expect(res.localResponse, isFalse);
      expect(res.id, docIdPutOnline);
      expect(res.rev, anything);
      onlineDocRev = res.rev;
      expect(res.payload.name, "Online");
    });

    test("3. Put Document Offline docIdPutOffline", () {
      print("3.3");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.putc);
        expect(res.localResponse, isTrue);
        expect(res.id, docIdPutOffline);
        expect(res.payload.name, "Offline");
      });

      sporran3.online = false;
      offlineDoc.name = "Offline";
      sporran3.put(docIdPutOffline, offlineDoc)
        ..then((res) {
          wrapper(res);
        });
    });

    test("4. Put Document Online Conflict", () async {
      print("3.4");
      sporran3.online = true;
      onlineDoc.name = "Online";
      final SporranQuery res = await sporran3.put(docIdPutOnline, onlineDoc);
      expect(res.errorCode, 409);
      expect(res.errorText, 'conflict');
      expect(res.operation, Sporran.putc);
      expect(res.id, docIdPutOnline);
    });

    test("5. Put Document Online Updated docIdPutOnline", () {
      print("3.5");

      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.putc);
        expect(res.localResponse, isFalse);
        expect(res.id, docIdPutOnline);
        expect(res.rev, anything);
        expect(res.payload.name, "Online - Updated");
      });

      onlineDoc.name = "Online - Updated";
      sporran3.online = true;
      sporran3.put(docIdPutOnline, onlineDoc, onlineDocRev)
        ..then((res) {
          wrapper(res);
        });
    });

    test("6. Get Document Offline docIdPutOnline", () async {
      print("3.6");
      sporran3.online = false;
      final dynamic res = await sporran3.get(docIdPutOnline);
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.getc);
      expect(res.localResponse, isTrue);
      expect(res.id, docIdPutOnline);
      expect(res.payload.name, "Online - Updated");
    });

    test("7. Get Document Offline docIdPutOffline", () {
      print("3.7");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.getc);
        expect(res.localResponse, isTrue);
        expect(res.id, docIdPutOffline);
        expect(res.payload.name, "Offline");
        expect(res.rev, isNull);
      });

      sporran3.online = false;
      sporran3.get(docIdPutOffline)
        ..then((res) {
          wrapper(res);
        });
    });

    test("8. Get Document Offline Not Exist", () async {
      print("3.8");
      sporran3.online = false;
      final dynamic res = await sporran3.get("Billy");
      expect(res.ok, isFalse);
      expect(res.operation, Sporran.getc);
      expect(res.localResponse, isTrue);
      expect(res.id, "Billy");
      expect(res.rev, isNull);
      expect(res.payload, isNull);
    });

    test("9. Get Document Online docIdPutOnline", () async {
      print("3.9");
      sporran3.online = true;
      var res = await sporran3.get(docIdPutOnline);
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.getc);
      expect(res.payload.name, "Online - Updated");
      expect(res.localResponse, isFalse);
      expect(res.id, docIdPutOnline);
      onlineDocRev = res.rev;
    });

    test("10. Delete Document Offline", () {
      print("3.10");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.localResponse, isTrue);
        expect(res.operation, Sporran.deletec);
        expect(res.id, docIdPutOffline);
        expect(res.payload, isNull);
        expect(res.rev, isNull);
        expect(sporran3.pendingDeleteSize, 1);
      });

      sporran3.online = false;
      sporran3.delete(docIdPutOffline)
        ..then((res) {
          wrapper(res);
        });
    });

    test("11. Delete Document Online", () {
      print("3.11");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.localResponse, isFalse);
        expect(res.operation, Sporran.deletec);
        expect(res.id, docIdPutOnline);
        expect(res.payload, isNotNull);
        expect(res.rev, anything);
      });

      sporran3.online = true;
      sporran3.delete(docIdPutOnline, onlineDocRev)
        ..then((res) {
          wrapper(res);
        });
    });

    test("12. Get Document Online Not Exist", () {
      print("3.12");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isFalse);
        expect(res.operation, Sporran.getc);
        expect(res.localResponse, isFalse);
        expect(res.id, "Billy");
      });
      sporran3.online = true;
      sporran3.get("Billy")
        ..then((res) {
          wrapper(res);
        });
    });

    test("13. Delete Document Not Exist", () {
      print("3.13");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isFalse);
        expect(res.operation, Sporran.deletec);
        expect(res.id, "Billy");
        expect(res.payload, isNull);
        expect(res.rev, isNull);
      });

      sporran3.online = false;
      sporran3.delete("Billy")
        ..then((res) {
          wrapper(res);
        });
    });

    test("14. Group Pause", () {
      print("3.14");
      final wrapper = expectAsync0(() {});
      new Timer(new Duration(seconds: 3), wrapper);
    });
  }, skip: false);

  /* Group 4 - Sporran attachment put/get tests */
  group("4. Attachment Put/Get/Delete Tests - ", () {
    Sporran sporran4;

    final String docIdPutOnline = "putOnlineg4";
    final String docIdPutOffline = "putOfflineg4";
    final dynamic onlineDoc = new JsonObjectLite();
    final dynamic offlineDoc = new JsonObjectLite();
    String onlineDocRev;

    final String attachmentPayload =
        'iVBORw0KGgoAAAANSUhEUgAAABwAAAASCAMAAAB/2U7WAAAABl' +
            'BMVEUAAAD///+l2Z/dAAAASUlEQVR4XqWQUQoAIAxC2/0vXZDr' +
            'EX4IJTRkb7lobNUStXsB0jIXIAMSsQnWlsV+wULF4Avk9fLq2r' +
            '8a5HSE35Q3eO2XP1A1wQkZSgETvDtKdQAAAABJRU5ErkJggg==';

    test("1. Create and Open Sporran", () async {
      print("4.1");
      sporran4 = await getSporran(initialiser);
      expect(sporran4.dbName, initialiser.dbName);
      expect(sporran4.lawnIsOpen, isTrue);
      sporran4.autoSync = false;
    });

    test("2. Put Document Online docIdPutOnline", () async {
      print("4.2");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.putc);
        expect(res.id, docIdPutOnline);
        expect(res.localResponse, isFalse);
        expect(res.payload.name, "Online");
        expect(res.rev, anything);
        onlineDocRev = res.rev;
      });

      sporran4.online = true;
      onlineDoc.name = "Online";
      sporran4.put(docIdPutOnline, onlineDoc)
        ..then((res) {
          wrapper(res);
        });
    });

    test("3. Put Document Offline docIdPutOffline", () {
      print("4.3");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.putc);
        expect(res.id, docIdPutOffline);
        expect(res.localResponse, isTrue);
        expect(res.payload.name, "Offline");
      });

      sporran4.online = false;
      offlineDoc.name = "Offline";
      sporran4.put(docIdPutOffline, offlineDoc)
        ..then((res) {
          wrapper(res);
        });
    });

    test("4. Create Attachment Online docIdPutOnline", () {
      print("4.4");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.putAttachmentc);
        expect(res.id, docIdPutOnline);
        expect(res.localResponse, isFalse);
        expect(res.rev, anything);
        onlineDocRev = res.rev;
        expect(res.payload.attachmentName, "onlineAttachment");
        expect(res.payload.contentType, 'image/png');
        expect(res.payload.payload, attachmentPayload);
      });

      sporran4.online = true;
      final dynamic attachment = new JsonObjectLite();
      attachment.attachmentName = "onlineAttachment";
      attachment.rev = onlineDocRev;
      attachment.contentType = 'image/png';
      attachment.payload = attachmentPayload;
      sporran4.putAttachment(docIdPutOnline, attachment)
        ..then((res) {
          wrapper(res);
        });
    });

    test("5. Create Attachment Offline docIdPutOffline", () {
      print("4.5");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.putAttachmentc);
        expect(res.id, docIdPutOffline);
        expect(res.localResponse, isTrue);
        expect(res.rev, isNull);
        expect(res.payload.attachmentName, "offlineAttachment");
        expect(res.payload.contentType, 'image/png');
        expect(res.payload.payload, attachmentPayload);
      });

      sporran4.online = false;
      final dynamic attachment = new JsonObjectLite();
      attachment.attachmentName = "offlineAttachment";
      attachment.rev = onlineDocRev;
      attachment.contentType = 'image/png';
      attachment.payload = attachmentPayload;
      sporran4.putAttachment(docIdPutOffline, attachment)
        ..then((res) {
          wrapper(res);
        });
    });

    test("6. Get Attachment Online docIdPutOnline", () async {
      print("4.6");
      sporran4.online = true;
      dynamic res  = await sporran4.getAttachment(docIdPutOnline, "onlineAttachment");
      print(res);
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.getAttachmentc);
      expect(res.id, docIdPutOnline);
      expect(res.localResponse, isFalse);
      expect(res.rev, anything);
      expect(res.payload.attachmentName, "onlineAttachment");
      expect(res.payload.contentType == 'image/png' || res.payload.contentType == 'image/png; charset=utf-8', true);
      expect(res.payload.payload, attachmentPayload);
        
    });

    test("7. Get Attachment Offline docIdPutOffline", () {
      print("4.7");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.getAttachmentc);
        expect(res.id, docIdPutOffline);
        expect(res.localResponse, isTrue);
        expect(res.rev, isNull);
        print(res.payload);
        expect(res.payload.payload.attachmentName, "offlineAttachment");
        expect(res.payload.payload.contentType, 'image/png');
        expect(res.payload.payload.payload, attachmentPayload);
      });

      sporran4.online = false;
      sporran4.getAttachment(docIdPutOffline, "offlineAttachment")
        ..then((res) {
          wrapper(res);
        });
    });

    test("8. Get Document Online docIdPutOnline", () async {
      print("4.8");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.getc);
        expect(res.id, docIdPutOnline);
        expect(res.localResponse, isFalse);
        expect(res.rev, onlineDocRev);
        final List attachments = WiltUserUtils.getAttachments(res.payload);
        expect(attachments.length, 1);
      });

      sporran4.online = true;

      sporran4.get(docIdPutOnline, onlineDocRev)
        ..then((res) {
          wrapper(res);
        });
    });

    test("9. Delete Attachment Online docIdPutOnline", () async {
      print("4.9");
      sporran4.online = true;
      sporran4.autoSync = false;
      final dynamic res = await sporran4.deleteAttachment(docIdPutOnline, "onlineAttachment", onlineDocRev);
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.deleteAttachmentc);
      expect(res.id, docIdPutOnline);
      expect(res.localResponse, isFalse);
      onlineDocRev = res.rev;
      expect(res.rev, anything);
    });

    test("10. Delete Document Online docIdPutOnline", () {
      print("4.10");
      final wrapper = expectAsync1((res) {});

      /* Tidy up only, tested in group 3 */
      sporran4.delete(docIdPutOnline, onlineDocRev)
        ..then((res) {
          wrapper(res);
        });
    });

    test("11. Delete Attachment Offline docIdPutOffline", () {
      print("4.11");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.deleteAttachmentc);
        expect(res.id, docIdPutOffline);
        expect(res.localResponse, isTrue);
        expect(res.rev, isNull);
        expect(res.payload, isNull);
      });

      sporran4.online = false;
      sporran4.deleteAttachment(docIdPutOffline, "offlineAttachment", null)
        ..then((res) {
          wrapper(res);
        });
    });

    test("12. Delete Attachment Not Exist", () {
      print("4.12");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isFalse);
        expect(res.operation, Sporran.deleteAttachmentc);
        expect(res.id, docIdPutOffline);
        expect(res.localResponse, isTrue);
        expect(res.rev, isNull);
        expect(res.payload, isNull);
      });

      sporran4.online = false;
      sporran4.deleteAttachment(docIdPutOffline, "Billy", null)
        ..then((res) {
          wrapper(res);
        });
    }, skip: false);

    /*test("13. Group Pause", () {

      print("4.13");
      var wrapper = expectAsync0(() {});

      Timer pause = new Timer(new Duration(seconds: 3), wrapper);

    });*/
  });

  /* Group 5 - Sporran Bulk Documents tests */
  group("5. Bulk Document Tests - ", () {
    Sporran sporran5;
    String docid1rev;
    String docid2rev;
    String docid3rev;

    test("1. Create and Open Sporran", () async {
      print("5.1");
      await wilt.deleteDatabase(initialiser.dbName);
      wilt.db = initialiser.dbName;
      sporran5 = await getSporran(initialiser);
      sporran5.autoSync = false;
      expect(sporran5.dbName, initialiser.dbName);
      expect(sporran5.lawnIsOpen, isTrue);
    });

    test("2. Bulk Insert Documents Online", () async {
      print("5.2");
      
      final dynamic document1 = new JsonObjectLite();
      document1.title = "Document 1";
      document1.version = 1;
      document1.attribute = "Doc 1 attribute";

      final dynamic document2 = new JsonObjectLite();
      document2.title = "Document 2";
      document2.version = 2;
      document2.attribute = "Doc 2 attribute";

      final dynamic document3 = new JsonObjectLite();
      document3.title = "Document 3";
      document3.version = 3;
      document3.attribute = "Doc 3 attribute";

      final Map docs = new Map<String, JsonObjectLite>();
      docs['docid1'] = document1;
      docs['docid2'] = document2;
      docs['docid3'] = document3;

      final dynamic res = await sporran5.bulkCreate(docs);
      print(res);
      expect(res.ok, isTrue);
      expect(res.localResponse, isFalse);
      expect(res.operation, Sporran.bulkCreatec);
      expect(res.id, isNull);
      expect(res.payload, isNotNull);
      expect(res.rev, isNotNull);
      expect(res.rev[0].rev, anything);
      docid1rev = res.rev[0].rev;
      expect(res.rev[1].rev, anything);
      docid2rev = res.rev[1].rev;
      expect(res.rev[2].rev, anything);
      docid3rev = res.rev[2].rev;
      final dynamic doc3 = res.payload['docid3'];
      expect(doc3.title, "Document 3");
      expect(doc3.version, 3);
      expect(doc3.attribute, "Doc 3 attribute");
    });

    test("3. Bulk Insert Documents Offline", () async {
      print("5.3");
      final dynamic document1 = new JsonObjectLite();
      document1.title = "Document 1";
      document1.version = 1;
      document1.attribute = "Doc 1 attribute";

      final dynamic document2 = new JsonObjectLite();
      document2.title = "Document 2";
      document2.version = 2;
      document2.attribute = "Doc 2 attribute";

      final dynamic document3 = new JsonObjectLite();
      document3.title = "Document 3";
      document3.version = 3;
      document3.attribute = "Doc 3 attribute";

      final Map docs = new Map<String, JsonObjectLite>();
      docs['docid1offline'] = document1;
      docs['docid2offline'] = document2;
      docs['docid3offline'] = document3;

      sporran5.online = false;

      final dynamic res = await sporran5.bulkCreate(docs);
      expect(res.ok, isTrue);
      expect(res.localResponse, isTrue);
      expect(res.operation, Sporran.bulkCreatec);
      expect(res.id, isNull);
      expect(res.payload, isNotNull);
      expect(res.rev, isNull);
      final dynamic doc3 = res.payload['docid3offline'];
      expect(doc3.title, "Document 3");
      expect(doc3.version, 3);
      expect(doc3.attribute, "Doc 3 attribute");
    });

    test("4. Get All Docs Online", () {
      print("5.4");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.localResponse, isFalse);
        expect(res.operation, Sporran.getAllDocsc);
        expect(res.id, isNull);
        expect(res.rev, isNull);
        expect(res.payload, isNotNull);
        final dynamic successResponse = res.payload;
        print(successResponse);
        expect(successResponse.total_rows, equals(3));
        
        expect(successResponse.rows[0].id, equals('docid1'));
        expect(successResponse.rows[1].id, equals('docid2'));
        expect(successResponse.rows[2].id, equals('docid3'));
      });

      sporran5.online = true;
      sporran5.getAllDocs(includeDocs: true)
        ..then((res) {
          wrapper(res);
        });
    });

    test("5. Get All Docs Offline", () async {
      print("5.5");
      sporran5.online = false;
      final dynamic res = await sporran5.getAllDocs(keys: [
        'docid1offline',
        'docid2offline',
        'docid3offline',
        'docid1',
        'docid2',
        'docid3'
      ]);
      expect(res.ok, isTrue);
      expect(res.localResponse, isTrue);
      expect(res.operation, Sporran.getAllDocsc);
      expect(res.id, isNull);
      expect(res.rev, isNull);
      expect(res.payload, isNotNull);
      expect(res.payload.length, 6);
      expect(res.payload['docid1'].payload.title, "Document 1");
      expect(res.payload['docid2'].payload.title, "Document 2");
      expect(res.payload['docid3'].payload.title, "Document 3");
      expect(res.payload['docid1offline'].payload.title, "Document 1");
      expect(res.payload['docid2offline'].payload.title, "Document 2");
      expect(res.payload['docid3offline'].payload.title, "Document 3");
    });

    test("6. Get Database Info Offline", () {
      print("5.6");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.localResponse, isTrue);
        expect(res.operation, Sporran.dbInfoc);
        expect(res.id, isNull);
        expect(res.rev, isNull);
        expect(res.payload, isNotNull);
        expect(res.payload.length, 6);
        expect(res.payload.contains('docid1'), isTrue);
        expect(res.payload.contains('docid2'), isTrue);
        expect(res.payload.contains('docid3'), isTrue);
        expect(res.payload.contains('docid1offline'), isTrue);
        expect(res.payload.contains('docid2offline'), isTrue);
        expect(res.payload.contains('docid3offline'), isTrue);
      });

      sporran5.getDatabaseInfo()
        ..then((res) {
          wrapper(res);
        });
    });

    test("7. Get Database Info Online", () async {
      print("5.7");
      sporran5.online = true;
      sporran5.autoSync = false;
      SporranQuery res = await sporran5.getDatabaseInfo();
      expect(res.ok, isTrue);
      expect(res.localResponse, isFalse);
      expect(res.operation, Sporran.dbInfoc);
      expect(res.id, isNull);
      expect(res.rev, isNull);
      expect(res.payload, isNotNull);
      expect(res.payload.doc_count, 3);
      expect(res.payload.db_name, initialiser.dbName);
    });

    test("8. Tidy Up All Docs Online", () {
      print("5.8");
      final wrapper = expectAsync1((res) {}, count: 3);

      sporran5.delete('docid1', docid1rev)
        ..then((res) {
          wrapper(res);
        });
      sporran5.delete('docid2', docid2rev)
        ..then((res) {
          wrapper(res);
        });
      sporran5.delete('docid3', docid3rev)
        ..then((res) {
          wrapper(res);
        });
    });

  }, skip: false);

  /* Group 6 - Sporran Change notification tests */
  group("6. Change notification Tests Documents - ", () {
    Sporran sporran6;

    String docId1Rev;
    String docId2Rev;
    String docId3Rev;

    test("1. Create and Open Sporran", () async {
      print("6.1");
      await wilt.deleteDatabase(initialiser.dbName);
      wilt.db = initialiser.dbName;
      initialiser.manualNotificationControl = false;
      sporran6 = await getSporran(initialiser);
      sporran6.autoSync = false;
      initialiser.manualNotificationControl = true;
      expect(sporran6.dbName, initialiser.dbName);
      expect(sporran6.lawnIsOpen, isTrue);
    });

    test("2. Wilt - Bulk Insert Supplied Keys", () async {
      print("6.2");

      final dynamic document1 = new JsonObjectLite();
      document1.title = "Document 1";
      document1.version = 1;
      document1.attribute = "Doc 1 attribute";
      final String doc1 = WiltUserUtils.addDocumentId(document1, "MyBulkId1");
      final dynamic document2 = new JsonObjectLite();
      document2.title = "Document 2";
      document2.version = 2;
      document2.attribute = "Doc 2 attribute";
      final String doc2 = WiltUserUtils.addDocumentId(document2, "MyBulkId2");
      final dynamic document3 = new JsonObjectLite();
      document3.title = "Document 3";
      document3.version = 3;
      document3.attribute = "Doc 3 attribute";
      final String doc3 = WiltUserUtils.addDocumentId(document3, "MyBulkId3");
      final List docList = new List<String>();
      docList.add(doc1);
      docList.add(doc2);
      docList.add(doc3);
      final String docs = WiltUserUtils.createBulkInsertString(docList);
      final dynamic res = await wilt.bulkString(docs);
      
      expect(res.error, isFalse);

      final dynamic successResponse = res.jsonCouchResponse;
      expect(successResponse[0].id, equals("MyBulkId1"));
      expect(successResponse[1].id, equals("MyBulkId2"));
      expect(successResponse[2].id, equals("MyBulkId3"));
      docId1Rev = successResponse[0].rev;
      docId2Rev = successResponse[1].rev;
      docId3Rev = successResponse[2].rev;
    });

    /* Pause a little for the notifications to come through */
    test("3. Notification Pause", () {
      print("6.4");
      final wrapper = expectAsync0(() {});

      new Timer(new Duration(seconds: 3), wrapper);
    });

    /* Go offline and get our created documents, from local storage */
    test("4. Get Document Offline MyBulkId1", () async {
      print("6.4");
      sporran6.online = false;
      SporranQuery res = await sporran6.get("MyBulkId1");
      print(res);
      print(res.payload);
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.getc);
      expect(res.localResponse, isTrue);
      expect(res.id, "MyBulkId1");
      expect(res.payload.title, "Document 1");
      expect(res.payload["version"], 1);
      expect(res.payload["attribute"], "Doc 1 attribute");
    });

    test("5. Get Document Offline MyBulkId2", () async { 
      print("6.5");
      sporran6.online = false;
      SporranQuery res = await sporran6.get("MyBulkId2");
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.getc);
      expect(res.localResponse, isTrue);
      expect(res.id, "MyBulkId2");
      expect(res.payload.title, "Document 2");
      expect(res.payload.version, 2);
      expect(res.payload.attribute, "Doc 2 attribute");
    });

    test("6. Get Document Offline MyBulkId3", () async {
      print("6.6");
      SporranQuery res = await sporran6.get("MyBulkId3");
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.getc);
      expect(res.localResponse, isTrue);
      expect(res.id, "MyBulkId3");
      expect(res.payload.title, "Document 3");
      expect(res.payload.version, 3);
      expect(res.payload.attribute, "Doc 3 attribute");
    });

    test("7. Wilt - Delete Document MyBulkId1", () async {
      print("6.7");
      try {
        final dynamic res = await wilt.deleteDocument("MyBulkId1", docId1Rev);
        expect(res.error, isFalse);
        final dynamic successResponse = res.jsonCouchResponse;
        expect(successResponse.id, "MyBulkId1");
      } catch (e) {
        print(e.toString());
        logMessage("WILT::Delete Document MyBulkId1");
        // final dynamic errorResponse = res.jsonCouchResponse;
        // final String errorText = errorResponse.error;
        // logMessage("WILT::Error is $errorText");
        // final String reasonText = errorResponse.reason;
        // logMessage("WILT::Reason is $reasonText");
        // final int statusCode = res.errorCode;
        // logMessage("WILT::Status code is $statusCode");
      }
    });

    test("8. Wilt - Delete Document MyBulkId2", () {
      print("6.8");
      final wrapper = expectAsync1((res) {
        try {
          expect(res.error, isFalse);
        } catch (e) {
          logMessage("WILT::Delete Document MyBulkId2");
          final dynamic errorResponse = res.jsonCouchResponse;
          final String errorText = errorResponse.error;
          logMessage("WILT::Error is $errorText");
          final String reasonText = errorResponse.reason;
          logMessage("WILT::Reason is $reasonText");
          final int statusCode = res.errorCode;
          logMessage("WILT::Status code is $statusCode");
          return;
        }

        final dynamic successResponse = res.jsonCouchResponse;
        expect(successResponse.id, "MyBulkId2");
      });

      wilt.deleteDocument("MyBulkId2", docId2Rev)
        ..then((res) {
          wrapper(res);
        });
    });

    test("9. Wilt - Delete Document MyBulkId3", () {
      print("6.9");
      final wrapper = expectAsync1((res) {
        try {
          expect(res.error, isFalse);
        } catch (e) {
          logMessage("WILT::Delete Document MyBulkId3");
          final dynamic errorResponse = res.jsonCouchResponse;
          final String errorText = errorResponse.error;
          logMessage("WILT::Error is $errorText");
          final String reasonText = errorResponse.reason;
          logMessage("WILT::Reason is $reasonText");
          final int statusCode = res.errorCode;
          logMessage("WILT::Status code is $statusCode");
          return;
        }

        final dynamic successResponse = res.jsonCouchResponse;
        expect(successResponse.id, "MyBulkId3");
      });

      wilt.deleteDocument("MyBulkId3", docId3Rev)
        ..then((res) {
          wrapper(res);
        });
    });

    /* Pause a little for the notifications to come through */
    test("10. Notification Pause", () {
      print("6.10");
      final wrapper = expectAsync0(() {});

      new Timer(new Duration(seconds: 3), wrapper);
    });

    /* Go offline and get our created documents, from local storage */
    test("11. Get Document Offline Deleted MyBulkId1", () {
      print("6.11");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isFalse);
        expect(res.operation, Sporran.getc);
        expect(res.localResponse, isTrue);
      });

      sporran6.online = false;
      sporran6.get("MyBulkId1")
        ..then((res) {
          wrapper(res);
        });
    });

    test("12. Get Document Offline Deleted MyBulkId2", () {
      print("6.12");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isFalse);
        expect(res.operation, Sporran.getc);
        expect(res.localResponse, isTrue);
      });

      sporran6.get("MyBulkId2")
        ..then((res) {
          wrapper(res);
        });
    });

    test("13. Get Document Offline Deleted MyBulkId3", () {
      print("6.13");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isFalse);
        expect(res.operation, Sporran.getc);
        expect(res.localResponse, isTrue);
      });

      sporran6.get("MyBulkId3")
        ..then((res) {
          wrapper(res);
        });
    });

    test("14. Group Pause", () {
      print("6.14");
      final wrapper = expectAsync0(() {});

      new Timer(new Duration(seconds: 3), wrapper);
    });
  }, skip: false);

  /* Group 7 - Sporran Change notification tests */
  group("7. Change notification Tests Attachments - ", () {
    Sporran sporran7;

    String docId1Rev;
    final String attachmentPayload =
        'iVBORw0KGgoAAAANSUhEUgAAABwAAAASCAMAAAB/2U7WAAAABl' +
            'BMVEUAAAD///+l2Z/dAAAASUlEQVR4XqWQUQoAIAxC2/0vXZDr' +
            'EX4IJTRkb7lobNUStXsB0jIXIAMSsQnWlsV+wULF4Avk9fLq2r' +
            '8a5HSE35Q3eO2XP1A1wQkZSgETvDtKdQAAAABJRU5ErkJggg==';

    test("1. Create and Open Sporran", () async {
      await wilt.deleteDatabase(initialiser.dbName);
      wilt.db = initialiser.dbName;
      print("7.1");
      initialiser.manualNotificationControl = false;

      sporran7 = await getSporran(initialiser);
      sporran7.autoSync = false;
      initialiser.manualNotificationControl = true;
      
      expect(sporran7.dbName, initialiser.dbName);
      expect(sporran7.lawnIsOpen, isTrue);
      
    });

    test("2. Wilt - Bulk Insert Supplied Keys", () async {
      print("7.2");
      final dynamic document1 = new JsonObjectLite();
      document1.title = "Document 1";
      document1.version = 1;
      document1.attribute = "Doc 1 attribute";
      final String doc1 = WiltUserUtils.addDocumentId(document1, "MyBulkId1");
      final dynamic document2 = new JsonObjectLite();
      document2.title = "Document 2";
      document2.version = 2;
      document2.attribute = "Doc 2 attribute";
      final String doc2 = WiltUserUtils.addDocumentId(document2, "MyBulkId2");
      final dynamic document3 = new JsonObjectLite();
      document3.title = "Document 3";
      document3.version = 3;
      document3.attribute = "Doc 3 attribute";
      final String doc3 = WiltUserUtils.addDocumentId(document3, "MyBulkId3");
      final List docList = new List<String>();
      docList.add(doc1);
      docList.add(doc2);
      docList.add(doc3);
      final String docs = WiltUserUtils.createBulkInsertString(docList);
      
      final dynamic res = await wilt.bulkString(docs);

      final dynamic successResponse = res.jsonCouchResponse;
      expect(successResponse[0].id, equals("MyBulkId1"));
      expect(successResponse[1].id, equals("MyBulkId2"));
      expect(successResponse[2].id, equals("MyBulkId3"));
      docId1Rev = successResponse[0].rev;
    });

    /* Pause a little for the notifications to come through */
    test("3. Notification Pause", () {
      print("7.3");
      final wrapper = expectAsync0(() {
          
      });

      new Timer(new Duration(seconds: 4), wrapper);
    });

    test("4. Create Attachment Online MyBulkId1 Attachment 1", () async {
      print("7.4");
      // sporran7 = await getSporran(initialiser);
      sporran7.online = true;
      final dynamic attachment = new JsonObjectLite();
      attachment.attachmentName = "AttachmentName1";
      attachment.rev = docId1Rev;
      attachment.contentType = 'image/png';
      attachment.payload = attachmentPayload;

      final dynamic res = await sporran7.putAttachment("MyBulkId1", attachment);
      print(res);
      expect(res.ok, isTrue);
      expect(res.operation, Sporran.putAttachmentc);
      expect(res.id, "MyBulkId1");
      expect(res.localResponse, isFalse);
      expect(res.rev, anything);
      docId1Rev = res.rev;
      expect(res.payload.attachmentName, "AttachmentName1");
      expect(res.payload.contentType, 'image/png');
      expect(res.payload.payload, attachmentPayload);
    });

    test("5. Create Attachment Online MyBulkId1 Attachment 2", () {
      print("7.5");
      final wrapper = expectAsync1((res) {
        expect(res.ok, isTrue);
        expect(res.operation, Sporran.putAttachmentc);
        expect(res.id, "MyBulkId1");
        expect(res.localResponse, isFalse);
        expect(res.rev, anything);
        docId1Rev = res.rev;
        expect(res.payload.attachmentName, "AttachmentName2");
        expect(res.payload.contentType, 'image/png');
        expect(res.payload.payload, attachmentPayload);
      });

      sporran7.online = true;
      final dynamic attachment = new JsonObjectLite();
      attachment.attachmentName = "AttachmentName2";
      attachment.rev = docId1Rev;
      attachment.contentType = 'image/png';
      attachment.payload = attachmentPayload;
      sporran7.putAttachment("MyBulkId1", attachment)
        ..then((res) {
          wrapper(res);
        });
    });

    /* Pause a little for the notifications to come through */
    test("6. Notification Pause", () {
      print("7.6");
      final wrapper = expectAsync0(() {});

      new Timer(new Duration(seconds: 3), wrapper);
    });

    test("7. Delete Attachment Online MyBulkId1 Attachment 1", () async {
      print("7.7");
      var res = await wilt.deleteAttachment('MyBulkId1', 'AttachmentName1', docId1Rev);
      if(res.error) {
        logMessage("WILT::Delete Attachment Failed");
        final dynamic errorResponse = res.jsonCouchResponse;
        final String errorText = errorResponse.error;
        logMessage("WILT::Error is $errorText");
        final String reasonText = errorResponse.reason;
        logMessage("WILT::Reason is $reasonText");
        final int statusCode = res.errorCode;
        logMessage("WILT::Status code is $statusCode");
      }
      expect(res.error, isFalse);
      final dynamic successResponse = res.jsonCouchResponse;
      expect(successResponse.ok, isTrue);
      docId1Rev = successResponse.rev;
    });

    test("8. Notification Pause", () {
      print("7.8");
      final wrapper = expectAsync0(() {});

      new Timer(new Duration(seconds: 5), wrapper);
    });

    test("9. Get Attachment Offline MyBulkId1 AttachmentName1", () async {
      print("7.9");
      sporran7.online = false;
      SporranQuery res = await sporran7.getAttachment('MyBulkId1', 'AttachmentName1');
      expect(res.ok, isFalse);
      expect(res.operation, Sporran.getAttachmentc);
      expect(res.localResponse, isTrue);
    });
  }, skip: false);
}
