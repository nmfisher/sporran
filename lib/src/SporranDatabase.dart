/*
 * Package : Sporran
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/02/2014
 * Copyright :  S.Hamblett@OSCF
 * 
 * Sporran is a pouchdb alike for Dart.
 * 
 * This is the main Sporran Database class.
 * 
 * A Sporran database comprises of a WiltBrowserClient object, and a a Lawndart 
 * object and in tandem, sharing the same database name.
 * 
 * Please read the usage and interface documentation supplied for
 * further details.
 * 
 */
import 'dart:async';
import 'dart:convert';

import 'package:sporran/lawndart.dart';
import 'package:sporran/src/Event.dart';
import 'package:sporran/src/EventFactory.dart';
import 'package:sporran/src/SporranException.dart';
import 'package:sporran/src/WiltClientFactory.dart';
import 'package:wilt/wilt.dart';

class SporranDatabase {
  /// Constants
  static final String notUpdatedc = "not_updated";
  static final String updatedc = "updated";
  static final String attachmentMarkerc = "sporranAttachment";

  /// Construction, for Wilt we need URL and authentication parameters.
  /// For LawnDart only the database name, the store name is fixed by Sporran
  SporranDatabase(this._dbName, this._host, this._lawndart, this._getWiltClient,
      this._eventFactory,
      [this._manualNotificationControl = false,
      this._port = "5984",
      this._scheme = "http://",
      this._user = null,
      this._password = null,
      this._preserveLocalDatabase = false,
      this.localOnly = true]) {
    _initialise();
  }

  void _initialise() {
    if (_lawndart == null)
      throw new SporranException(SporranException.noStoreEx);

    _lawnIsOpen = true;
    // Delete the local database unless told to preserve it.
    if (!_preserveLocalDatabase) _lawndart.nuke();
    // Instantiate a Wilt object
    _wilt = _getWiltClient(_host, _port, _scheme);
    // Login
    if (_user != null) {
      _wilt.login(_user, _password);
    }

    // Open CouchDb
    if(localOnly) {
      _noCouchDb = true;
      _signalReady();
    } else {
      connectToCouch();
    }
  }

  bool localOnly;

  /// Host name
  String _host = null;
  String get host => _host;

  /// Port number
  String _port = null;
  String get port => _port;

  /// HTTP scheme
  String _scheme = null;
  String get scheme => _scheme;

  /// Authentication, user name
  String _user = null;

  /// Authentication, user password
  String _password = null;

  /// Manual notification control
  bool _manualNotificationControl = false;
  bool get manualNotificationControl => _manualNotificationControl;

  /// Local database preservation
  bool _preserveLocalDatabase = false;

  /// The Wilt database
  Wilt _wilt;
  WiltClientFactory _getWiltClient;
  Wilt get wilt => _wilt;

  /// Factory to create events (primarily used for dart:html)
  EventFactory _eventFactory;

  /// The Lawndart database
  Store _lawndart;
  Store get lawndart => _lawndart;

  /// Lawn is open indicator
  bool _lawnIsOpen = false;

  bool get lawnIsOpen => _lawnIsOpen;

  /// Database name
  String _dbName;
  String get dbName => _dbName;

  /// CouchDb database is intact
  bool _noCouchDb = true;
  bool get noCouchDb => _noCouchDb;

  /// Pending delete queue
  Map _pendingDeletes = new Map<String, dynamic>();
  Map get pendingDeletes => _pendingDeletes;

  /// Event stream for Ready events
  final _onReady = new StreamController<Event>.broadcast();
  Stream get onReady => _onReady.stream;

  /// Start change notifications
  void startChangeNotifications() {
    final WiltChangeNotificationParameters parameters =
        new WiltChangeNotificationParameters();
    parameters.includeDocs = true;
    _wilt.startChangeNotification(parameters);

    /* Listen for and process changes */
    _wilt.changeNotification.listen((e) {
      _processChange(e);
    });
  }

