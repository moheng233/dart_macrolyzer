import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:source_maps/refactor.dart';
import 'package:source_span/source_span.dart';

typedef FileChangeHandler = Future<void> Function(String path);

final class VirtualFile {
  VirtualFile(
    String path,
    String content, {
    required FileChangeHandler onFileChange,
    required OverlayResourceProvider provider,
    required int modificationStamp,
  }) : _source = SourceFile.fromString(content, url: path),
       _result = SourceFile.fromString(content, url: path),
       _path = path,
       _content = content,
       _resultContent = content,
       _onFileChange = onFileChange,
       _provider = provider {
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

  final FileChangeHandler _onFileChange;

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

    _onFileChange(_path);
  }

  void close() {
    _provider.removeOverlay(_path);
  }
}
