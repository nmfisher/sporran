/*
 * Package : Sporran
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/02/2014
 * Copyright :  S.Hamblett@OSCF
 * 
 * Sporran is a pouchdb alike for Dart.
 * 
 * This is the main Sporran API class.
 * 
 * Please read the usage and interface documentation supplied for
 * further details.
 * 
 */

import 'dart:async';
import 'dart:convert';
import 'package:sporran/lawndart.dart';
import 'package:sporran/src/EventFactory.dart';
import 'package:sporran/src/SporranException.dart';
import 'package:sporran/src/SporranInitialiser.dart';
import 'package:sporran/src/SporranDatabase.dart';
import 'package:sporran/src/SporranQuery.dart';
import 'package:sporran/src/WiltClientFactory.dart';
import 'package:wilt/wilt.dart';

class Sporran {
  /// Method constants
  static final String putc = "put";
  static final String getc = "get";
  static final String deletec = "delete";
  static final String putAttachmentc = "put_attachment";
  static final String getAttachmentc = "get_attachment";
  static final String deleteAttachmentc = "delete_attachment";
  static final String bulkCreatec = "bulk_create";
  static final String getAllDocsc = "get_all_docs";
  static final String dbInfoc = "db_info";

  /// Construction.
  ///
  Sporran(SporranInitialiser initialiser, Stream<bool> connectivity, WiltClientFactory wiltFactory, EventFactory eventFactory) {
    
    if (initialiser == null) {
      throw new SporranException(SporranException.noInitialiserEx);
    }

    this._dbName = initialiser.dbName;

    /**
     * Construct our database.
     */
    _database = new SporranDatabase(
        _dbName,
        initialiser.hostname,
        initialiser.store,
        wiltFactory,
        eventFactory,
        initialiser.manualNotificationControl,
        initialiser.port,
        initialiser.scheme,
        initialiser.username,
        initialiser.password,
        initialiser.preserveLocal);

    /**
     * Online/offline listeners
     */
    connectivity.listen((x) {
      if(x) {
        _transitionToOnline();
      } else {
        _online = false;
      }
    });
  }

  /// Database
  SporranDatabase _database;

  /// Database name
  String _dbName;
  String get dbName => _dbName;

  /// Lawndart database
  Store get lawndart => _database.lawndart;

  /// Lawndart databse is open
  bool get lawnIsOpen => _database.lawnIsOpen;

  /// Wilt database
  Wilt get wilt => _database.wilt;

  /// On/Offline indicator
  bool _online = true;
  bool get online {
    /* If we are not online or we are and the CouchDb database is not
     * available we are offline
     */
    if ((!_online) || (_database.noCouchDb)) return false;
    return true;
  }

  set online(bool state) {
    _online = state;
    if (state) _transitionToOnline();
  }

  /// Pending delete queue size
  int get pendingDeleteSize => _database.pendingLength();

  /// Ready event
  Stream get onReady => _database.onReady;

  /// Manual notification control
  bool get manualNotificationControl => _database.manualNotificationControl;

  /// Start change notification manually
  void startChangeNotifications() {
    if (manualNotificationControl) {
      if (_database.wilt.changeNotificationsPaused) {
        _database.wilt.restartChangeNotifications();
      } else {
        _database.startChangeNotifications();
      }
    }
  }

  /// Stop change notification manually
  void stopChangeNotifications() {
    if (manualNotificationControl) _database.wilt.pauseChangeNotifications();
  }

  /// Manual control of sync().
  ///
  /// Usually Sporran syncs when a transition to online is detected,
  /// however this can be disabled, use in conjunction with manual
  /// change notification control. If this is set to false you must
  /// call sync() explicitly.
  bool _autoSync = true;
  bool get autoSync => _autoSync;
  set autoSync(bool state) => _autoSync = state;

  /// Online transition
  void _transitionToOnline() {
    _online = true;

    /**
     * If we have never connected to CouchDb try now,
     * otherwise we can sync straight away
     */
    if (_database.noCouchDb) {
      _database.connectToCouch(true);
    } else {
      if (_autoSync) sync();
    }
  }