  /// Change notification processor
  void _processChange(WiltChangeNotificationEvent e) {
    print("Processing change notification [ $e] ");
    /* Ignore error events */
    if (!(e.type == WiltChangeNotificationEvent.updatee ||
        e.type == WiltChangeNotificationEvent.deletee)) return;

    /* Process the update or delete event */
    if (e.type == WiltChangeNotificationEvent.updatee) {

      updateLocalStorageObject(e.docId, e.document, e.docRevision, updatedc);

      /* Now update the attachments */

      /* Get a list of attachments from the document */
      final List attachments = WiltUserUtils.getAttachments(e.document);
      final List attachmentsToDelete = new List<String>();

      /* For all the keys... */
      _lawndart.keys().listen((String key) {
        /* If an attachment... */
        final List keyList = key.split('-');
        if ((keyList.length == 3) && (keyList[2] == attachmentMarkerc)) {
          /* ...for this document... */
          if (e.docId == keyList[0]) {
            /* ..potentially now deleted... */
            attachmentsToDelete.add(key);
            /* ...check against all the documents current attachments */
            attachments.forEach((attachment) {
              if ((keyList[1] == attachment["name"]) &&
                  (keyList[0] == e.docId) &&
                  (keyList[2] == attachmentMarkerc)) {
                /* If still valid remove it from the delete list */
                attachmentsToDelete.remove(key);
              }
            });
          }
        }
      }, onDone: () {
        /* We now have a list of attachments for this document that
        * are not present in the document itself so remove them.
        */
        attachmentsToDelete.forEach((key) async {
          await _lawndart.removeByKey(key);
          removePendingDelete(key);
        });
      });

      /* Now update already existing ones and add any new ones */
      updateDocumentAttachments(e.docId, e.document);
    } else {
      /* Tidy up any pending deletes */
      removePendingDelete(e.docId);
      /* Do the delete */
      _lawndart.removeByKey(e.docId)
        ..then((_) {
          /* Remove all document attachments */
          _lawndart.keys().listen((String key) {
            final List keyList = key.split('-');
            if ((keyList.length == 3) && (keyList[2] == attachmentMarkerc)) {
              _lawndart.removeByKey(key);
            }
          });
        });
    }
  }

  /// Signal we are ready
  void _signalReady() {
    final Event e = _eventFactory('Event', 'SporranReady');
    _onReady.add(e);
  }

  /// Create and/or connect to CouchDb
  void connectToCouch([bool transitionToOnline = false]) async {
    try {
      final dynamic res = await _wilt.getAllDbs();
      
      if(res.error)
        throw Exception(res.responseText);

      final dynamic successResponse = res.jsonCouchResponse;
      final bool exists = successResponse.contains(_dbName);
      /// If the CouchDb database does not exist create it.
      if (exists == false) {
        final dynamic created = await _wilt.createDatabase(_dbName);
        if (created.error) {
          throw Exception();
        }
      }

      _wilt.db = _dbName;
      _noCouchDb = false;

      /**
       * Start change notifications
       */
      if (!manualNotificationControl) startChangeNotifications();

      /**
       * If this is a transition to online start syncing
       */
      if (transitionToOnline) sync();

      /**
       * Signal we are ready
       */
      _signalReady();
    } catch(err) {
      print("Connection error : $err");
      _noCouchDb = true;
      _signalReady();
    } 
  }

  /// Add a key to the pending delete queue
  void addPendingDelete(String key, String document) {
    final dynamic deletedDocument =
        jsonDecode(document);
    _pendingDeletes[key] = deletedDocument;
  }

  /// Remove a key from the pending delete queue
  void removePendingDelete(String key) {
    if (_pendingDeletes.containsKey(key)) _pendingDeletes.remove(key);
  }

  /*
   * Length of the pending delete queue
   */
  int pendingLength() {
    return _pendingDeletes.length;
  }

  /// Update document attachments
  void updateDocumentAttachments(String id, dynamic document) {
    /* Get a list of attachments from the document */
    final List attachments = WiltUserUtils.getAttachments(document);

    /* Exit if none */
    if (attachments.length == 0) return;

    /* Create our own Wilt instance */
    final Wilt wilting = _getWiltClient(_host, _port, _scheme);

    /* Login if we are using authentication */
    if (_user != null) {
      wilting.login(_user, _password);
    }

    /* Get and update all the attachments */
    attachments.forEach((attachment) async {
      /* Get the attachment */
      wilting.db = _dbName;
      final dynamic res = await wilting.getAttachment(id, attachment["name"]);
      if (!res.error) {
        final dynamic successResponse = res.jsonCouchResponse;
        final dynamic newAttachment = {
          "attachmentName":attachment["name"],
          "rev":document.containsKey("_rev") ? document["_rev"] : document["rev"],
          "contentType":successResponse["contentType"],
          "payload":res.responseText,
        };
        
        final String key =
            "$id-${attachment['name']}-${SporranDatabase.attachmentMarkerc}";
        updateLocalStorageObject(
            key, newAttachment, newAttachment["rev"], SporranDatabase.updatedc);
      }
    });
  }

