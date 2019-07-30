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
import 'package:sporran/src/SporranInitialiser.dart';
import 'package:wilt/wilt.dart';
import 'package:wilt/wilt_browser_client.dart';

export 'src/Sporran.dart';
export 'src/SporranException.dart';
export 'src/SporranInitialiser.dart';

Wilt _getWiltClient(String host, String port, String scheme) => WiltBrowserClient(host, port, scheme);

Sporran getSporran(SporranInitialiser initialiser) {
  final SynchronousStreamController<bool> _onlineStreamController = StreamController<bool>(sync: true);
  window.onOnline.listen((x) {
    _onlineStreamController.add(true);
  });

  window.onOffline.listen((x) {
    _onlineStreamController.add(false);
  });
  
  return Sporran(initialiser, _onlineStreamController.stream, _getWiltClient);
}