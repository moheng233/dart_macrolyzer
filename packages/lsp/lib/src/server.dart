import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:dart_macrolyzer_lsp_protocol/lsp_client.dart';
import 'package:dart_macrolyzer_lsp_protocol/lsp_server.dart';

import 'event/file_system_event.dart';
import 'file_system.dart';
import 'util/file_path.dart';

const name = 'macrolyzer';
const version = '0.0.1';

final class MacrolyzerServer {
  MacrolyzerServer(
    Stream<List<int>> stdin,
    StreamSink<List<int>> stdout, {
    required this.dartPath,
    required String stateLocation,
    this.onProcessClose,
  }) : _downstream = LspServer(stdin, stdout),
       _fileSystem = MacrolyzerFileSystem(
         PhysicalResourceProvider(stateLocation: stateLocation),
       ) {
    _downstream
      ..onInitialize(_onInitialize)
      ..onInitialized(_onInitialized)
      ..onWillSaveTextDocument(_onWillSaveTextDocument)
      ..onDidOpenTextDocument(_onDidOpenTextDocument)
      ..onDidChangeTextDocument(_onDidChangeTextDocument)
      ..onDidCloseTextDocument(_onDidCloseTextDocument)
      ..onDidSaveTextDocument(_onDidSaveTextDocument);

    _fileSystem.downstreamEvent.listen(
      (event) async {
        switch (event) {
          case FileSystemOpenEvent():
            _console.log('${event.path} open');
          case FileSystemCompleteChangeEvent():
            _console.log('${event.path} change');

            final context = _analysis.contextFor(event.path);

            context.changeFile(event.path);
            await context.applyPendingFileChanges();

            final session = context.currentSession;
            final unit = await session.getResolvedLibrary(event.path);

            if (unit is ResolvedLibraryResult) {}
          case FileSystemCloseEvent():
            _console.log('${event.path} close');
          case FileSystemSaveEvent():
            _console.log('${event.path} save');
        }
      },
    );
  }

  final String dartPath;

  final void Function(int exitCode)? onProcessClose;

  final LspServer _downstream;
  late final LspClient _upstream;

  late final AnalysisContextCollection _analysis;
  final MacrolyzerFileSystem _fileSystem;

  late final Process _lspProcess;

  bool listend = false;
  bool initialized = false;

  RemoteConsole get _console => _downstream.console;

  Future<void> listen() async {
    _lspProcess = await Process.start(
      dartPath,
      [
        'language-server',
        '--protocol=lsp',
        '--client-id=$name',
        '--client-version=$version',
      ],
      runInShell: true,
    );

    _upstream = LspClient(_lspProcess.stdout, _lspProcess.stdin);

    unawaited(
      _lspProcess.exitCode.then((exitCode) {
        onProcessClose?.call(exitCode);
      }),
    );

    await _registerMethods();

    _downstream.peer.registerFallback(
      (parameters) =>
          _upstream.peer.sendRequest(parameters.method, parameters.value),
    );

    _upstream.peer.registerFallback(
      (parameters) =>
          _downstream.peer.sendRequest(parameters.method, parameters.value),
    );

    listend = true;

    await Future.wait([_downstream.listen(), _upstream.listen()]);
  }

  Future<void> _onDidChangeTextDocument(
    DidChangeTextDocumentParams params,
  ) async {
    final file = _fileSystem.getVirtaulFile(
      toFilePath(params.textDocument.uri),
    );
    final source = file.source;
    var content = file.content;

    for (final change in params.contentChanges) {
      change.map(
        (p) => content.replaceRange(
          source.getOffset(p.range.start.line, p.range.start.character),
          source.getOffset(p.range.end.line, p.range.end.character),
          p.text,
        ),
        (p) {
          content = p.text;
        },
      );
    }

    file.change(content, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _onDidCloseTextDocument(
    DidCloseTextDocumentParams params,
  ) async {
    _fileSystem.getVirtaulFile(toFilePath(params.textDocument.uri)).close();
  }

  Future<void> _onDidOpenTextDocument(DidOpenTextDocumentParams params) async {
    _fileSystem.open(
      toFilePath(params.textDocument.uri),
      params.textDocument.text,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _onDidSaveTextDocument(DidSaveTextDocumentParams params) async {}

  Future<InitializeResult> _onInitialize(InitializeParams params) {
    _analysis = AnalysisContextCollection(
      includedPaths: [if (params.rootUri != null) params.rootUri!.toFilePath()],
      resourceProvider: _fileSystem,
    );

    return _upstream.initialize(params);
  }

  Future<void> _onInitialized(InitializedParams params) async {
    initialized = true;

    _fileSystem.analysis = _analysis;

    _upstream.initialized(params);
  }

  Future<void> _onWillSaveTextDocument(
    WillSaveTextDocumentParams params,
  ) async {
    return _upstream.willSaveTextDocument(params);
  }

  Future<void> _registerMethods() async {
    _upstream.onNotification(r'$/progress', (param) async {
      _downstream.sendNotification(r'$/progress', param);
    });

    _fileSystem.upstreamEvent.listen(
      (event) {
        switch (event) {
          case FileSystemOpenEvent():
            _upstream.didOpenTextDocument(
              DidOpenTextDocumentParams(
                textDocument: TextDocumentItem(
                  languageId: 'dart',
                  text: event.content,
                  uri: Uri.file(event.path),
                  version: event.modificationStamp,
                ),
              ),
            );
          case FileSystemCompleteChangeEvent():
            _upstream.didChangeTextDocument(
              DidChangeTextDocumentParams(
                contentChanges: [
                  Either2.t2(
                    TextDocumentContentChangeEvent2(text: event.content),
                  ),
                ],
                textDocument: VersionedTextDocumentIdentifier(
                  uri: Uri.file(event.path),
                  version: event.modificationStamp,
                ),
              ),
            );
          case FileSystemCloseEvent():
            _upstream.didCloseTextDocument(
              DidCloseTextDocumentParams(
                textDocument: TextDocumentIdentifier(uri: Uri.file(event.path)),
              ),
            );
          case FileSystemSaveEvent():
            _upstream.didSaveTextDocument(
              DidSaveTextDocumentParams(
                textDocument: TextDocumentIdentifier(uri: Uri.file(event.path)),
              ),
            );
        }
      },
    );
  }
}
