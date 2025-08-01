import 'dart:async';
import 'dart:io';

import 'package:dart_macrolyzer_lsp_protocol/lsp_server.dart';

const name = "macrolyzer";
const version = "0.0.1";

class MacrolyzerServer {
  MacrolyzerServer(this._stdin, this._stdout, {required this.dartPath})
    : _server = LspServer(_stdin, stdout);

  final String dartPath;

  final Stream<List<int>> _stdin;
  final StreamSink<List<int>> _stdout;

  final LspServer _server;
  

  Future<void> listen() async {
    final lspProcess = await Process.start(
      dartPath,
      [
        "language-server",
        "--protocol=lsp",
        "--client-id=$name",
        "--client-version=$version",
      ],
      runInShell: true,
      includeParentEnvironment: true,
    );
  }
}