  /// Update document.
  ///
  /// If the document does not exist a create is performed.
  ///
  /// For an update operation a specific revision must be specified.
  Future<SporranQuery> put(String id, Map document, [String rev = null]) async {
    if (id == null) {
      throw new SporranException(SporranException.putNoDocIdEx);
    }

    final SporranQuery res = new SporranQuery();
    res.operation = putc;
    res.id = id;
    res.payload = document;

    /* Update LawnDart */
    await _database.updateLocalStorageObject(id, document, rev, SporranDatabase.notUpdatedc);

    /* If we are offline just return */
    if (!online) {
      res.localResponse = true;
      res.ok = true;
      res.rev = rev;
      return res;
    }
    if(rev != null) {
      document["_rev"] = rev;
    }
    final dynamic wiltResponse = await _database.wilt.putDocument(id, document);
    res.localResponse = false;
    
    if(!wiltResponse.error) {
      res.rev = wiltResponse.jsonCouchResponse["rev"];
      await _database.updateLocalStorageObject(id, document, rev, SporranDatabase.updatedc);
      await _database.updateAttachmentRevisions(id, rev);
      res.ok = true;
    } else {
      res.ok = false;
      res.errorCode = wiltResponse.errorCode;
      res.errorText = wiltResponse.jsonCouchResponse["error"];
      res.errorReason = wiltResponse.jsonCouchResponse["reason"];
    }
    return res;
  }

  /// Get a document
  Future<SporranQuery> get(String id, [String rev = null]) async {
    if (id == null) {
      throw new SporranException(SporranException.getNoDocIdEx);    
    }

    final SporranQuery res = new SporranQuery();
    res.operation = getc;
    res.id = id;

    /* Check for offline, if so try the get from local storage */
    if (!online) {
      final dynamic document = await _database.getLocalStorageObject(id);
      res.localResponse = true;
      res.ok = !document.isEmpty;
      if(res.ok) {
        res.payload = document["payload"];
        res.rev = document["_rev"];;
      }
      return res;
    }
    
    /* Get the document from CouchDb with its attachments */
    final dynamic wiltResponse = await _database.wilt.getDocument(id, rev, true);
    
    res.localResponse = false;
    res.ok = !wiltResponse.error;
    res.payload = res.ok ? wiltResponse.jsonCouchResponse : null;
    res.rev = res.ok ? wiltResponse.jsonCouchResponse["_rev"] : null;

    /* If Ok update local storage with the document */
    if (res.ok) {
      await _database.updateLocalStorageObject(
          id, wiltResponse.jsonCouchResponse, res.rev, SporranDatabase.updatedc);
      /**
       * Get the documents attachments and create them locally
       */
      await _database.createDocumentAttachments(id, res.payload);
    } else {
      res.errorCode = wiltResponse.errorCode;
      res.errorText = wiltResponse.jsonCouchResponse["error"];
      res.errorReason = wiltResponse.jsonCouchResponse["reason"];
    }
    return res;
  }

  /// Delete a document.
  ///
  /// Revision must be supplied if we are online
  Future<SporranQuery> delete(String id, [String rev = null]) async {
    final Completer opCompleter = new Completer();

    if (id == null) {
      return throw new SporranException(SporranException.deleteNoDocIdEx);
    }

    /* Remove from Lawndart */
    final String document = await _database.lawndart.getByKey(id);

    final dynamic res = new SporranQuery();
    res.operation = deletec;
    res.id = id;    

   /* Doesnt exist, return error */
    if (document == null) {
      res.localResponse = true;
      res.payload = null;
      res.rev = null;
      res.ok = false;
      return res;
    }

    await _database.lawndart.removeByKey(id);
    
    /* Check for offline, if so add to the pending delete queue and return */
    if (!online) {
      _database.addPendingDelete(id, document);
      res.localResponse = true;
      res.ok = true;
      return res;
    }

    /* Online, delete from CouchDb */
    final dynamic wiltResponse = await _database.wilt.deleteDocument(id, rev);
    res.operation = deletec;
    res.localResponse = false;
    res.payload = wiltResponse.jsonCouchResponse;
    res.id = id;
    res.ok = !wiltResponse.error;
    res.rev = wiltResponse.error ? null : wiltResponse.jsonCouchResponse["rev"];
    _database.removePendingDelete(id);
    if(!res.ok) {
      res.errorCode = wiltResponse.errorCode;
      res.errorText = wiltResponse.jsonCouchResponse["error"];
      res.errorReason = wiltResponse.jsonCouchResponse["reason"];
    }
    return res;
  }

