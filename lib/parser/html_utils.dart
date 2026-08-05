import 'package:flutter_quill_delta_from_html/parser/colors.dart';
import 'package:flutter_quill_delta_from_html/parser/font_size_parser.dart';
import 'package:flutter_quill_delta_from_html/parser/indent_parser.dart';
import 'package:flutter_quill_delta_from_html/parser/line_height_parser.dart';
import 'package:flutter_quill_delta_from_html/parser/typedef/typedefs.dart';

/// Checks if the given [tag] corresponds to an inline HTML element.
///
/// Inline elements include: 'i', 'em', 'u', 'ins', 's', 'del', 'b', 'strong', 'sub', 'sup'.
///
/// Parameters:
/// - [tag]: The HTML tag name to check.
///
/// Returns:
/// `true` if [tag] is an inline element, `false` otherwise.
bool isInline(String tag) {
  return ["i", "em", "u", "ins", "s", "del", "b", "strong", "sub", "sup"].contains(tag);
}

/// Parses a CSS style attribute string into Delta attributes.
///
/// Converts CSS styles (like 'text-align', 'color', 'font-size', etc.) from [style]
/// into Quill Delta attributes suitable for rich text formatting.
///
/// Parameters:
/// - [style]: The CSS style attribute string to parse.
///
/// Returns:
/// A map of Delta attributes derived from the CSS styles.
///
/// Example:
/// ```dart
/// final style = 'color: #ff0000; font-size: 16px;';
/// print(parseStyleAttribute(style)); // Output: {'color': '#ff0000', 'size': '16'}
/// ```
Map<String, dynamic> parseStyleAttribute(
  String tag,
  String style, {
  CSSVarible? onDetectLineheightCssVariable,
}) {
  final attributes = <String, dynamic>{};
  if (style.isEmpty) return attributes;

  final styles = style.split(';');
  double? fontSize;

  for (final style in styles) {
    final parts = style.split(':');
    if (parts.length == 2) {
      final key = parts[0].trim();
      final value = parts[1].trim();

      switch (key) {
        case 'text-align':
          attributes['align'] = value;
        case 'color':
          final color = validateAndGetColor(value);
          if (color != null) {
            attributes['color'] = color;
          }
        case 'background-color':
          final color = validateAndGetColor(value);
          if (color != null) {
            attributes['background'] = color;
          }
        case 'padding-left' || 'padding-right':
          final indentation = parseToIndent(value);
          if (indentation != 0) {
            attributes['indent'] = indentation;
          }
        case 'font-size':
          String? sizeToPass;

          // Handle default values used by [vsc_quill_delta_to_html]
          if (value == '0.75em') {
            fontSize = 10;
            sizeToPass = 'small';
          } else if (value == '1.5em') {
            fontSize = 18;
            sizeToPass = 'large';
          } else if (value == '2.5em') {
            fontSize = 22;
            sizeToPass = 'huge';
          } else {
            try {
              final size = parseSizeToPx(value);
              if (size <= 10) {
                fontSize = 10;
                sizeToPass = 'small';
              } else {
                fontSize = size.floorToDouble();
                sizeToPass = '${size.floor()}';
              }
            } on UnsupportedError {
              //ignore error
              break;
            }
          }
          attributes['size'] = sizeToPass;
        case 'font-family':
          attributes['font'] = value;
        case 'line-height':
          double? lineHeight;
          if (onDetectLineheightCssVariable != null) {
            lineHeight = onDetectLineheightCssVariable(tag, key, value);
          }

          if (lineHeight == null) {
            try {
              lineHeight = parseLineHeight(value, fontSize: fontSize ?? 16.0);
            } catch (e) {
              //ignore error (i.e. 'line-height: inherit;')
            }
          }

          if (lineHeight != null) {
            attributes['line-height'] = lineHeight;
          }
        case 'font-style':
          if (value.contains('italic')) {
            attributes['italic'] = true;
          }
        case 'text-decoration':
          if (value.contains('underline')) {
            attributes['underline'] = true;
          }
          if (value.contains('line-through')) {
            attributes['strike'] = true;
          }
        case 'font-weight':
          if (value == 'bold') {
            attributes['bold'] = true;
          }
        default:
          break;
      }
    } else {
      switch (style) {
        case 'justify' || 'center' || 'left' || 'right':
          attributes['align'] = style;
        case 'rtl':
          attributes['direction'] = 'rtl';
        case 'true' || 'false':
          // Treat as check list
          if (style == 'true') {
            attributes['list'] = 'checked';
          } else {
            attributes['list'] = 'unchecked';
          }
        default:
          break;
      }
    }
  }

  return attributes;
}

/// Parses a CSS `<img>` style attribute string into Delta attributes.
///
/// Converts CSS styles (like 'width', 'height', 'margin') from [style]
/// into Quill Delta attributes suitable for image rich text formatting.
///
/// Parameters:
/// - [style]: The CSS style attribute string to parse.
///
/// Returns:
/// A map of Delta attributes derived from the CSS styles.
///
/// Example:
/// ```dart
/// final style = 'width: 50px; height: 250px;';
/// print(parseStyleAttribute(style)); // Output: {'width': '50px', 'height': '250px'}
/// ```
Map<String, dynamic> parseImageStyleAttribute(String style, String align) {
  final attributes = <String, dynamic>{};

  final styles = style.split(';');
  for (final style in styles) {
    final parts = style.split(':');
    if (parts.length == 2) {
      final key = parts[0].trim();
      final value = parts[1].trim();

      switch (key) {
        case 'width':
          attributes['width'] = value;
        case 'height':
          attributes['height'] = value;
        case 'margin':
          attributes['margin'] = value;
        default:
          // Ignore other styles
          break;
      }
    }
  }

  if (align.isNotEmpty) attributes['alignment'] = align;
  return attributes;
}
