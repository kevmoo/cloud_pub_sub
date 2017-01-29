// Copyright (c) 2017, Kevin Moore. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:googleapis/pubsub/v1.dart';
import 'package:http/http.dart';

import 'shared.dart';

main(List<String> arguments) => doItWithClient(_doIt);

Future _doIt(Client client) async {
  var pubSub = new PubsubApi(client);

  var request = new PublishRequest()
    ..messages = [
      new PubsubMessage()
        ..dataAsBytes = UTF8.encode("hello, world at ${new DateTime.now()}")
    ];

  var response = await pubSub.projects.topics.publish(request, topic);

  print(response.messageIds);
}