  /// Put attachment
  ///
  /// If the revision is supplied the attachment to the document will be updated,
  /// otherwise the attachment will be created, along with the document if needed.
  ///
  /// The JsonObjectLite attachment parameter must contain the following :-
  ///
  /// String attachmentName
  /// String rev - maybe '', see above
  /// String contentType - mime type in the form 'image/png'
  /// String payload - stringified binary blob
  Future<SporranQuery> putAttachment(String id, dynamic attachment) async {
    if (id == null) {
      throw new SporranException(SporranException.putAttNoDocIdEx);
    }

    if (attachment == null) {
      throw new SporranException(SporranException.putAttNoAttEx);
    }

    /* Update LawnDart */
    final String key = "$id-${attachment.attachmentName}-${SporranDatabase.attachmentMarkerc}";

    final SporranQuery res = new SporranQuery();
    res.operation = putAttachmentc;
    res.id = id;

    await _database.updateLocalStorageObject(
        key, attachment, attachment.rev, SporranDatabase.notUpdatedc);
    /* If we are offline just return */
    if (!online) {
      res.localResponse = true;
      res.ok = true;
      res.payload = attachment;
      return res;
    }

    /* Otherwise, create locally, then boomerang to Wilt */
    final Function attachmentHandler = attachment.rev == '' ? _database.wilt.createAttachment : _database.wilt.updateAttachment;

    final dynamic wiltResponse = await attachmentHandler(id, attachment.attachmentName,
              attachment.rev, attachment.contentType, attachment.payload);

    res.ok = !(wiltResponse.error);
    res.localResponse = false;

    /* If success, mark the update as UPDATED in local storage */
    if (res.ok) {
      final dynamic newAttachment = jsonDecode(_mapToJson(attachment));
      newAttachment["contentType"] = attachment.contentType;
      newAttachment["payload"] = attachment.payload;
      newAttachment["attachmentName"] = attachment.attachmentName;
      res.payload = newAttachment;
      res.rev = wiltResponse.jsonCouchResponse["rev"];
      newAttachment["rev"] = wiltResponse.jsonCouchResponse["rev"];
      await _database.updateLocalStorageObject(key, newAttachment,
          wiltResponse.jsonCouchResponse["rev"], SporranDatabase.updatedc);
      await _database.updateAttachmentRevisions(id, wiltResponse.jsonCouchResponse["rev"]);
    } else {
      res.errorCode = wiltResponse.errorCode;
      res.errorText = wiltResponse.jsonCouchResponse["error"];
      res.errorReason = wiltResponse.jsonCouchResponse["reason"];
    }

    return res;
  }

  /// Delete an attachment.
  /// Revision can be null if offline
  Future deleteAttachment(String id, String attachmentName, String rev) async {
    final String key =
        "$id-$attachmentName-${SporranDatabase.attachmentMarkerc}";

    if (id == null) {
      throw new SporranException(SporranException.deleteAttNoDocIdEx);
    }

    if (attachmentName == null) {
      throw new SporranException(SporranException.deleteAttNoAttNameEx);
    }

    if ((online) && (rev == null)) {
      throw new SporranException(SporranException.deleteAttNoRevEx);
    }

    final dynamic res = new SporranQuery();
    res.operation = deleteAttachmentc;
    res.id = id;

    /* Remove from Lawndart */
    final dynamic document = await _database.lawndart.getByKey(key);
    if(document == null) {
      /* Doesnt exist, return error */
      res.localResponse = true;
      res.ok = false;
      return res;
    }

    await _database.lawndart.removeByKey(key);
    /* Check for offline, if so add to the pending delete queue and return */
    if (!online) {
      _database.addPendingDelete(key, document);
      res.localResponse = true;
      res.ok = true;
      return res;
    }

    /* Online, delete from CouchDb */
    final dynamic wiltResponse = await _database.wilt.deleteAttachment(id, attachmentName, rev);
    res.localResponse = false;
    res.payload = wiltResponse.jsonCouchResponse;
    res.ok = !wiltResponse.error;
    res.rev = wiltResponse.error ? null : wiltResponse.jsonCouchResponse["rev"];
    if(res.ok) {
      _database.removePendingDelete(key);
    } else {
      res.errorCode = wiltResponse.errorCode;
      res.errorText = wiltResponse.jsonCouchResponse["error"];
      res.errorReason = wiltResponse.jsonCouchResponse["reason"];
    }
    
    return res;
  }

