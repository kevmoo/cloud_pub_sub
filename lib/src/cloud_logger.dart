import 'dart:async';

import 'package:googleapis/logging/v2.dart';
import 'package:http/http.dart';

class CloudLogger {
  final String projectName;
  final String logName;
  final LoggingApi _logging;

  CloudLogger(this.projectName, this.logName, Client client)
      : this._logging = new LoggingApi(client);

  Future<Null> log(dynamic logObject) async {
    var resource = new MonitoredResource()..type = 'project';

    var entry = new LogEntry()
      ..logName = 'projects/$projectName/logs/$logName'
      ..resource = resource;

    if (logObject is String) {
      entry.textPayload = logObject;
    } else if (logObject is Map) {
      entry.jsonPayload = logObject;
    } else {
      throw new ArgumentError.value(
          logObject, 'logObject', "Must be `String` or JSON map");
    }

    await _logging.entries
        .write(new WriteLogEntriesRequest()..entries = [entry]);
  }
}
