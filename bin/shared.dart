final String projectSimple = 'j832com-3c809';
final String project = 'projects/$projectSimple';
final topic = '$project/topics/test1';
final gcpComputeV1Uri = "https://www.googleapis.com/compute/v1/";

final _time = new DateTime.now().millisecondsSinceEpoch.toString();

final theZone = 'us-central1-a';
final managerName = "psf-man-$_time";
final autoScalerName = 'psf-scale4-$_time';
final String templateName = 'psf-template-$_time';
