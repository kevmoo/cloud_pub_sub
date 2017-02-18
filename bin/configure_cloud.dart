import 'dart:async';

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
  print("Creating the auto scaler...");

  var policy = new AutoscalingPolicy.fromJson({
    "coolDownPeriodSec": 120,
    "cpuUtilization": {"utilizationTarget": 0.6},
    "maxNumReplicas": 10,
    "minNumReplicas": 1
  });
  var request = new Autoscaler()
    ..autoscalingPolicy = policy
    ..target = groupUrl.toString()
    ..name = autoScalerName;

  return await createIfNotExist(
      computeThing,
      "$project/zones/$theZone/autoscalers/$autoScalerName",
      () => computeThing.autoscalers.insert(request, projectSimple, theZone));
}

Future<Uri> _createInstanceGroup(ComputeApi api) async {
  var manager = new InstanceGroupManager()
    ..name = managerName
    ..instanceTemplate = "$project/global/instanceTemplates/$templateName"
    ..targetSize = 0;

  print('Creating an instance group');
  final resource = "$project/zones/$theZone/instanceGroupManagers/$managerName";
  return createIfNotExist(api, resource,
      () => api.instanceGroupManagers.insert(manager, projectSimple, theZone));
}

// TODO(kevmoo) return the uri of the thing – at least?
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

  print("Creating instance template");
  var resource = "$project/global/instanceTemplates/$templateName";
  return createIfNotExist(api, resource,
      () => api.instanceTemplates.insert(template, projectSimple));
}

final _install = r'''
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh
sudo apt-get install apt-transport-https --assume-yes
sudo apt-get update
sudo apt-get install apt-transport-https git --assume-yes
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart --assume-yes
dart --version
logger "All done!"
''';
