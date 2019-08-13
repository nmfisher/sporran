/*
 * Package : Sporran
 * Author : Nick Fisher <nick.fisher@avinium.com>
 * Date   : 30/07/2019
 * Licence :  MIT
 */

library sporran_io;

import 'dart:async';

import 'package:sporran/src/Sporran.dart';
import 'package:sporran/src/Event.dart' as eventWrapper;
import 'package:sporran/src/SporranInitialiser.dart';
import 'package:sporran/src/wilt/WiltServerClient2.dart';
import 'package:wilt/wilt.dart';
export 'src/Sporran.dart';
export 'src/SporranException.dart';
export 'src/SporranInitialiser.dart';
// ideally these should be kept private to this library, but we export them for testing in Flutter projects
export 'src/wilt/WiltServerClient2.dart'; 
export 'src/tests/sporran_test.dart'; 
export 'src/tests/sporran_scenario1_test.dart';
export 'src/tests/sporran_scenario2_test.dart';
export 'src/tests/sporran_scenario3_test.dart';

Wilt _getWiltClient(String host, String port, String scheme) => WiltServerClient2(host, port, scheme);

eventWrapper.Event _eventFactory(String type, String name) => new eventWrapper.Event.eventType(type, name);

Future<Sporran> getSporran(SporranInitialiser initialiser, Stream<bool> connectivity) async { 
  var sporran = Sporran(initialiser, connectivity, _getWiltClient, _eventFactory);
  await sporran.onReady.first;
  return sporran;
}