  /// Update local storage.
  ///
  Future updateLocalStorageObject(
      String key, dynamic update, String revision, String updateStatus) async {
     
     /* Check for not initialized */
    if ((lawndart == null) || (!_lawnIsOpen)) {
      throw new SporranException(SporranException.lawnNotInitEx);
    }

    final dynamic document = {
      "key":key,
      "rev":revision,
      "status":updateStatus,
      "payload":update
    };
    
    await _lawndart.save(jsonEncode(document), key);
  }

  /// Get an object from local storage
  Future<dynamic> getLocalStorageObject(String key) async {
    final String document = await lawndart.getByKey(key);
    if(document == null)
      return Map();
    return jsonDecode(document);
  }

  /// Get multiple objects from local storage
  Future<Map> getLocalStorageObjects(List<String> keys) async {
    var values = await lawndart.getByKeys(keys).map((x) => jsonDecode(x)).toList();
    return Map.fromIterables(keys, values);
  }

  /// Delete a CouchDb document.
  ///
  /// If this fails we probably have a conflict in which case
  /// Couch wins.
  void delete(String key, String revision) {
    /* Create our own Wilt instance */
    final Wilt wilting = _getWiltClient(_host, _port, _scheme);

    /* Login if we are using authentication */
    if (_user != null) {
      wilting.login(_user, _password);
    }

    wilting.db = _dbName;
    wilting.deleteDocument(key, revision);
  }

  /// Delete a CouchDb attachment.
  ///
  /// If this fails we probably have a conflict in which case
  /// Couch wins.
  void deleteAttachment(String key, String name, String revision) async {
    /* Create our own Wilt instance */
    final Wilt wilting = _getWiltClient(_host, _port, _scheme);

    /* Login if we are using authentication */
    if (_user != null) {
      wilting.login(_user, _password);
    }

    wilting.db = _dbName;
    await wilting.deleteAttachment(key, name, revision);
  }

  /// Update/create a CouchDb attachment
  void updateAttachment(String key, String name, String revision,
      String contentType, String payload) async {
    /* Create our own Wilt instance */
    final Wilt wilting = _getWiltClient(_host, _port, _scheme);

    /* Login if we are using authentication */
    if (_user != null) {
      wilting.login(_user, _password);
    }

    wilting.db = _dbName;

    print("Updating attachment with key [ $key ], rev [ $revision ]");
    
    final dynamic res = await wilting.updateAttachment(key, name, revision, contentType, payload);
    /**
     * If we have a conflict, get the document to get its
     * latest revision
     */
    if (res.error) {
      if (res.errorCode == 409) {
        final dynamic document = await wilting.getDocument(key);
          /**
           * If the document doesn't already have an attachment
           * with this name get the revision and add this one.
           * We don't care about the outcome, if it errors there's
           * nothing we can do.
           */
          if (!document.error) {
            final dynamic successResponse = document.jsonCouchResponse;
            final List attachments = WiltUserUtils.getAttachments(successResponse);
            bool found = false;
            attachments.forEach((dynamic attachment) {
              if (attachment["name"] == name) found = true;
            });

            if (!found) {
              wilting.updateAttachment(
                  key, name, successResponse["_rev"], contentType, payload);
            }
          }
        }
      }
  }

  /// Update/create a CouchDb document
  Future<String> update(String key, Map document, String revision) {
    final Completer<String> completer = new Completer<String>();

    /* Create our own Wilt instance */
    final Wilt wilting = _getWiltClient(_host, _port, _scheme);

    /* Login if we are using authentication */
    if (_user != null) {
      wilting.login(_user, _password);
    }

    void localCompleter(dynamic res) {
      if (!res.error) {
        completer.complete(res.jsonCouchResponse["rev"]);
      }
    }

    if(revision != null) {
      document["_rev"] = revision;
    }

    print("Putting document : [ $document ]");

    wilting.db = _dbName;
    wilting.putDocument(key, document)
      ..then((res) {
        localCompleter(res);
      });

    return completer.future;
  }

  /// Manual bulk insert uses update
  Future<Map<String, String>> _manualBulkInsert(
      Map<String, dynamic> documentsToUpdate) {
    final Completer<Map<String, String>> completer =
        new Completer<Map<String, String>>();
    final Map<String, String> revisions = new Map<String, String>();

    final int length = documentsToUpdate.length;
    int count = 0;
    documentsToUpdate.forEach((String key, dynamic document) {
      update(key, document["payload"], document.containsKey("rev") ? document["rev"] : document["_rev"])
        ..then((String rev) {
          revisions[document["key"]] = rev;
          count++;
          if (count == length) completer.complete(revisions);
        });
    });

    return completer.future;
  }

