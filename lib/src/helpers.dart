import 'dart:convert';

String prettyJson(Object obj) => const JsonEncoder.withIndent(' ').convert(obj);
