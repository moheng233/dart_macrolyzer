import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';

import 'helper/protocol/protocol_special.dart';
import 'protocol/protocol_generated.dart';
import 'remote_console.dart';
import 'wireformat.dart';

class LspServer {
  LspServer(Stream<List<int>> stream, StreamSink<List<int>> sink) {
    peer = Peer(lspChannel(stream, sink));
    console = RemoteConsole(this);
  }

  late final Peer peer;
  late final RemoteConsole console;

  Future<void> listen() => peer.listen();

  Future<void> close() => peer.close();

  Future<R> sendRequest<R>(String method, dynamic params) async {
    return await peer.sendRequest(method, params) as R;
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

  void onInitialize(
    Future<InitializeResult> Function(InitializeParams) handler,
  ) {
    peer.registerMethod('initialize', (Parameters params) async {
      final initParams = InitializeParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(initParams);
    });
  }

  void onInitialized(Future<void> Function(InitializedParams) handler) {
    peer.registerMethod('initialized', (Parameters params) async {
      final initParams = InitializedParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(initParams);
    });
  }

  void onShutdown(Future<void> Function() handler) {
    peer.registerMethod('shutdown', (Parameters params) async {
      await handler();
    });
  }

  void onExit(Future<void> Function() handler) {
    peer.registerMethod('exit', (Parameters params) async {
      await handler();
    });
  }

  void onDidOpenTextDocument(
    Future<void> Function(DidOpenTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/didOpen', (Parameters params) async {
      final openParams = DidOpenTextDocumentParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(openParams);
    });
  }

