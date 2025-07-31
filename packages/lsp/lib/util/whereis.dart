import 'dart:io';

Future<List<String>> whereIs(String name) async {
  late final ProcessResult result;

  if (Platform.isWindows) {
    // Windows 使用 where 命令
    result = await Process.run('where', [name], runInShell: true);
  } else {
    // Linux/macOS 使用 which 命令
    result = await Process.run('which', [name]);
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
