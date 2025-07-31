import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:dart_macrolyzer_lsp/util/whereis.dart';

void main(List<String> args) async {
  final dartPath = (await whereIs("dart")).first;
  final analysisServerPath = p.join(
    p.dirname(dartPath),
    "snapshots",
    "analysis_server_aot.dart.snapshot",
  );

  print(dartPath);
  print(analysisServerPath);
}