  void onDidChangeTextDocument(
    Future<void> Function(DidChangeTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/didChange', (Parameters params) async {
      final changeParams = DidChangeTextDocumentParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(changeParams);
    });
  }

  void onDidCloseTextDocument(
    Future<void> Function(DidCloseTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/didClose', (Parameters params) async {
      final closeParams = DidCloseTextDocumentParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(closeParams);
    });
  }

  void onWillSaveTextDocument(
    Future<void> Function(WillSaveTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/willSave', (Parameters params) async {
      final saveParams = WillSaveTextDocumentParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(saveParams);
    });
  }

  void onWillSaveWaitUntilTextDocument(
    Future<List<TextEdit>> Function(WillSaveTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/willSaveWaitUntil', (
      Parameters params,
    ) async {
      final saveParams = WillSaveTextDocumentParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(saveParams);
    });
  }

  void onDidSaveTextDocument(
    Future<void> Function(DidSaveTextDocumentParams) handler,
  ) {
    peer.registerMethod('textDocument/didSave', (Parameters params) async {
      final saveParams = DidSaveTextDocumentParams.fromJson(
        params.value as Map<String, Object?>,
      );
      await handler(saveParams);
    });
  }

  void sendDiagnostics(PublishDiagnosticsParams params) {
    peer.sendNotification('textDocument/publishDiagnostics', params.toJson());
  }

  void onHover(Future<Hover> Function(TextDocumentPositionParams) handler) {
    peer.registerMethod('textDocument/hover', (Parameters params) async {
      final hoverParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(hoverParams);
    });
  }

  void onCompletion(
    Future<CompletionList> Function(TextDocumentPositionParams) handler,
  ) {
    peer.registerMethod('textDocument/completion', (Parameters params) async {
      final completionParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(completionParams);
    });
  }

  void onCompletionResolve(
    Future<CompletionItem> Function(CompletionItem) handler,
  ) {
    peer.registerMethod('completionItem/resolve', (Parameters params) async {
      final completionItem = CompletionItem.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(completionItem);
    });
  }

  void onSignatureHelp(
    Future<SignatureHelp> Function(TextDocumentPositionParams) handler,
  ) {
    peer.registerMethod('textDocument/signatureHelp', (
      Parameters params,
    ) async {
      final signatureParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(signatureParams);
    });
  }

  void onDeclaration(
    Future<Either3<Location, List<Location>, List<LocationLink>>?> Function(
      TextDocumentPositionParams,
    )
    handler,
  ) {
    peer.registerMethod('textDocument/declaration', (Parameters params) async {
      final declarationParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(declarationParams);
    });
  }

  void onDefinition(
    Future<Either3<Location, List<Location>, List<LocationLink>>?> Function(
      TextDocumentPositionParams,
    )
    handler,
  ) {
    peer.registerMethod('textDocument/definition', (Parameters params) async {
      final definitionParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(definitionParams);
    });
  }

  void onTypeDefinition(
    Future<Either3<Location, List<Location>, List<LocationLink>>?> Function(
      TextDocumentPositionParams,
    )
    handler,
  ) {
    peer.registerMethod('textDocument/typeDefinition', (
      Parameters params,
    ) async {
      final typeDefinitionParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(typeDefinitionParams);
    });
  }

  void onImplementation(
    Future<Either3<Location, List<Location>, List<LocationLink>>?> Function(
      TextDocumentPositionParams,
    )
    handler,
  ) {
    peer.registerMethod('textDocument/implementation', (
      Parameters params,
    ) async {
      final implementationParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(implementationParams);
    });
  }

  void onReferences(Future<List<Location>> Function(ReferenceParams) handler) {
    peer.registerMethod('textDocument/references', (Parameters params) async {
      final referenceParams = ReferenceParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(referenceParams);
    });
  }

  void onDocumentHighlight(
    Future<List<DocumentHighlight>> Function(TextDocumentPositionParams)
    handler,
  ) {
    peer.registerMethod('textDocument/documentHighlight', (
      Parameters params,
    ) async {
      final highlightParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(highlightParams);
    });
  }

  void onDocumentSymbol(
    Future<List<SymbolInformation>> Function(DocumentSymbolParams) handler,
  ) {
    peer.registerMethod('textDocument/documentSymbol', (
      Parameters params,
    ) async {
      final documentSymbolParams = DocumentSymbolParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(documentSymbolParams);
    });
  }

  void onWorkspaceSymbolResolve(
    Future<SymbolInformation> Function(SymbolInformation) handler,
  ) {
    peer.registerMethod('workspace/symbol/resolve', (Parameters params) async {
      final symbolInformation = SymbolInformation.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(symbolInformation);
    });
  }

  void onCodeAction(
    Future<List<CodeAction>> Function(CodeActionParams) handler,
  ) {
    peer.registerMethod('textDocument/codeAction', (Parameters params) async {
      final codeActionParams = CodeActionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(codeActionParams);
    });
  }

  void onCodeActionResolve(Future<CodeAction> Function(CodeAction) handler) {
    peer.registerMethod('codeAction/resolve', (Parameters params) async {
      final codeAction = CodeAction.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(codeAction);
    });
  }

  void onCodeLens(Future<List<CodeLens>> Function(CodeLensParams) handler) {
    peer.registerMethod('textDocument/codeLens', (Parameters params) async {
      final codeLensParams = CodeLensParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(codeLensParams);
    });
  }

  void onCodeLensResolve(Future<CodeLens> Function(CodeLens) handler) {
    peer.registerMethod('codeLens/resolve', (Parameters params) async {
      final codeLens = CodeLens.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(codeLens);
    });
  }

  void onDocumentFormatting(
    Future<List<TextEdit>> Function(DocumentFormattingParams) handler,
  ) {
    peer.registerMethod('textDocument/formatting', (Parameters params) async {
      final formatParams = DocumentFormattingParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(formatParams);
    });
  }

  void onDocumentRangeFormatting(
    Future<List<TextEdit>> Function(DocumentRangeFormattingParams) handler,
  ) {
    peer.registerMethod('textDocument/rangeFormatting', (
      Parameters params,
    ) async {
      final formatParams = DocumentRangeFormattingParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(formatParams);
    });
  }

  void onDocumentOnTypeFormatting(
    Future<List<TextEdit>> Function(DocumentOnTypeFormattingParams) handler,
  ) {
    peer.registerMethod('textDocument/onTypeFormatting', (
      Parameters params,
    ) async {
      final formatParams = DocumentOnTypeFormattingParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(formatParams);
    });
  }

  void onRenameRequest(Future<WorkspaceEdit> Function(RenameParams) handler) {
    peer.registerMethod('textDocument/rename', (Parameters params) async {
      final renameParams = RenameParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(renameParams);
    });
  }

  void onPrepareRename(
    Future<Either2<Range, PrepareRenameResult>> Function(
      TextDocumentPositionParams,
    )
    handler,
  ) {
    peer.registerMethod('textDocument/prepareRename', (
      Parameters params,
    ) async {
      final prepareParams = TextDocumentPositionParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(prepareParams);
    });
  }

  void onDocumentLinks(
    Future<List<DocumentLink>> Function(DocumentLinkParams) handler,
  ) {
    peer.registerMethod('textDocument/documentLink', (Parameters params) async {
      final documentLinkParams = DocumentLinkParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(documentLinkParams);
    });
  }

  void onDocumentLinkResolve(
    Future<DocumentLink> Function(DocumentLink) handler,
  ) {
    peer.registerMethod('documentLink/resolve', (Parameters params) async {
      final documentLink = DocumentLink.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(documentLink);
    });
  }

  void onDocumentColor(
    Future<List<ColorInformation>> Function(ColorPresentationParams) handler,
  ) {
    peer.registerMethod('textDocument/documentColor', (
      Parameters params,
    ) async {
      final colorParams = ColorPresentationParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(colorParams);
    });
  }

  void onColorPresentation(
    Future<List<ColorPresentation>> Function(ColorPresentationParams) handler,
  ) {
    peer.registerMethod('textDocument/colorPresentation', (
      Parameters params,
    ) async {
      final colorParams = ColorPresentationParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(colorParams);
    });
  }

  void onFoldingRanges(
    Future<List<FoldingRange>> Function(FoldingRangeParams) handler,
  ) {
    peer.registerMethod('textDocument/foldingRange', (Parameters params) async {
      final foldingParams = FoldingRangeParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(foldingParams);
    });
  }

  void onSelectionRanges(
    Future<List<SelectionRange>> Function(SelectionRangeParams) handler,
  ) {
    peer.registerMethod('textDocument/selectionRange', (
      Parameters params,
    ) async {
      final selectionParams = SelectionRangeParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(selectionParams);
    });
  }

  void onExecuteCommand(
    Future<dynamic> Function(ExecuteCommandParams) handler,
  ) {
    peer.registerMethod('workspace/executeCommand', (Parameters params) async {
      final executeParams = ExecuteCommandParams.fromJson(
        params.value as Map<String, Object?>,
      );
      return handler(executeParams);
    });
  }

  Future<void> dispose() => peer.close();
}
