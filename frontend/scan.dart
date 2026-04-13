import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  final regexps = [
    RegExp(r"Text\(\s*'([^']+)'"),
    RegExp(r"Text\(\s*\'([^\']+)\'"),
    RegExp(r"hintText:\s*'([^']+)'"),
    RegExp(r"label:\s*'([^']+)'"),
    RegExp(r"label:\s*Text\(\s*'([^']+)'"),
    RegExp(r"title:\s*Text\(\s*'([^']+)'"),
    RegExp(r"SnackBar\(content:\s*Text\(\s*'([^']+)'"),
    RegExp(r"errorMessage\s*=\s*'([^']+)'"),
  ];

  for (final file in files) {
    if (file.path.contains('language_provider.dart')) continue;
    
    final lines = file.readAsLinesSync();
    int lineNumber = 1;
    for (var line in lines) {
      // Ignore lines that already have localization or are comments
      if (line.contains('context.tr(') || line.trim().startsWith('//')) {
        lineNumber++;
        continue;
      }
      for (var reg in regexps) {
        final match = reg.firstMatch(line);
        if (match != null) {
          final str = match.group(1)!;
          // Ignore strings that look like map keys or variables or empty or symbols
          if (!str.contains(r'$') && str.trim().isNotEmpty && !str.startsWith('http')) {
             print('${file.path}|$lineNumber|$str');
          }
        }
      }
      lineNumber++;
    }
  }
}
