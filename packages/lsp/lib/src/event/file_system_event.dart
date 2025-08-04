sealed class FileSystemEventBase {
  FileSystemEventBase({required this.path});

  final String path;
}

final class FileSystemOpenEvent extends FileSystemEventBase {
  FileSystemOpenEvent({
    required super.path,
    required this.content,
    required this.modificationStamp,
  });

  final String content;
  final int modificationStamp;
}

final class FileSystemCompleteChangeEvent extends FileSystemEventBase {
  FileSystemCompleteChangeEvent({
    required super.path,
    required this.content,
    required this.modificationStamp,
  });

  final String content;
  final int modificationStamp;
}

final class FileSystemCloseEvent extends FileSystemEventBase {
  FileSystemCloseEvent({required super.path});
}

final class FileSystemSaveEvent extends FileSystemEventBase {
  FileSystemSaveEvent({required super.path});
}
