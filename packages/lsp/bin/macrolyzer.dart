import 'dart:io';

import 'package:dart_macrolyzer_lsp/server.dart';

void main(List<String> args) async {
  try {
    final dartPath = whereIs('dart').first;

    final server = MacrolyzerServer(
      stdin,
      stdout,
      dartPath: dartPath,
      stateLocation: 'C:/Users/moheng/Downloads/test',
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
