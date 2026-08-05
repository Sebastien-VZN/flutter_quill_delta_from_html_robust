import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_from_html/parser/extensions/node_ext.dart';
import 'package:flutter_quill_delta_from_html/parser/html_to_operation.dart';
import 'package:flutter_quill_delta_from_html/parser/html_utils.dart';
import 'package:flutter_quill_delta_from_html/parser/node_processor.dart';
import 'package:flutter_quill_delta_from_html/parser/typedef/typedefs.dart';
import 'package:html/dom.dart' as dom;

/// Default implementation of `HtmlOperations` for converting common HTML to Delta operations.
///
/// This class provides default implementations for converting common HTML elements
/// like paragraphs, headers, lists, links, images, videos, code blocks, and blockquotes
/// into Delta operations.
class DefaultHtmlToOperations extends HtmlOperations {
  DefaultHtmlToOperations(
    this.onDetectLineheightCssVariable,
  );
  final CSSVarible? onDetectLineheightCssVariable;

  @override
  List<Operation> paragraphToOp(dom.Element element) {
    final delta = Delta();
    final attributes = element.attributes;
    final inlineAttributes = <String, dynamic>{};
    final blockAttributes = <String, dynamic>{};
    // Process the style attribute
    if (attributes.containsKey('style') || attributes.containsKey('align') || attributes.containsKey('dir')) {
      final style = attributes['style'] ?? '';
      final styles2 = attributes['align'];
      final styles3 = attributes['dir'];
      final styleAttributes = parseStyleAttribute(
        element.localName!,
        style,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      final alignAttribute = parseStyleAttribute(
        element.localName!,
        styles2 ?? '',
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      final dirAttribute = parseStyleAttribute(
        element.localName!,
        styles3 ?? '',
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      styleAttributes.addAll({...alignAttribute, ...dirAttribute});
      if (styleAttributes.containsKey('align') || styleAttributes.containsKey('direction') || styleAttributes.containsKey('indent')) {
        blockAttributes['align'] = styleAttributes['align'];
        blockAttributes['direction'] = styleAttributes['direction'];
        blockAttributes['indent'] = styleAttributes['indent'];
        styleAttributes
          ..remove('align')
          ..remove('direction')
          ..remove('indent');
      }
      inlineAttributes.addAll(styleAttributes);
    }
    final nodes = element.nodes;
    //this store into all nodes into a paragraph, and
    //ensure getting all attributes or tags into a paragraph
    for (final node in nodes) {
      processNode(
        node,
        inlineAttributes,
        delta,
        addSpanAttrs: true,
        customBlocks: customBlocks,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }
    if (blockAttributes.isNotEmpty) {
      blockAttributes.removeWhere((key, value) => value == null);
      delta.insert('\n', attributes: blockAttributes);
    }

    return delta.toList();
  }

  @override
  List<Operation> spanToOp(dom.Element element) {
    final delta = Delta();
    final attributes = element.attributes;
    final inlineAttributes = <String, dynamic>{};
    // Process the style attribute
    if (attributes.containsKey('style')) {
      final style = attributes['style'];
      final styleAttributes = parseStyleAttribute(
        element.localName!,
        style ?? '',
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      if (styleAttributes.containsKey('align')) {
        styleAttributes.remove('align');
      }
      inlineAttributes.addAll(styleAttributes);
    }
    final nodes = element.nodes;
    //this store into all nodes into a paragraph, and
    //ensure getting all attributes or tags into a paragraph
    for (final node in nodes) {
      processNode(
        node,
        inlineAttributes,
        delta,
        customBlocks: customBlocks,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }

    return delta.toList();
  }

  @override
  List<Operation> linkToOp(dom.Element element) {
    final delta = Delta();
    final attributes = <String, dynamic>{};

    if (element.attributes.containsKey('href')) {
      attributes['link'] = element.attributes['href'];
    }

    final nodes = element.nodes;
    for (final node in nodes) {
      processNode(
        node,
        attributes,
        delta,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }

    return delta.toList();
  }

  @override
  List<Operation> headerToOp(dom.Element element) {
    final delta = Delta();
    final attributes = <String, dynamic>{};
    final blockAttributes = <String, dynamic>{};

    if (element.attributes.containsKey('style') || element.attributes.containsKey('align') || element.attributes.containsKey('dir')) {
      final style = element.getSafeAttribute('style');
      final styles2 = element.getSafeAttribute('align');
      final styles3 = element.getSafeAttribute('dir');
      final styleAttributes = parseStyleAttribute(
        element.localName!,
        style,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      final alignAttribute = parseStyleAttribute(
        element.localName!,
        styles2,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      final dirAttribute = parseStyleAttribute(
        element.localName!,
        styles3,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      styleAttributes.addAll({...alignAttribute, ...dirAttribute});
      if (styleAttributes.containsKey('align') || styleAttributes.containsKey('direction') || styleAttributes.containsKey('indent')) {
        blockAttributes['align'] = styleAttributes['align'];
        blockAttributes['direction'] = styleAttributes['direction'];
        blockAttributes['indent'] = styleAttributes['indent'];
        styleAttributes
          ..remove('align')
          ..remove('direction')
          ..remove('indent');
      }
      attributes.addAll(styleAttributes);
    }

    final headerLevel = element.localName ?? 'h1';
    blockAttributes['header'] = int.parse(headerLevel.substring(1));

    final nodes = element.nodes;
    for (final node in nodes) {
      processNode(
        node,
        attributes,
        delta,
        addSpanAttrs: true,
        removeTheseAttributesFromSpan: ['size'],
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }
    // Ensure a newline is added at the end of the header with the correct attributes
    if (blockAttributes.isNotEmpty) {
      blockAttributes.removeWhere((key, value) => value == null);
      delta.insert('\n', attributes: blockAttributes);
    }
    return delta.toList();
  }

  @override
  List<Operation> divToOp(dom.Element element) {
    final delta = Delta();
    final attributes = <String, dynamic>{};

    if (element.attributes.containsKey('style')) {
      final style = element.attributes['style']!;
      final styleAttributes = parseStyleAttribute(
        element.localName!,
        style,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      attributes.addAll(styleAttributes);
    }
    for (final node in element.nodes) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        delta.insert(node.text);
      } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
        final ops = resolveCurrentElement(node as dom.Element);
        for (final op in ops) {
          delta.insert(op.data, attributes: op.attributes);
        }
        if (node.isParagraph) {
          delta.insert('\n');
        }
      }
    }

    return delta.toList();
  }

  @override
  List<Operation> listToOp(dom.Element element, [int indentLevel = 0]) {
    final delta = Delta();
    final tagName = element.localName ?? 'ul';
    final attributes = <String, dynamic>{};
    final items = element.children.where((child) => child.localName == 'li').toList();

    if (tagName == 'ul') {
      attributes['list'] = 'bullet';
    } else if (tagName == 'ol') {
      attributes['list'] = 'ordered';
    }
    final checkbox = element.querySelector('input[type="checkbox"]');
    if (checkbox != null) {
      // If a checkbox is found, determine if it's checked
      final isChecked = checkbox.attributes.containsKey('checked');
      if (isChecked) {
        attributes['list'] = 'checked';
      } else {
        attributes['list'] = 'unchecked';
      }
    }
    var ignoreBlockAttributesInsertion = false;
    for (final item in items) {
      ignoreBlockAttributesInsertion = false;
      var indent = indentLevel;
      if (checkbox == null) {
        final dataChecked = item.getSafeAttribute('data-checked');
        final blockAttrs = parseStyleAttribute(
          element.localName!,
          dataChecked,
          onDetectLineheightCssVariable: onDetectLineheightCssVariable,
        );
        final isCheckList = item.localName == 'li' && blockAttrs.isNotEmpty && blockAttrs.containsKey('list');
        if (isCheckList) {
          attributes['list'] = blockAttrs['list'];
        }
      }
      // force always the max level indentation to be five

      var result = indentLevel;
      if (indentLevel > 5) {
        result = 5;
      }
      if (indentLevel > 0) attributes['indent'] = result;
      for (final node in item.nodes) {
        if (node.nodeType == dom.Node.TEXT_NODE) {
          delta.insert(node.text);
        } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
          final element = node as dom.Element;
          final ops = <Operation>[];
          // if found, a element list, into another list, then this is a nested and must insert first the block attributes
          // to separate the current element from the nested list elements
          if (element.isList) {
            indent++;
            ignoreBlockAttributesInsertion = true;
            delta.insert('\n', attributes: attributes);
          }
          ops.addAll(resolveCurrentElement(element, indent));
          for (final op in ops) {
            delta.insert(op.data, attributes: op.attributes);
          }
        }
      }
      if (!ignoreBlockAttributesInsertion) {
        delta.insert('\n', attributes: attributes);
      }
    }

    return delta.toList();
  }

  @override
  List<Operation> imgToOp(dom.Element element) {
    final src = element.getSafeAttribute('src');
    final styles = element.getSafeAttribute('style');
    final attributes = parseImageStyleAttribute(
      styles,
      element.getSafeAttribute('align'),
    );
    if (src.isNotEmpty) {
      return [
        Operation.insert(
          {'image': src},
          attributes: styles.isEmpty
              ? null
              : {
                  'style': attributes.entries.map((entry) => '${entry.key}:${entry.value}').toList().join(';'),
                },
        ),
      ];
    }
    return [];
  }

  @override
  List<Operation> videoToOp(dom.Element element) {
    final src = element.getAttribute('src');
    final sourceSrc = element.nodes.where((node) => node.nodeType == dom.Node.ELEMENT_NODE).firstOrNull?.attributes['src'];
    if (src != null && src.isNotEmpty || sourceSrc != null && sourceSrc.isNotEmpty) {
      return [
        Operation.insert({'video': src ?? sourceSrc}),
      ];
    }
    return [];
  }

  @override
  List<Operation> blockquoteToOp(dom.Element element) {
    final delta = Delta();
    final blockAttributes = <String, dynamic>{'blockquote': true};

    for (final node in element.nodes) {
      processNode(
        node,
        {},
        delta,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }

    delta.insert('\n', attributes: blockAttributes);

    return delta.toList();
  }

  @override
  List<Operation> codeblockToOp(dom.Element element) {
    final delta = Delta();
    final blockAttributes = <String, dynamic>{'code-block': true};

    for (final node in element.nodes) {
      processNode(
        node,
        {},
        delta,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }

    delta.insert('\n', attributes: blockAttributes);

    return delta.toList();
  }

  @override
  List<Operation> brToOp(dom.Element element) {
    return [Operation.insert('\n')];
  }

  @override
  List<Operation> tableToOp(
    dom.Element element, [
    bool transformTableAsEmbed = false,
  ]) {
    final table = <String, dynamic>{
      'headers': <String, dynamic>{},
      'rows': <String, dynamic>{},
    };
    final tBody = element.children.firstOrNull;
    if (transformTableAsEmbed) {
      var rowIndex = 0;
      for (final node in (tBody ?? element).nodes) {
        final ops = <Operation>[];
        final isHeaderRow = node is dom.Element && node.localName == 'tr' && node.children.isNotEmpty && node.children.firstOrNull?.localName == 'th';
        if (isHeaderRow) {
          var index = 0;
          final header = <String, dynamic>{};
          for (final hNode in node.children) {
            if (hNode.text.isNotEmpty) {
              header['$index'] = hNode.text;
              index++;
            }
          }
          if (header.isNotEmpty) {
            table['headers'] = <String, dynamic>{
              ...header,
            };
          }
          continue;
        }
        if (node is! dom.Element && node.text != null) {
          ops.add(Operation.insert(node.text));
          table['rows']['$rowIndex'] = <String>[
            ...ops.map<String>(
              (
                e,
              ) =>
                  e.data!.toString(),
            ),
          ];
          rowIndex++;
        } else {
          final nodeEl = node as dom.Element;
          if (nodeEl.localName == 'tr') {
            for (final cellNodes in nodeEl.children) {
              final cellOps = cellNodes.localName == 'td' ? paragraphToOp(cellNodes) : divToOp(cellNodes);
              if (table['rows']['$rowIndex'] != null) {
                table['rows']['$rowIndex'].addAll(
                  cellOps
                      .map<String>(
                        (
                          e,
                        ) =>
                            e.data!.toString(),
                      )
                      .toList(),
                );
                continue;
              }
              table['rows']['$rowIndex'] = <String>[
                ...cellOps.map<String>(
                  (
                    e,
                  ) =>
                      e.data!.toString(),
                ),
              ];
            }
            rowIndex++;
          }
        }
      }
      return <Operation>[
        Operation.insert(<String, Map<String, dynamic>>{
          'table': table,
        }),
      ];
    }

    final ops = <Operation>[];
    for (final node in element.nodes) {
      if (node.nodeType == dom.Node.ELEMENT_NODE) {
        final element = node as dom.Element;
        if (element.localName == 'td') {
          ops.addAll(paragraphToOp(element));
        } else {
          ops.addAll(divToOp(element));
        }
      }
    }

    return ops;
  }
}
