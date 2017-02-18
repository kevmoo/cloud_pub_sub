import 'names.dart';

String getTaggedName(String prefix) => '$prefix-$_time';

final _time = new DateTime.now()
    .toIso8601String()
    .toLowerCase()
    .replaceAll(':', '-')
    .replaceAll('.', '-')
    .split('-')
    .take(5)
    .join('-');

final managerName = "psf-man-$_time";
final autoScalerName = 'psf-scale-$_time';

final topic = '$projectPath/topics/test1';
