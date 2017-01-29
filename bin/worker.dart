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
  var pubSub = new PubsubApi(client).projects;

  var subName = '$project/subscriptions/kevmoo1';

  Subscription sub;
  try {
    sub = await pubSub.subscriptions.get(subName);
  } on DetailedApiRequestError catch (e) {
    if (e.message.contains("Resource not found")) {
      var request = new Subscription()..topic = topic;

      sub = await pubSub.subscriptions.create(request, subName);
    } else {
      rethrow;
    }
  }

  print("We have a sub! - ${sub.name}");

  while (true) {
    var pullRequest = new PullRequest()
      ..maxMessages = 1
      ..returnImmediately = true;

    print('Looking for any work to do...');

    var pullResponse = await pubSub.subscriptions.pull(pullRequest, subName);

    if (pullResponse.receivedMessages == null) {
      var wait = const Duration(seconds: 5);
      print('No work to do, waiting $wait');
      await new Future.delayed(wait);
      continue;
    }

    var message = pullResponse.receivedMessages.single;

    var messageContent = UTF8.decode(message.message.dataAsBytes);

    print("working on: $messageContent");

    await pubSub.subscriptions.acknowledge(
        new AcknowledgeRequest()..ackIds = [message.ackId], subName);
    print("act!");
  }
}
