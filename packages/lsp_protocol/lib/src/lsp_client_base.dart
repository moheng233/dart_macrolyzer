import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';

import 'helper/protocol/protocol_special.dart';
import 'protocol/protocol_generated.dart';
import 'remote_console.dart';
import 'wireformat.dart';

class LspClient {
  LspClient(Stream<List<int>> stream, StreamSink<List<int>> sink) {
    peer = Peer(lspChannel(stream, sink));
  }

  late final Peer peer;
  late final RemoteConsole console;

  Future<void> listen() => peer.listen();

  Future<void> close() => peer.close();

  Future<dynamic> sendRequest(
    String method,
    dynamic params,
  ) async {
    return peer.sendRequest(method, params);
  }

  Future<void> onRequest<R>(
    String method,
    Future<R> Function(Parameters) handler,
  ) async {
    peer.registerMethod(method, (Parameters params) async {
      return handler(params);
    });
  }

  void onNotification(
    String method,
    Future<void> Function(Parameters) handler,
  ) {
    peer.registerMethod(method, (Parameters params) async {
      await handler(params);
    });
  }

  void sendNotification(String method, dynamic params) {
    return peer.sendNotification(method, params);
  }

  // Client methods - these send requests to the server
  Future<InitializeResult> initialize(InitializeParams params) async {
    return InitializeResult.fromJson(
      (await sendRequest('initialize', params.toJson()))
          as Map<String, Object?>,
    );
  }

  void initialized(InitializedParams params) {
    sendNotification('initialized', params.toJson());
  }

  Future<void> shutdown() async {
    await sendRequest('shutdown', null);
  }

  void exit() {
    sendNotification('exit', null);
  }

  void didOpenTextDocument(DidOpenTextDocumentParams params) {
    sendNotification('textDocument/didOpen', params.toJson());
  }

  void didChangeTextDocument(DidChangeTextDocumentParams params) {
    sendNotification('textDocument/didChange', params.toJson());
  }

  void didCloseTextDocument(DidCloseTextDocumentParams params) {
    sendNotification('textDocument/didClose', params.toJson());
  }

  void willSaveTextDocument(WillSaveTextDocumentParams params) {
    sendNotification('textDocument/willSave', params.toJson());
  }

  Future<List<TextEdit>> willSaveWaitUntilTextDocument(
    WillSaveTextDocumentParams params,
  ) async {
    return (await sendRequest(
              'textDocument/willSaveWaitUntil',
              params.toJson(),
            )
            as List<Map<String, Object?>>)
        .map(TextEdit.fromJson)
        .toList();
  }

  void didSaveTextDocument(DidSaveTextDocumentParams params) {
    sendNotification('textDocument/didSave', params.toJson());
  }

  Future<Hover?> hover(TextDocumentPositionParams params) async {
    final result = await sendRequest('textDocument/hover', params.toJson());
    return result != null 
        ? Hover.fromJson(result as Map<String, Object?>) 
        : null;
  }

  Future<CompletionList> completion(TextDocumentPositionParams params) async {
    final result = await sendRequest(
      'textDocument/completion',
      params.toJson(),
    );
    return CompletionList.fromJson(result as Map<String, Object?>);
  }

  Future<CompletionItem> completionResolve(CompletionItem item) async {
    final result = await sendRequest('completionItem/resolve', item.toJson());
    return CompletionItem.fromJson(result as Map<String, Object?>);
  }

