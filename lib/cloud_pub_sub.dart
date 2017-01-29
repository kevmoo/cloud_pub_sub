// Copyright (c) 2017, Kevin Moore. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:googleapis/pubsub/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:stack_trace/stack_trace.dart';

Future<AutoRefreshingAuthClient> getClient() async {
  var json = new File('key.json').readAsStringSync();

  var clientCreds = new ServiceAccountCredentials.fromJson(json);
  var scopes = const [PubsubApi.CloudPlatformScope, PubsubApi.PubsubScope];
  var creds = await clientViaServiceAccount(clientCreds, scopes);

  return creds;
}

Future<T> doItWithClient<T>(Future<T> func(Client client)) async {
  return await Chain.capture(() async {
    var client = await getClient();

    try {
      return await func(client);
    } finally {
      client.close();
    }
  }, onError: (error, Chain chain) {
    print(error);
    print(chain.terse);
    exitCode = 1;
  });
}