  /// Get an attachment
  Future<SporranQuery> getAttachment(String id, String attachmentName) async {
    final String key =
        "$id-$attachmentName-${SporranDatabase.attachmentMarkerc}";

    if (id == null) {
      throw new SporranException(SporranException.getAttNoDocIdEx);
    }

    if (attachmentName == null) {
      throw new SporranException(SporranException.getAttNoAttNameEx);
    }

    final SporranQuery res = new SporranQuery();
    res.id = id;
    res.operation = getAttachmentc;

    /* Check for offline, if so try the get from local storage */
    if (!online) {
      final dynamic document = await _database.getLocalStorageObject(key);
      res.localResponse = true;
      res.ok = document.isEmpty ? false : true;
      res.payload = res.ok ? document : null;
      return res;
    }

    /* Get the attachment from CouchDb */
    final dynamic wiltResponse = await _database.wilt.getAttachment(id, attachmentName);
    /* If Ok update local storage with the attachment */
    res.localResponse = false;
    res.ok = !wiltResponse.error;
    if (!res.ok) {
      res.errorCode = wiltResponse.errorCode;
      res.errorText = wiltResponse.jsonCouchResponse["error"];
      res.errorReason = wiltResponse.jsonCouchResponse["reason"];
    } else {
      final dynamic attachment = {
        "attachmentName":attachmentName,
        "contentType":wiltResponse.jsonCouchResponse["contentType"],
        "payload":wiltResponse.responseText,
        "rev":res.rev,
      };
      
      res.payload = attachment;

      _database.updateLocalStorageObject(
              key, attachment, res.rev, SporranDatabase.updatedc);
    }
    return res;
  }

  /// Bulk document create.
  ///
  /// docList is a map of documents with their keys
  Future<SporranQuery> bulkCreate(Map<String, dynamic> docList) async {

    if (docList == null) {
      throw new SporranException(SporranException.bulkCreateNoDocListEx);
    }

    final SporranQuery res = new SporranQuery();
    res.operation = bulkCreatec;

    /* Update LawnDart */
    docList.forEach((key, document) async {
      await _database.updateLocalStorageObject(key, document, null, SporranDatabase.notUpdatedc);
    });

    /* If we are offline just return */
    if (!online) {
      res.localResponse = true;
      res.ok = true;
      res.payload = docList;
      return res;
    }

    /* Prepare the documents */
    final List documentList = docList.map((key, document) {
      return MapEntry(key, WiltUserUtils.addDocumentId(document, key));
    }).values.toList();

    final String docs = WiltUserUtils.createBulkInsertString(documentList);
    
    /* Complete locally, then boomerang to the client */
    final dynamic wiltResponse = await _database.wilt.bulkString(docs);
    
    /* If success, mark the update as UPDATED in local storage */
    res.ok = !wiltResponse.error;
    res.localResponse = false;
    res.payload = docList;
    if (!res.ok) {
      res.errorCode = wiltResponse.errorCode;
      res.errorText = wiltResponse.jsonCouchResponse["error"];
      res.errorReason = wiltResponse.jsonCouchResponse["reason"];
    } else {
      /* Get the revisions for the updates */
      final List revisions = new List<dynamic>();
      final Map revisionsMap = new Map<String, String>();

      wiltResponse.jsonCouchResponse.toList().forEach((resp) {
        try {
          revisions.add(resp);
          revisionsMap[resp.id] = resp.rev;
        } catch (e) {
          print(e);
          // revisions.add(null);
        }
      });
      res.rev = revisions;

      /* Update the documents */
      docList.forEach((key, document) async {
        await _database.updateLocalStorageObject(
            key, document, revisionsMap[key], SporranDatabase.updatedc);
      });
    }
    return res;
  }

