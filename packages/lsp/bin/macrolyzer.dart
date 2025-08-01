import 'dart:convert';
import 'dart:io';

import 'package:dart_macrolyzer_lsp/server.dart';
import 'package:dart_macrolyzer_lsp_protocol/lsp_client.dart';
import 'package:dart_macrolyzer_lsp_protocol/lsp_server.dart';

const name = "macrolyzer";
const version = "0.0.1";

void main(List<String> args) async {
  try {
    final server = LspServer(stdin, stdout);
    final console = server.console;

    final dartPath = whereIs("dart").first;

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

    final client = LspClient(lspProcess.stdout, lspProcess.stdin);

    // 设置请求转发：从 LSP 客户端（如 VS Code）到分析服务器
    _setupGenericForwarding(server, client);

    lspProcess.exitCode.then((exitCode) {
      stderr.writeln('Analysis server exited with code: $exitCode');
      exit(exitCode);
    });

    // 启动监听
    Future.wait([server.listen(), client.listen()]);
  } catch (e, stackTrace) {
    stderr.writeln('Error in macrolyzer: $e');
    stderr.writeln('Stack trace: $stackTrace');
    exit(1);
  }
}

/// 设置通用转发以处理任何未明确处理的方法
void _setupGenericForwarding(LspServer server, LspClient client) {
  // 使用底层 peer 设置通用的请求转发
  // 这会捕获所有未被明确注册的方法

  // 服务器端：转发所有请求到客户端
  server.peer.registerFallback((parameters) async {
    try {
      // 获取方法名
      final method = parameters.method;

      // 转发请求到客户端
      final response = await client.peer.sendRequest(method, parameters.value);

      return response;
    } catch (e) {
      rethrow;
    }
  });

  client.onNotification(r"$/progress", (param) async {
    server.sendNotification(r"$/progress", param);
  });

  // 客户端：转发所有通知到服务器
  client.peer.registerFallback((parameters) async {
    try {
      final method = parameters.method;

      // 转发通知到服务器
      server.peer.sendRequest(method, parameters.value);
    } catch (e) {}
  });
}
