import 'dart:async';

import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:cloud_pub_sub/src/instance_template.dart';
import 'package:googleapis/compute/v1.dart';
import 'package:http/http.dart';

main(List<String> args) async {
  await doItWithClient((client) async {
    var computeThing = new ComputeApi(client);

    var templateUri = await createInstanceTemplate(
        computeThing, projectName, getTaggedName('psf-template'));

    var groupUrl = await _createInstanceGroup(computeThing, templateUri);

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
      "$projectPath/zones/$gcZone/autoscalers/$autoScalerName",
      () => computeThing.autoscalers.insert(request, projectName, gcZone));
}

Future<Uri> _createInstanceGroup(ComputeApi api, Uri templateUri) async {
  assert(templateUri.pathSegments.take(2).join('/') == 'compute/v1');

  var manager = new InstanceGroupManager()
    ..name = managerName
    ..instanceTemplate = templateUri.pathSegments.skip(2).join('/')
    ..targetSize = 0;

  print('Creating an instance group');
  final resource =
      "$projectPath/zones/$gcZone/instanceGroupManagers/$managerName";
  return createIfNotExist(api, resource,
      () => api.instanceGroupManagers.insert(manager, projectName, gcZone));
}