  Future<SporranAllDocsQuery> _getAllDocsOffline({List<String> keys: null}) async {
    List<String> keyList = keys;
    if (keys == null) {
      /* Get all the keys from Lawndart */
      keyList = await _database.lawndart.keys().toList();

      /* Only return documents */
      keyList = keyList.where((key) {
        final List<String> split = key.split('-');
        return (split.length != 3 || split[2] != SporranDatabase.attachmentMarkerc);
      }).toList();
    }

    final dynamic documents = await _database.getLocalStorageObjects(keyList);
    final SporranAllDocsQuery res = new SporranAllDocsQuery();
    res.localResponse = true;
    res.operation = getAllDocsc;
    res.ok = true;
    res.payload = documents;
    res.totalRows = documents.length;
    res.keyList = documents.keys.toList().cast<String>();
    return res;
  }
  /// Get all documents.
  ///
  /// The parameters should be self explanatory and are addative.
  ///
  /// In offline mode only the keys parameter is respected.
  /// The includeDocs parameter is also forced to true.
  Future<SporranAllDocsQuery> getAllDocs(
      {bool includeDocs: false,
      int limit: null,
      String startKey: null,
      String endKey: null,
      List<String> keys: null,
      bool descending: false}) async {
    
    SporranAllDocsQuery res;
    /* Check for offline, if so try the get from local storage */
    if (!online) {
      res = await _getAllDocsOffline(keys: keys);
    } else {
      /* Get the document from CouchDb */
      final dynamic wiltResponse = await _database.wilt.getAllDocs(
          includeDocs: includeDocs,
          limit: limit,
          startKey: startKey,
          endKey: endKey,
          keys: keys,
          descending: descending);
      res = new SporranAllDocsQuery();
      res.operation = getAllDocsc;
      res.localResponse = false;
      res.ok = !wiltResponse.error;
      if(!res.ok) {
        res.errorCode = wiltResponse.errorCode;
        res.errorText = wiltResponse.jsonCouchResponse["error"];
        res.errorReason = wiltResponse.jsonCouchResponse["reason"];
      } else {
        res.payload = wiltResponse.jsonCouchResponse;
      }
    }
    return res;
  }

  /// Get information about the database.
  ///
  /// When offline the a list of the keys in the Lawndart database are returned,
  /// otherwise a response for CouchDb is returned.
  Future<SporranQuery> getDatabaseInfo() async {

    final SporranQuery res = new SporranQuery();
    res.operation = dbInfoc;

    if (!online) {
      final List<String> keys = await _database.lawndart.keys().toList();
      res.localResponse = true;
      res.payload = keys;
      res.ok = true;
    } else {
      /* Get the database information from CouchDb */
      final dynamic wiltResponse = await _database.wilt.getDatabaseInfo();
      res.localResponse = false;
      res.ok = !wiltResponse.error; 
      if(!res.ok) {
        res.errorCode = wiltResponse.errorCode;
        res.errorText = wiltResponse.jsonCouchResponse["error"];
        res.errorReason = wiltResponse.jsonCouchResponse["reason"];
      } else {
        res.payload = wiltResponse.jsonCouchResponse;
      }
    }

    return res;
  }

  /// Synchronise local storage and CouchDb when we come online or on demand.
  ///
  /// Note we don't check for failures in this, there is nothing we can really do
  /// if we say get a conflict error or a not exists error on an update or delete.
  ///
  /// For updates, if applied successfully we wait for the change notification to
  /// arrive to mark the update as UPDATED. Note if these are switched off sync may be
  /// lost with Couch.
  void sync() {
    /* Only if we are online */
    if (!online) {
      print("Not online, skipping sync");
      return;
    }
    _database.sync();
  }

  /// Login
  ///
  /// Allows log in credentials to be changed if needed.
  void login(String user, String password) {
    if (user == null || password == null) {
      throw new SporranException(SporranException.invalidLoginCredsEx);
    }

    _database.login(user, password);
  }

  /// Serialize a map to a JSON string
  static String _mapToJson(dynamic map) {
    if (map is String) {
      try {
        final res = json.decode(map);
        if (res != null) {
          return map;
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
    }
    return json.encode(map);
  }
}
