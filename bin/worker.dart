import 'dart:async';

import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:cloud_pub_sub/src/shared.dart';
import 'package:googleapis/logging/v2.dart' as logging;
import 'package:googleapis/pubsub/v1.dart';
import 'package:http/http.dart';

main(List<String> arguments) => doItWithClient(_doIt);

Future _doIt(Client client) async {
  var log = new logging.LoggingApi(client);

  Future _doLogThing(Map<String, Object> jsonContent) async {
    var resource = new logging.MonitoredResource()..type = 'project';

    var entry = new logging.LogEntry()
      ..logName = '$project/logs/my-test-log'
      ..resource = resource
      ..jsonPayload = jsonContent;

    await log.entries
        .write(new logging.WriteLogEntriesRequest()..entries = [entry]);
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

  await _doLogThing({'worker': 'starting!'});

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

    var messageContent = message.message.data;

    print("working on: $messageContent");

    await pubSub.subscriptions.acknowledge(
        new AcknowledgeRequest()..ackIds = [message.ackId], subName);
    print("act!");
  }
}
