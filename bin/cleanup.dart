import 'package:cloud_pub_sub/cloud_pub_sub.dart';
import 'package:googleapis/compute/v1.dart';

main() async {
  await doItWithClient((client) async {
    var computeThing = new ComputeApi(client);

    // list all instance groups
    var groups =
        await computeThing.instanceGroupManagers.list(projectSimple, theZone);

    assert(groups.nextPageToken == null);
    for (var group in groups.items ?? const []) {
      print(group.name);

      try {
        await waitForOperation(
            computeThing,
            await computeThing.instanceGroupManagers
                .delete(projectSimple, theZone, group.name));
      } on DetailedApiRequestError catch (e) {
        print(e.message);
      }
    }

    var templates = await computeThing.instanceTemplates.list(projectSimple);

    assert(templates.nextPageToken == null);
    for (var template in templates.items ?? const <InstanceTemplate>[]) {
      print(template.name);
      try {
        await waitForOperation(
            computeThing,
            await computeThing.instanceTemplates
                .delete(projectSimple, template.name));
      } on DetailedApiRequestError catch (e) {
        print(e.message);
      }
    }
  });
}
