import 'dart:async';
import 'dart:io';

import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:googleapis/compute/v1.dart';

import 'names.dart';

final gcpComputeV1Uri = "https://www.googleapis.com/compute/v1/";

Future<Uri> createIfNotExist(
    ComputeApi api, String resource, Future<Operation> creator()) async {
  try {
    var thing = await creator();
    thing = await waitForOperation(api, thing);

    assert("$gcpComputeV1Uri$resource" == thing.targetLink);

    return Uri.parse(thing.targetLink);
  } on DetailedApiRequestError catch (e) {
    if (e.message == "The resource '$resource' already exists") {
      print('\t${e.message}');
      return Uri.parse("$gcpComputeV1Uri$resource");
    }
    print(prettyJson(e.errors.map((a) => a.originalJson).toList()));
    print(e.message);
    rethrow;
  }
}

Future<Operation> waitForOperation(ComputeApi api, Operation thing) async {
  while (thing.status != 'DONE') {
    var uri = Uri.parse(thing.selfLink);
    assert(uri.pathSegments.take(4).join('/') == "compute/v1/$project");

    var locationScope = uri.pathSegments[4];

    switch (locationScope) {
      case "zones":
        thing =
            await api.zoneOperations.get(projectSimple, theZone, thing.name);
        break;
      case "global":
        thing = await api.globalOperations.get(projectSimple, thing.name);
        break;
      default:
        throw "can't part at $locationScope \t $uri";
    }
    stdout.write('...${thing.progress}');
    await new Future.delayed(const Duration(seconds: 1));
  }
  stdout.writeln();
  print('\t${thing.status} - ${thing.targetLink}');

  return thing;
}
