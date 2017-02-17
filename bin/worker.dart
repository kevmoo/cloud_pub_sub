// Copyright (c) 2017, Kevin Moore. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:googleapis/pubsub/v1.dart';
import 'package:googleapis/logging/v2.dart' as logging;
import 'package:http/http.dart';

import 'shared.dart';

main(List<String> arguments) => doItWithClient(_doIt);

Future _doIt(Client client) async {
  var log = new logging.LoggingApi(client);

  /*
  var things = await log.monitoredResourceDescriptors.list();
  print(things.resourceDescriptors.map((mdr) {
return "${mdr.displayName}\t${mdr.description}";
  }).join('\n'));

*/
  Future _doLogThing(String content) async {
    var resource = new logging.MonitoredResource()..type = 'project';

    var entry = new logging.LogEntry()
      ..logName = '$project/logs/my-test-log'
      ..resource = resource
      ..textPayload = content;

    var response = await log.entries
        .write(new logging.WriteLogEntriesRequest()..entries = [entry]);

    print(response);
    print(prettyJson(response));
  }

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

  await _doLogThing('starting!');

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
