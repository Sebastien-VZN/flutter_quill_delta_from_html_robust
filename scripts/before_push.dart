import 'dart:io';

import 'package:flutter/foundation.dart';

import '_lib/format_files.dart';

/// Local pre-push guard. Mirrors the CI pipeline so a push is blocked before
/// it reaches GitHub if formatting, analysis, or tests would fail. Run from
/// the repository root, e.g. via the `.githooks/pre-push` hook.
void main() async {
  await runCommand('flutter', ['analyze']);

  await runCommand('flutter', ['test']);

  await runCommand('dart', ['fix', '--apply']);

  // Format the repository, then assert it is fully formatted (mirrors the CI
  // `format_check.dart` check). Files are passed in chunks to stay under the
  // Windows command-line length limit.
  final files = collectFormatableDartFiles();
  if (files.isEmpty) {
    stderr.writeln('No Dart files found to format.');
    exit(1);
  }
  for (final batch in chunkFormatBatches(files)) {
    await runCommand('dart', ['format', '-l', '150', ...batch]);
  }
  for (final batch in chunkFormatBatches(files)) {
    await runCommand(
      'dart',
      ['format', '-l', '150', '--set-exit-if-changed', ...batch],
    );
  }

  debugPrint('');
  debugPrint('Checks completed.');
}

Future<void> runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  debugPrint(
    "Running '$executable ${arguments.join(' ')}' in directory "
    "'${workingDirectory ?? 'root'}'...",
  );
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  debugPrint(result.stdout.toString());
  debugPrint(result.stderr.toString());
  if (result.exitCode != 0) {
    stderr.writeln(
      "Command '$executable ${arguments.join(' ')}' failed with exit code "
      '${result.exitCode}.',
    );
    exit(result.exitCode);
  }
}
