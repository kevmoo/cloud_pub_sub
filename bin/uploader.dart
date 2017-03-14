import 'dart:async';

import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:cloud_pub_sub/src/shared.dart';
import 'package:googleapis/pubsub/v1.dart';
import 'package:http/http.dart';

main(List<String> arguments) => doItWithClient(_doIt);

Future _doIt(Client client) async {
  var pubSub = new PubsubApi(client);

  var request = new PublishRequest()
    ..messages = [
      new PubsubMessage()..data = "hello, world at ${new DateTime.now()}"
    ];

  var response = await pubSub.projects.topics.publish(request, topic);

  print(response.messageIds);
}
