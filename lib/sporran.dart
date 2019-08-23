/*
 * Package : Sporran
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/02/2014
 * Copyright :  S.Hamblett@OSCF
 */

library sporran;

import 'dart:async';
import 'dart:html';

import 'package:sporran/src/Sporran.dart';
import 'package:sporran/src/Event.dart' as eventWrapper;
import 'package:sporran/src/SporranInitialiser.dart';
import 'package:sporran/src/wilt/WiltBrowserClient2.dart';
import 'package:wilt/wilt.dart';
import 'package:wilt/wilt_browser_client.dart';

export 'src/Sporran.dart';
export 'src/SporranException.dart';
export 'src/SporranInitialiser.dart';

Wilt _getWiltClient(String host, String port, String scheme) => WiltBrowserClient2(host, port, scheme);

eventWrapper.Event _eventFactory(String type, String name) => new eventWrapper.Event.eventType(type, name);

Future<Sporran> getSporran(SporranInitialiser initialiser, bool localOnly) async {
  final SynchronousStreamController<bool> _onlineStreamController = StreamController<bool>(sync: true);
  window.onOnline.listen((x) {
    _onlineStreamController.add(true);
  });

  window.onOffline.listen((x) {
    _onlineStreamController.add(false);
  });
  
  final Sporran sporran = Sporran(initialiser, _onlineStreamController.stream, _getWiltClient, _eventFactory, localOnly);
  await sporran.onReady.first;
  return sporran;
}
