import 'dart:async';
import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:dart_macrolyzer_lsp_protocol/lsp_client.dart';
import 'package:path/path.dart';
import 'package:source_span/source_span.dart';

import 'event/file_system_event.dart';
import 'virtual_file.dart';

final class MacrolyzerFileSystem implements ResourceProvider {
  MacrolyzerFileSystem(ResourceProvider baseProvider)
    : _provider = OverlayResourceProvider(baseProvider);

  final HashMap<String, VirtualFile> _fileMap = HashMap();

  final OverlayResourceProvider _provider;

  final StreamController<FileSystemEventBase> _upstreamEvent =
      StreamController();
  final StreamController<FileSystemEventBase> _downstreamEvent =
      StreamController();

  /// 送至上行服务器的文件系统事件
  Stream<FileSystemEventBase> get upstreamEvent => _upstreamEvent.stream;

  /// 送至下行服务器的文件系统事件
  Stream<FileSystemEventBase> get downstreamEvent => _downstreamEvent.stream;

  @override
  Context get pathContext => _provider.pathContext;

  @override
  File getFile(String path) => _provider.getFile(path);

  @override
  Folder getFolder(String path) => _provider.getFolder(path);

  @override
  Link getLink(String path) => _provider.getLink(path);

  @override
  Resource getResource(String path) => _provider.getResource(path);

  @override
  Folder? getStateLocation(String pluginId) =>
      _provider.getStateLocation(pluginId);

  VirtualFile getVirtaulFile(String path) => _fileMap[path]!;

  VirtualFile open(String url, String content, int modificationStamp) {
    final file = VirtualFile(
      url,
      content,
      provider: _provider,
      onFileChange: _onFileChange,
      modificationStamp: modificationStamp,
    );

    _fileMap[url] = file;

    return file;
  }

  Future<void> _onFileChange(String path) async {}
}
