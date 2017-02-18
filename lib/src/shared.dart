import 'names.dart';

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
final templateName = 'psf-template-$_time';
final topic = '$projectPath/topics/test1';
