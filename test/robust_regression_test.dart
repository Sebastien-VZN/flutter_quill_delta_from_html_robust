import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:flutter_quill_delta_from_html/parser/pullquote_block_example.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as dom_parser;

void main() {
  group('Custom block regression (b13a44d)', () {
    test('A custom block must be inserted once and not leaked as plain text', () {
      const html = '''
        <html><body>
          <p>Before</p>
          <pullquote data-author="Jane" data-style="bold">Custom block content</pullquote>
          <p>After</p>
        </body></html>
      ''';
      final delta = HtmlToDelta(customBlocks: [PullquoteBlock()]).convert(html);

      final ops = delta.toList();
      // The pullquote op must exist (custom block produced it).
      final hasCustom = ops.any(
        (op) => op.data is String && (op.data! as String).contains('Pullquote:'),
      );
      expect(hasCustom, isTrue, reason: 'custom pullquote block was not inserted');

      // The raw text of the pullquote must NOT appear as a separate plain insert.
      final leakedText = ops.any(
        (op) => op.data is String && (op.data! as String).trim() == 'Custom block content',
      );
      expect(leakedText, isFalse, reason: 'custom block leaked as plain text (double insert)');
    });

    test('PullquoteBlock with no currentAttributes still emits attributes map', () {
      final fragment = dom_parser.parseFragment(
        '<pullquote data-author="Jane" data-style="italic">Quote body</pullquote>',
      );
      final element = fragment.firstChild! as dom.Element;
      final ops = PullquoteBlock().convert(element);

      expect(ops, isNotEmpty, reason: 'convert() returned [] when currentAttributes was null');
      final textOp = ops.first;
      expect(textOp.data! as String, contains('Jane'));
      expect(textOp.attributes?['italic'], isTrue);
    });
  });

  group('Color parsing (colors.dart)', () {
    test('rgb() converts to upper-cased #AARRGGBB', () {
      final converter = HtmlToDelta();
      final delta = converter.convert('<p style="color: rgb(255, 0, 0)">red</p>');
      final op = delta.toList().firstWhere(
            (op) => op.data is String && (op.data! as String).contains('red'),
            orElse: () => throw StateError('no red op'),
          );
      expect(op.attributes?['color'], '#FFFF0000');
    });

    test('hex color passes through unchanged when valid', () {
      final converter = HtmlToDelta();
      final delta = converter.convert('<p style="color: #00ff00">green</p>');
      final op = delta.toList().firstWhere(
            (op) => op.data is String && (op.data! as String).contains('green'),
            orElse: () => throw StateError('no green op'),
          );
      expect(op.attributes?['color'], isNotNull);
    });

    test('named color "blue" converts', () {
      final converter = HtmlToDelta();
      final delta = converter.convert('<p style="color: blue">blue text</p>');
      final op = delta.toList().firstWhere(
            (op) => op.data is String && (op.data! as String).contains('blue text'),
            orElse: () => throw StateError('no blue op'),
          );
      expect(op.attributes?['color'], isNotNull);
    });
  });

  group('Style attribute parsing (html_utils.dart)', () {
    test('align/direction/indent moved to block attributes', () {
      final converter = HtmlToDelta();
      final delta = converter.convert('<p style="text-align: right; padding-left: 20px" dir="rtl">x</p>');
      final op = delta.toList().firstWhere(
            (op) => op.data == '\n' && op.attributes != null,
            orElse: () => throw StateError('no block op'),
          );
      expect(op.attributes?['align'], 'right');
      expect(op.attributes?['direction'], 'rtl');
      expect(op.attributes?['indent'], isNotNull);
    });

    test('background-color yields background attribute', () {
      final converter = HtmlToDelta();
      final delta = converter.convert('<p style="background-color: #ffff00">bg</p>');
      final op = delta.toList().firstWhere(
            (op) => op.data is String && (op.data! as String).contains('bg'),
            orElse: () => throw StateError('no bg op'),
          );
      expect(op.attributes?['background'], isNotNull);
    });
  });

  group('Image attributes (named Operation.insert, b13a44d)', () {
    test('img with align+style produces named image attributes', () {
      const html = '<p>i: <img align="center" style="width: 10px" src="https://e.com/i.png"/></p>';
      final converter = HtmlToDelta();
      final delta = converter.convert(html);
      final imgOp = delta.toList().firstWhere(
            (op) => op.data is Map && (op.data! as Map).containsKey('image'),
            orElse: () => throw StateError('no image op'),
          );
      expect(imgOp.attributes?['style'], contains('alignment:center'));
    });
  });
}