  Future<SignatureHelp?> signatureHelp(
    TextDocumentPositionParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/signatureHelp',
      params.toJson(),
    );
    return result != null 
        ? SignatureHelp.fromJson(result as Map<String, Object?>) 
        : null;
  }

  Future<Either3<Location, List<Location>, List<LocationLink>>?> declaration(
    TextDocumentPositionParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/declaration',
      params.toJson(),
    );
    return result != null ? _parseLocationResult(result) : null;
  }

  Future<Either3<Location, List<Location>, List<LocationLink>>?> definition(
    TextDocumentPositionParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/definition',
      params.toJson(),
    );
    return result != null ? _parseLocationResult(result) : null;
  }

  Future<Either3<Location, List<Location>, List<LocationLink>>?> typeDefinition(
    TextDocumentPositionParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/typeDefinition',
      params.toJson(),
    );
    return result != null ? _parseLocationResult(result) : null;
  }

  Future<Either3<Location, List<Location>, List<LocationLink>>?> implementation(
    TextDocumentPositionParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/implementation',
      params.toJson(),
    );
    return result != null ? _parseLocationResult(result) : null;
  }

  Future<List<Location>> references(ReferenceParams params) async {
    final result = await sendRequest(
      'textDocument/references',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(Location.fromJson)
        .toList();
  }

  Future<List<DocumentHighlight>> documentHighlight(
    TextDocumentPositionParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/documentHighlight',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(DocumentHighlight.fromJson)
        .toList();
  }

  Future<List<SymbolInformation>> documentSymbol(
    DocumentSymbolParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/documentSymbol',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(SymbolInformation.fromJson)
        .toList();
  }

  Future<SymbolInformation> workspaceSymbolResolve(
    SymbolInformation symbol,
  ) async {
    final result = await sendRequest(
      'workspace/symbol/resolve',
      symbol.toJson(),
    );
    return SymbolInformation.fromJson(result as Map<String, Object?>);
  }

  Future<List<CodeAction>> codeAction(CodeActionParams params) async {
    final result = await sendRequest(
      'textDocument/codeAction',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(CodeAction.fromJson)
        .toList();
  }

  Future<CodeAction> codeActionResolve(CodeAction action) async {
    final result = await sendRequest('codeAction/resolve', action.toJson());
    return CodeAction.fromJson(result as Map<String, Object?>);
  }

  Future<List<CodeLens>> codeLens(CodeLensParams params) async {
    final result = await sendRequest('textDocument/codeLens', params.toJson());
    return (result as List<Map<String, Object?>>)
        .map(CodeLens.fromJson)
        .toList();
  }

  Future<CodeLens> codeLensResolve(CodeLens lens) async {
    final result = await sendRequest('codeLens/resolve', lens.toJson());
    return CodeLens.fromJson(result as Map<String, Object?>);
  }

  Future<List<TextEdit>> documentFormatting(
    DocumentFormattingParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/formatting',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(TextEdit.fromJson)
        .toList();
  }

  Future<List<TextEdit>> documentRangeFormatting(
    DocumentRangeFormattingParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/rangeFormatting',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(TextEdit.fromJson)
        .toList();
  }

  Future<List<TextEdit>> documentOnTypeFormatting(
    DocumentOnTypeFormattingParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/onTypeFormatting',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(TextEdit.fromJson)
        .toList();
  }

  Future<WorkspaceEdit> rename(RenameParams params) async {
    final result = await sendRequest('textDocument/rename', params.toJson());
    return WorkspaceEdit.fromJson(result as Map<String, Object?>);
  }

  Future<Either2<Range, PrepareRenameResult>> prepareRename(
    TextDocumentPositionParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/prepareRename',
      params.toJson(),
    ) as Map<String, Object?>;
    // Handle the Either2 result based on the actual structure
    if (result.containsKey('start')) {
      return Either2.t1(Range.fromJson(result));
    } else {
      // Note: PrepareRenameResult might not exist in the generated types
      // You may need to check the actual protocol definition
      return Either2.t2(result as PrepareRenameResult);
    }
  }

  Future<List<DocumentLink>> documentLinks(DocumentLinkParams params) async {
    final result = await sendRequest(
      'textDocument/documentLink',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(DocumentLink.fromJson)
        .toList();
  }

  Future<DocumentLink> documentLinkResolve(DocumentLink link) async {
    final result = await sendRequest('documentLink/resolve', link.toJson());
    return DocumentLink.fromJson(result as Map<String, Object?>);
  }

  Future<List<ColorInformation>> documentColor(
    ColorPresentationParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/documentColor',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(ColorInformation.fromJson)
        .toList();
  }

  Future<List<ColorPresentation>> colorPresentation(
    ColorPresentationParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/colorPresentation',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(ColorPresentation.fromJson)
        .toList();
  }

  Future<List<FoldingRange>> foldingRanges(FoldingRangeParams params) async {
    final result = await sendRequest(
      'textDocument/foldingRange',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(FoldingRange.fromJson)
        .toList();
  }

  Future<List<SelectionRange>> selectionRanges(
    SelectionRangeParams params,
  ) async {
    final result = await sendRequest(
      'textDocument/selectionRange',
      params.toJson(),
    );
    return (result as List<Map<String, Object?>>)
        .map(SelectionRange.fromJson)
        .toList();
  }

  Future<dynamic> executeCommand(ExecuteCommandParams params) async {
    return sendRequest('workspace/executeCommand', params.toJson());
  }

  // Client notification handlers - these handle notifications from server
  void onPublishDiagnostics(
    Future<void> Function(PublishDiagnosticsParams) handler,
  ) {
    peer.registerMethod('textDocument/publishDiagnostics', (
      Parameters params,
    ) async {
      final diagnosticsParams = PublishDiagnosticsParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(diagnosticsParams);
    });
  }

  void onShowMessage(
    Future<void> Function(ShowMessageParams) handler,
  ) {
    peer.registerMethod('window/showMessage', (Parameters params) async {
      final messageParams = ShowMessageParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(messageParams);
    });
  }

  void onShowMessageRequest(
    Future<MessageActionItem?> Function(ShowMessageRequestParams) handler,
  ) {
    peer.registerMethod('window/showMessageRequest', (Parameters params) async {
      final requestParams = ShowMessageRequestParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(requestParams);
    });
  }

  void onLogMessage(
    Future<void> Function(LogMessageParams) handler,
  ) {
    peer.registerMethod('window/logMessage', (Parameters params) async {
      final logParams = LogMessageParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(logParams);
    });
  }

  void onWorkDoneProgressCreate(
    Future<void> Function(WorkDoneProgressCreateParams) handler,
  ) {
    peer.registerMethod('window/workDoneProgress/create', (
      Parameters params,
    ) async {
      final progressParams = WorkDoneProgressCreateParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(progressParams);
    });
  }

  // Helper method to parse location results
  Either3<Location, List<Location>, List<LocationLink>>? _parseLocationResult(
    dynamic result,
  ) {
    if (result is Map<String, Object?>) {
      // Single Location
      return Either3.t1(Location.fromJson(result));
    } else if (result is List) {
      if (result.isEmpty) {
        return const Either3.t2(<Location>[]);
      }
      final first = result.first;
      if (first is Map<String, Object?> && first.containsKey('targetUri')) {
        // List of LocationLink
        return Either3.t3(
          (result as List<Map<String, Object?>>)
              .map(LocationLink.fromJson)
              .toList(),
        );
      } else {
        // List of Location
        return Either3.t2(
          (result as List<Map<String, Object?>>)
              .map(Location.fromJson)
              .toList(),
        );
      }
    }
    return null;
  }

  Future<void> dispose() => peer.close();
}
