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
import 'package:wilt/wilt.dart';
import 'package:wilt/wilt_server_client.dart';

export 'src/Sporran.dart';
export 'src/SporranException.dart';
export 'src/SporranInitialiser.dart';

Wilt _getWiltClient(String host, String port, String scheme) => WiltServerClient(host, port, scheme);

eventWrapper.Event _eventFactory(String type, String name) => new eventWrapper.Event.eventType(type, name);

Sporran getSporran(SporranInitialiser initialiser, Stream<bool> connectivity) => Sporran(initialiser, connectivity, _getWiltClient, _eventFactory);
