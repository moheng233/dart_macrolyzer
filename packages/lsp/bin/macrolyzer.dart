import 'dart:io';

import 'package:dart_macrolyzer_lsp/server.dart';
import 'package:dart_macrolyzer_lsp_protocol/lsp_client.dart';
import 'package:dart_macrolyzer_lsp_protocol/lsp_server.dart';

const name = "macrolyzer";
const version = "0.0.1";

void main(List<String> args) async {
  try {
    final dartPath = whereIs("dart").first;

    final server = MacrolyzerServer(
      stdin,
      stdout,
      dartPath: dartPath,
      onProcessClose: (exitCode) {
        stderr.writeln('Analysis server exited with code: $exitCode');
        exit(exitCode);
      },
    );

    await server.listen();
  } on Exception catch (e, stackTrace) {
    stderr
      ..writeln('Error in macrolyzer: $e')
      ..writeln('Stack trace: $stackTrace');
    exit(1);
  }
}
