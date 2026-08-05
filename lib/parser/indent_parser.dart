/// Converts a CSS `padding-left` || 'padding-right' value to a standardized indentation level.
///
/// The method supports various units such as `px`, `pt`, `pc`, `em`, `rem`, and `%`.
/// The conversion is based on the following assumptions:
/// - `16px` equals 1 indentation level
/// - `12pt` equals 1 indentation level
/// - `1pc` equals 1 indentation level
/// - `1em` or `1rem` equals 1 indentation level
/// - `100%` equals 1 indentation level
///
/// If the unit is not recognized, the indentation level defaults to 0.
///
/// [value] The CSS `padding-left` value as a string (e.g., "32px", "2em").
///
/// Returns the corresponding indentation level as an integer.
int parseToIndent(String value) {
  // Extract numeric part from the value and parse it to double
  var indentValue = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

  // Extract the unit part from the value
  final unit = value.replaceAll(RegExp(r'[\d.]'), '').trim();

  // Convert the value to an indentation level based on the unit
  switch (unit) {
    case 'px':
      indentValue /= 16; // Assume 16px = 1 indent level
    case 'pt':
      indentValue /= 12; // Assume 12pt = 1 indent level
    case 'pc':
      indentValue *= 1; // 1pc = 1 indent level
    case 'em':
    case 'rem':
      indentValue *= 1; // 1em or 1rem = 1 indent level
    case '%':
      indentValue /= 100; // Assume 100% = 1 indent level
    default:
      indentValue = 0; // If unit is not recognized, set indent level to 0
  }
  // Round to the nearest whole number for the indent level
  final indentLevel = indentValue.round();
  return indentLevel < 1
      ? 0
      : indentLevel > 5
          ? 5
          : indentLevel;
}
