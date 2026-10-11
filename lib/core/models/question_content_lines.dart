class QuestionContentLines {
  const QuestionContentLines._();

  static List<String> parse(String source) {
    if (source.isEmpty) return [''];

    final result = <String>[];
    final current = StringBuffer();
    var environmentDepth = 0;
    var inDisplayMath = false;

    for (final line in source.split('\n')) {
      if (current.isNotEmpty) current.writeln();
      current.write(line);

      environmentDepth += RegExp(r'\\begin\{[^}]+\}').allMatches(line).length;
      environmentDepth -= RegExp(r'\\end\{[^}]+\}').allMatches(line).length;
      environmentDepth = environmentDepth.clamp(0, 1 << 20);

      final displayMarkers = RegExp(r'(?<!\\)\$\$').allMatches(line).length;
      if (displayMarkers.isOdd) inDisplayMath = !inDisplayMath;

      if (environmentDepth == 0 && !inDisplayMath) {
        result.add(current.toString());
        current.clear();
      }
    }

    if (current.isNotEmpty) result.add(current.toString());
    return result.isEmpty ? [''] : result;
  }

  static String compile(Iterable<String> lines) => lines.join('\n');
}
