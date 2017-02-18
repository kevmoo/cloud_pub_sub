import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:googleapis/compute/v1.dart';

main() async {
  await doItWithClient((client) async {
    var computeThing = new ComputeApi(client);

    // list all instance groups
    var groups =
        await computeThing.instanceGroupManagers.list(projectName, gcZone);

    assert(groups.nextPageToken == null);
    for (var group in groups.items ?? const []) {
      print(group.name);

      try {
        await waitForOperation(
            computeThing,
            await computeThing.instanceGroupManagers
                .delete(projectName, gcZone, group.name));
      } on DetailedApiRequestError catch (e) {
        print(e.message);
      }
    }

    var templates = await computeThing.instanceTemplates.list(projectName);

    assert(templates.nextPageToken == null);
    for (var template in templates.items ?? const <InstanceTemplate>[]) {
      print(template.name);
      try {
        await waitForOperation(
            computeThing,
            await computeThing.instanceTemplates
                .delete(projectName, template.name));
      } on DetailedApiRequestError catch (e) {
        print(e.message);
      }
    }
  });
}
