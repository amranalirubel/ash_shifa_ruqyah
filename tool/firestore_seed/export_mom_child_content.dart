import 'dart:convert';
import 'dart:io';

// This exporter intentionally runs without bootstrapping the Flutter package.
// ignore: avoid_relative_lib_imports
import '../../lib/utils/mom_child_content_catalog.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart tool/firestore_seed/export_mom_child_content.dart '
      '<output.json>',
    );
    exitCode = 64;
    return;
  }

  final documents = buildMomChildCarePublishedDocuments();
  final output = File(arguments.single);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(documents)}\n',
  );

  stdout.writeln('Exported ${documents.length} canonical documents.');
}
