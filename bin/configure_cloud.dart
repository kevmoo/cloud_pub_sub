import 'dart:async';
import 'dart:convert';

import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:googleapis/compute/v1.dart';
import 'package:http/http.dart';

import 'shared.dart';

main(List<String> args) async {
  await doItWithClient((client) async {
    var computeThing = new ComputeApi(client);

    await _createInstanceTemplate(computeThing);

    var groupUrl = await _createInstanceGroup(computeThing);

    await _createAutoscalerAlpha(groupUrl, computeThing, client);
  });
}

Future<Uri> _createAutoscalerAlpha(
    Uri groupUrl, ComputeApi computeThing, Client client) async {
  print("now creating the auto scaler!");

  var jsonBody = JSON.encode({
    "autoscalingPolicy": {
      "minNumReplicas": 1,
      "maxNumReplicas": 10,
      "queueBasedScaling": {
        "acceptableBacklogPerInstance": 1,
        "cloudPubSub": {"topic": topic, "subscription": 'subNameThing'}
      }
    },
    "name": autoScalerName,
    "target": groupUrl.toString(),
    "zone": theZone
  });

  final autoScalersPath = "$project/zones/$theZone/autoscalers/";
  final expectedName = '$autoScalersPath$autoScalerName';

  var response = await client.post("${gcpComputeV1Uri}$autoScalersPath",
      headers: {"Content-Type": 'application/json; charset=utf-8'},
      body: jsonBody);

  var bodyMap = JSON.decode(response.body);

  if (response.statusCode == 200) {
    var operation =
        await _waitForOperation(computeThing, new Operation.fromJson(bodyMap));

    assert("$gcpComputeV1Uri$expectedName" == operation.targetLink);

    return Uri.parse(operation.targetLink);
  } else {
    var messageMap =
        ((bodyMap['error'] as Map)['errors'] as List).single as Map;

    var message = messageMap['message'];

    if (response.statusCode == 409 &&
        message == "The resource '$expectedName' already exists") {
      print(message);
      return Uri.parse("$gcpComputeV1Uri$expectedName");
    }

    throw new DetailedApiRequestError(response.statusCode, message);
  }
}

Future<Uri> _createInstanceGroup(ComputeApi api) async {
  var manager = new InstanceGroupManager.fromJson({
    "name": managerName,
    "instanceTemplate": "$project/global/instanceTemplates/$templateName",
    "targetSize": 0
  });

  print('creating an instance group');

  final resource = "$project/zones/$theZone/instanceGroupManagers/$managerName";

  try {
    var thing =
        await api.instanceGroupManagers.insert(manager, projectSimple, theZone);

    thing = await _waitForOperation(api, thing);

    assert("$gcpComputeV1Uri$resource" == thing.targetLink);

    return Uri.parse(thing.targetLink);
  } on DetailedApiRequestError catch (e) {
    if (e.message == "The resource '$resource' already exists") {
      print(e.message);
      return Uri.parse("$gcpComputeV1Uri$resource");
    }
    print(prettyJson(e.errors.map((a) => a.originalJson).toList()));
    print(e.message);
    rethrow;
  }
}

Future<Operation> _waitForOperation(ComputeApi api, Operation thing) async {
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
  }
  print('${thing.status} - ${thing.progress} - ${thing.selfLink}');

  return thing;
}

Future _createInstanceTemplate(ComputeApi api) async {
  var template = new InstanceTemplate.fromJson({
    "name": templateName,
    "description": "",
    "properties": {
      "machineType": "g1-small",
      "metadata": {
        "items": [
          {"key": "startup-script", "value": _install}
        ]
      },
      "tags": {"items": []},
      "disks": [
        {
          "type": "PERSISTENT",
          "boot": true,
          "mode": "READ_WRITE",
          "autoDelete": true,
          "deviceName": "pubsubfun1",
          "initializeParams": {
            "sourceImage":
                "${gcpComputeV1Uri}projects/debian-cloud/global/images/debian-8-jessie-v20170124",
            "diskType": "pd-standard",
            "diskSizeGb": "10"
          }
        }
      ],
      "canIpForward": false,
      "networkInterfaces": [
        {
          "network": "$project/global/networks/default",
          "accessConfigs": [
            {"name": "External NAT", "type": "ONE_TO_ONE_NAT"}
          ]
        }
      ],
      "scheduling": {
        "preemptible": false,
        "onHostMaintenance": "MIGRATE",
        "automaticRestart": true
      },
      "serviceAccounts": [
        {
          "email": "320099043588-compute@developer.gserviceaccount.com",
          "scopes": [
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring.write",
            "https://www.googleapis.com/auth/servicecontrol",
            "https://www.googleapis.com/auth/service.management.readonly",
            "https://www.googleapis.com/auth/trace.append"
          ]
        }
      ]
    }
  });

  try {
    print('Trying to create a template...');
    var operation = await api.instanceTemplates.insert(template, projectSimple);
    operation = await _waitForOperation(api, operation);
    print("created!");
  } on DetailedApiRequestError catch (e) {
    // TODO: do the actual check on this to make sure the URI is as expected
    if (e.message.contains("already exists")) {
      print(e.message);
      return;
    }
    rethrow;
  }
}

final _install = r'''
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install apt-transport-https git
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart
dart
dart --version
''';
