import 'dart:io';

import '_lib/format_files.dart';

/// Runs `dart format -l 150 --set-exit-if-changed` on every `.dart` file.
/// Files are passed in chunks to stay under the Windows command-line length
/// limit. Used by CI to enforce formatting.
void main() {
  final files = collectFormatableDartFiles();

  if (files.isEmpty) {
    stderr.writeln('No Dart files found to format.');
    exit(1);
  }

  final failureCodes = <int>[];
  for (final batch in chunkFormatBatches(files)) {
    final result = Process.runSync(
      'dart',
      ['format', '-l', '150', '--set-exit-if-changed', ...batch],
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) failureCodes.add(result.exitCode);
    if (result.exitCode != 0) break;
  }
  exit(failureCodes.isEmpty ? 0 : failureCodes.first);
}
