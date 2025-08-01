import 'dart:io';

List<String> whereIs(String name) {
  late final ProcessResult result;

  if (Platform.isWindows) {
    // Windows 使用 where 命令
    result = Process.runSync('where', [name], runInShell: true);
  } else {
    // Linux/macOS 使用 which 命令
    result = Process.runSync('which', [name]);
  }

  if (result.exitCode != 0) {
    return [];
  }

  return (result.stdout as String)
      .trim()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
