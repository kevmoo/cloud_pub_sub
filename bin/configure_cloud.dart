import 'dart:async';
import 'dart:convert';

import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:googleapis/compute/v1.dart';
import 'package:http/http.dart';

import 'shared.dart';

final theZone = 'us-central1-a';

main(List<String> args) async {
  await doItWithClient((client) async {
    var computeThing = new ComputeApi(client);

    await _createInstanceTemplate(computeThing.instanceTemplates);

    var groupUrl = await _createInstanceGroup(computeThing);

    var jsonBody = JSON.encode({
      "autoscalingPolicy": {
        "minNumReplicas": 0,
        "maxNumReplicas": 1,
        "queueBasedScaling": {
          "acceptableBacklogPerInstance": 1,
          "cloudPubSub": {"topic": topic, "subscription": 'subNameThing'}
        }
      },
      "name": "[AUTOSCALER_NAME]",
      "target": "[URL_TO_MANAGED_INSTANCE_GROUP]",
      "zone": "[ZONE]"
    });

    print("now creating the auto scaler!");

    var response = await client.post(
        "https://www.googleapis.com/compute/v1/projects/$projectSimple/zones/$theZone/autoscalers/",
        headers: {"Content-Type": 'application/json; charset=utf-8'},
        body: jsonBody);

    print([response.statusCode]);
    print(prettyJson(JSON.decode(response.body)));
  });
}

Future<Uri> _createInstanceGroup(ComputeApi api) async {
  final managerName = "pubsubfun-manager";
  var manager = new InstanceGroupManager.fromJson({
    "name": managerName,
    "instanceTemplate": "$project/global/instanceTemplates/$templateName",
    "targetSize": 0
  });

  print('creating an instance group');

  final root = "https://www.googleapis.com/compute/v1/";

  final resource = "$project/zones/$theZone/instanceGroupManagers/$managerName";

  try {
    var thing =
        await api.instanceGroupManagers.insert(manager, projectSimple, theZone);

    while (thing.status != 'DONE') {
      print('Not done! - ${thing.status} - ${thing.progress}');
      thing = await api.zoneOperations.get(projectSimple, theZone, thing.name);
    }
    print('DONE! - ${thing.status} - ${thing.progress}');
    print(prettyJson(thing));

    assert("$root$resource" == thing.targetLink);

    return Uri.parse(thing.targetLink);
  } on DetailedApiRequestError catch (e) {
    if (e.message == "The resource '$resource' already exists") {
      return Uri.parse("$root$resource");
    }
    print(prettyJson(e.errors.map((a) => a.originalJson).toList()));
    print(e.message);
    rethrow;
  }
}

Future _createInstanceTemplate(InstanceTemplatesResourceApi api) async {
  var template = new InstanceTemplate.fromJson({
    "name": templateName,
    "description": "",
    "properties": {
      "machineType": "g1-small",
      "metadata": {"items": []},
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
                "https://www.googleapis.com/compute/v1/projects/debian-cloud/global/images/debian-8-jessie-v20170124",
            "diskType": "pd-standard",
            "diskSizeGb": "10"
          }
        }
      ],
      "canIpForward": false,
      "networkInterfaces": [
        {
          "network": "projects/j832com-3c809/global/networks/default",
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
    await api.insert(template, projectSimple);
    print("created!");
  } on DetailedApiRequestError catch (e) {
    if (e.message.contains("already exists")) {
      print("Already there!");
      print(e.message);
      return;
    }
    rethrow;
  }
}

final _install = r'''
sudo apt-get update
sudo apt-get install apt-transport-https git
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart
dart
dart --version
''';
