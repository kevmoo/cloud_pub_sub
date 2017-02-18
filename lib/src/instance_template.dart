import 'dart:async';

import 'package:googleapis/compute/v1.dart';

import 'compute_utils.dart';

Future<Uri> createInstanceTemplate(
    ComputeApi api, String projectName, String templateName) async {
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
          "network": "projects/$projectName/global/networks/default",
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
  var resource = "projects/$projectName/global/instanceTemplates/$templateName";
  return createIfNotExist(
      api, resource, () => api.instanceTemplates.insert(template, projectName));
}

final _install = r'''
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh
sudo apt-get install apt-transport-https --assume-yes
sudo apt-get update
sudo apt-get install apt-transport-https git --assume-yes
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > \
  /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart --assume-yes
echo $(dart --version 2>&1) | logger -t dart_version
''';
