/*
 * Package : Sporran
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/02/2014
 * Copyright :  S.Hamblett@OSCF
 */

import 'dart:html';
import 'package:sporran/lawndart.dart';
import 'package:sporran/sporran.dart';
import 'package:sporran/src/SporranInitialiser.dart';
import 'package:sporran/src/wilt/WiltBrowserClient2.dart';
import 'package:test/test.dart';
import 'package:wilt/wilt.dart';
import 'package:sporran/src/tests/sporran_scenario1_test.dart';
import 'package:sporran/src/tests/sporran_scenario2_test.dart';
import 'package:sporran/src/tests/sporran_scenario3_test.dart';
import 'package:sporran/src/tests/sporran_test.dart';
import 'sporran_test_config.dart';

void main() async { 

  /* Create a Wilt instance for when we want to interface with CouchDb directly 
  * (e.g. dropping the database or updating directly to test that change notifications are correctly picked up).
  */

  final Wilt wilt = new WiltBrowserClient2(hostName, port, scheme);

  /* Login if we are using authentication */
  if (userName != null) {
    wilt.login(userName, userPassword);
  }

   /* Common initialiser */
  final SporranInitialiser initialiser = new SporranInitialiser();
  initialiser.store = await MemoryStore.open();
  initialiser.dbName = databaseName;
  initialiser.hostname = hostName;
  initialiser.manualNotificationControl = true;
  initialiser.port = port;
  initialiser.scheme = scheme;
  initialiser.username = userName;
  initialiser.password = userPassword;
  initialiser.preserveLocal = false;
  
  /* Group 1 - Environment tests */
  group("1. Environment Tests - ", () {
    print("1.1");
    String status = "online";

    test("Online/Offline", () {
      window.onOffline.first.then((e) {
        expect(status, "offline");
        /* Because we aren't really offline */
        expect(window.navigator.onLine, isTrue);
      });

      window.onOnline.first.then((e) {
        expect(status, "online");
        expect(window.navigator.onLine, isTrue);
      });

      status = "offline";
      var e = new Event.eventType('Event', 'offline');
      window.dispatchEvent(e);
      status = "online";
      e = new Event.eventType('Event', 'online');
      window.dispatchEvent(e);
    });

    test("1. Construction Online/Offline listener ", () async {
      print("2.1");
      var sporran21 = await getSporran(initialiser);
      final Event offline = new Event.eventType('Event', 'offline');
      window.dispatchEvent(offline);
      expect(sporran21.online, isFalse);
      final Event online = new Event.eventType('Event', 'online');
      window.dispatchEvent(online);
      expect(sporran21.online, isTrue);
      sporran21 = null;
    });

  }, skip: false);

  // run(wilt, initialiser, getSporran);
  runScenario1(wilt, initialiser, getSporran);
  runScenario2(wilt, initialiser, getSporran);
  runScenario3(wilt, initialiser, getSporran);
}