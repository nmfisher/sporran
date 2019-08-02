/*
 * Package : Sporran
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/02/2014
 * Copyright :  S.Hamblett@OSCF
 */

import 'package:sporran/lawndart.dart';
import 'package:sporran/src/SporranInitialiser.dart';
import 'package:sporran/src/wilt/WiltServerClient2.dart';
import 'package:sporran/sporran_io.dart';
import 'package:wilt/wilt.dart';
import 'sporran_scenario1_test.dart';
import 'sporran_scenario2_test.dart';
import 'sporran_scenario3_test.dart';
import 'sporran_test.dart';
import 'sporran_test_config.dart';

void main() async { 

  /* Create a Wilt instance for when we want to interface with CouchDb directly 
  * (e.g. dropping the database or updating directly to test that change notifications are correctly picked up).
  */

  final Wilt wilt = new WiltServerClient2(hostName, port, scheme);

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
  var sporranFactory = (SporranInitialiser initialiser) {
    return getSporran(initialiser, Stream.empty());
  };
  run(wilt, initialiser, sporranFactory);
  runScenario1(wilt, initialiser, sporranFactory);
  runScenario2(wilt, initialiser, sporranFactory);
  runScenario3(wilt, initialiser, sporranFactory);
}