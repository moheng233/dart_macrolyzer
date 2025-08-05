import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:source_span/source_span.dart';

import 'event/file_system_event.dart';

typedef FileChangeHandler = Future<void> Function(String path, String content);

final class VirtualFile {
  VirtualFile(
    String path,
    String content, {
    required StreamController<FileSystemEventBase> event,
    required OverlayResourceProvider provider,
    required int modificationStamp,
    required AnalysisContextCollection analysis,
  }) : _source = SourceFile.fromString(content, url: path),
       _result = SourceFile.fromString(content, url: path),
       _path = path,
       _content = content,
       _resultContent = content,
       _event = event,
       _provider = provider,
       _analysis = analysis {
    _provider.setOverlay(
      path,
      content: content,
      modificationStamp: modificationStamp,
    );
  }

  final OverlayResourceProvider _provider;

  SourceFile _source;
  SourceFile _result;

  final String _path;
  String _content;

  String _resultContent;

  final AnalysisContextCollection _analysis;

  final StreamController<FileSystemEventBase> _event;

  SourceFile get source => _source;
  String get content => _content;

  void change(String content, int modificationStamp) {
    _source = SourceFile.fromString(content, url: _path);
    _content = content;
    _provider.setOverlay(
      _path,
      content: content,
      modificationStamp: modificationStamp,
    );

    _event.add(
      FileSystemCompleteChangeEvent(
        path: _path,
        content: content,
        modificationStamp: modificationStamp,
      ),
    );
  }

  void close() {
    _provider.removeOverlay(_path);

    _event.add(FileSystemCloseEvent(path: _path));
  }
}
