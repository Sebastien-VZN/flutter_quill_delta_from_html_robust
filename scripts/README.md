# Scripts

All the scripts must be run from the root project folder and not inside the
scripts folder.

## Scripts

- `format_check.dart` — CI formatting gate
  (`dart format -l 150 --set-exit-if-changed`).
- `before_push.dart` — local pre-push guard: analyze → test →
  `dart fix --apply` → format → format check.
- `_lib/format_files.dart` — shared helpers: collects formatable `.dart`
  files (excluding `build/`, `.dart_tool/`) and chunks them to stay under the
  Windows command-line length limit.

## Example

```shell
dart ./scripts/format_check.dart
```

## Git hook (pre-push)

A `pre-push` hook is committed under `.githooks/` so contributors get the same
guard locally as in CI. To enable it once after cloning:

```shell
git config core.hooksPath .githooks
```

Then every `git push` will run `dart ./scripts/before_push.dart` and block the
push on any failure (analysis, tests, or formatting).