  /// Bulk insert documents using bulk insert
  Future<dynamic> bulkInsert(Map<String, dynamic> docList) {
    final Completer<dynamic> completer = new Completer<dynamic>();

    /* Create our own Wilt instance */
    final Wilt wilting = _getWiltClient(_host, _port, _scheme);

    /* Login if we are using authentication */
    if (_user != null) {
      wilting.login(_user, _password);
    }

    /* Prepare the documents */
    final List documentList = new List<String>();
    docList.forEach((key, document) {
      String docString = WiltUserUtils.addDocumentId(document.payload, key);
      if (document.rev != null) {
        final dynamic temp = jsonDecode(docString);
        docString = WiltUserUtils.addDocumentRev(temp, document.rev);
      }

      documentList.add(docString);
    });

    final String docs = WiltUserUtils.createBulkInsertString(documentList);

    /* Do the bulk create*/
    wilting.db = _dbName;
    wilting.bulkString(docs)
      ..then((res) {
        completer.complete(res);
      });

    return completer.future;
  }

  /// Update the revision of any attachments for a document
  /// if the document is updated from Couch
  void updateAttachmentRevisions(String id, String revision) {
    lawndart.all().listen((String document) {
      final String key = document;
      final List keyList = key.split('-');
      if ((keyList.length == 3) && (keyList[2] == attachmentMarkerc)) {
        if (id == keyList[0]) {
          final dynamic attachment = jsonDecode(document);
          updateLocalStorageObject(id, attachment, revision, updatedc);
        }
      }
    });
  }

  /// Synchronise local storage with CouchDb
  void sync() {
    print("Starting sync.");

    /*
     * Pending deletes first
     */
    pendingDeletes.forEach((key, dynamic document) {
      /**
       * If there is no revision the document hasn't been updated
       * from Couch, we have to ignore this here.
       */
      final String revision = document["rev"];
      if (revision != null) {
        /* Check for an attachment */
        final List keyList = key.split('-');
        if ((keyList.length == 3) &&
            (keyList[2] == SporranDatabase.attachmentMarkerc)) {
          deleteAttachment(keyList[0], keyList[1], revision);
          /* Just in case */
          lawndart.removeByKey(key);
        } else {
          delete(key, revision);
        }
      }
    });

    pendingDeletes.clear();

    final Map documentsToUpdate = new Map<String, dynamic>();
    final Map attachmentsToUpdate = new Map<String, dynamic>();

    /**
    * Get a list of non updated documents and attachments from Lawndart
    */
    lawndart.all().listen((String document) {
      final dynamic doc = jsonDecode(document);
      final String key = doc['key'];
      if (doc['status'] == notUpdatedc) {
        /* If an attachment just stack it */
        final List keyList = key.split('-');
        if ((keyList.length == 3) && (keyList[2] == attachmentMarkerc)) {
          attachmentsToUpdate[key] = doc;
        } else {
          documentsToUpdate[key] = doc;
        }
      }
    }, onDone: () {
      _manualBulkInsert(documentsToUpdate)
        ..then((revisions) {
          print("Handling updated revisions : $revisions");
          /* Finally do the attachments */
          attachmentsToUpdate.forEach((key, dynamic attachment) {
            final List keyList = key.split('-');
            print("Revision: ${revisions[keyList[0]]}");
            attachment["rev"] = revisions[keyList[0]];
            print("Inserting attachment $attachment");
            updateAttachment(
                keyList[0],
                attachment["payload"]["attachmentName"],
                attachment["rev"],
                attachment["payload"]["contentType"],
                attachment["payload"]["payload"]);
          });
        });
    });
  }

  /// Create document attachments
  void createDocumentAttachments(String key, dynamic document) {
    /* Get the attachments and create them locally */
    final List attachments = WiltUserUtils.getAttachments(document);

    attachments.forEach((dynamic attachment) {
      final dynamic attachmentToCreate = {
        "attachmentName":attachment["name"],
        "rev":document["_rev"],
        "contentType":attachment["data"]["content_type"]
      };
      final String attachmentKey =
          "$key-${attachment['name']}-${attachmentMarkerc}";
      // TODO - do we need to handle non-UTF8 strings?
      attachmentToCreate["payload"] =
          base64Encode(utf8.encode(attachment["data"]["data"]));

      updateLocalStorageObject(
          attachmentKey, attachmentToCreate, attachmentToCreate["rev"], updatedc);
    });
  }

  /// Login
  void login(String user, String password) {
    this._user = user;
    this._password = password;

    _wilt.login(_user, _password);
  }
}
