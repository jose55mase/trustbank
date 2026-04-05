import 'dart:convert';

import 'package:xml/xml.dart';

import 'package:nitrado_server_manager/shared/models/models.dart';
import 'xml_parser_service.dart';

/// Concrete implementation of [XmlParserService] using the `xml` package.
class XmlParserServiceImpl implements XmlParserService {
  // ---------------------------------------------------------------------------
  // types.xml
  // ---------------------------------------------------------------------------

  @override
  List<DayzType> parseTypes(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final typesRoot = document.rootElement;
    return typesRoot
        .findElements('type')
        .map(_parseSingleType)
        .toList();
  }

  DayzType _parseSingleType(XmlElement el) {
    final flags = el.findElements('flags').first;
    final categoryEls = el.findElements('category');
    final usageEls = el.findElements('usage');
    final valueEls = el.findElements('value');
    final tagEls = el.findElements('tag');

    return DayzType(
      name: el.getAttribute('name')!,
      nominal: int.parse(_textOf(el, 'nominal')),
      lifetime: int.parse(_textOf(el, 'lifetime')),
      restock: int.parse(_textOf(el, 'restock')),
      min: int.parse(_textOf(el, 'min')),
      quantmin: int.parse(_textOf(el, 'quantmin')),
      quantmax: int.parse(_textOf(el, 'quantmax')),
      cost: int.parse(_textOf(el, 'cost')),
      flags: DayzTypeFlags(
        countInCargo: int.parse(flags.getAttribute('count_in_cargo')!),
        countInHoarder: int.parse(flags.getAttribute('count_in_hoarder')!),
        countInMap: int.parse(flags.getAttribute('count_in_map')!),
        countInPlayer: int.parse(flags.getAttribute('count_in_player')!),
        crafted: int.parse(flags.getAttribute('crafted')!),
        deloot: int.parse(flags.getAttribute('deloot')!),
      ),
      category: categoryEls.isEmpty
          ? null
          : categoryEls.first.getAttribute('name'),
      usages: usageEls.map((e) => e.getAttribute('name')!).toList(),
      values: valueEls.map((e) => e.getAttribute('name')!).toList(),
      tags: tagEls.map((e) => e.getAttribute('name')!).toList(),
    );
  }

  @override
  String serializeTypes(List<DayzType> types) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    builder.element('types', nest: () {
      for (final t in types) {
        builder.element('type', nest: () {
          builder.attribute('name', t.name);
          _buildTextElement(builder, 'nominal', t.nominal.toString());
          _buildTextElement(builder, 'lifetime', t.lifetime.toString());
          _buildTextElement(builder, 'restock', t.restock.toString());
          _buildTextElement(builder, 'min', t.min.toString());
          _buildTextElement(builder, 'quantmin', t.quantmin.toString());
          _buildTextElement(builder, 'quantmax', t.quantmax.toString());
          _buildTextElement(builder, 'cost', t.cost.toString());
          builder.element('flags', nest: () {
            builder.attribute('count_in_cargo', t.flags.countInCargo.toString());
            builder.attribute('count_in_hoarder', t.flags.countInHoarder.toString());
            builder.attribute('count_in_map', t.flags.countInMap.toString());
            builder.attribute('count_in_player', t.flags.countInPlayer.toString());
            builder.attribute('crafted', t.flags.crafted.toString());
            builder.attribute('deloot', t.flags.deloot.toString());
          });
          if (t.category != null) {
            builder.element('category', nest: () {
              builder.attribute('name', t.category!);
            });
          }
          for (final usage in t.usages) {
            builder.element('usage', nest: () {
              builder.attribute('name', usage);
            });
          }
          for (final value in t.values) {
            builder.element('value', nest: () {
              builder.attribute('name', value);
            });
          }
          for (final tag in t.tags) {
            builder.element('tag', nest: () {
              builder.attribute('name', tag);
            });
          }
        });
      }
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  // ---------------------------------------------------------------------------
  // globals.xml
  // ---------------------------------------------------------------------------

  @override
  List<GlobalVariable> parseGlobals(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final root = document.rootElement;
    return root.findElements('var').map((el) {
      return GlobalVariable(
        name: el.getAttribute('name')!,
        type: int.parse(el.getAttribute('type')!),
        value: el.getAttribute('value')!,
      );
    }).toList();
  }

  @override
  String serializeGlobals(List<GlobalVariable> globals) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    builder.element('variables', nest: () {
      for (final g in globals) {
        builder.element('var', nest: () {
          builder.attribute('name', g.name);
          builder.attribute('type', g.type.toString());
          builder.attribute('value', g.value);
        });
      }
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  // ---------------------------------------------------------------------------
  // events.xml
  // ---------------------------------------------------------------------------

  @override
  List<SpawnEvent> parseEvents(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final root = document.rootElement;
    return root.findElements('event').map(_parseSingleEvent).toList();
  }

  SpawnEvent _parseSingleEvent(XmlElement el) {
    final flagsEl = el.findElements('flags').first;
    final childrenEl = el.findElements('children');
    final children = <EventChild>[];
    if (childrenEl.isNotEmpty) {
      children.addAll(
        childrenEl.first.findElements('child').map((c) {
          return EventChild(
            type: c.getAttribute('type')!,
            min: int.parse(c.getAttribute('min')!),
            max: int.parse(c.getAttribute('max')!),
            lootmin: int.parse(c.getAttribute('lootmin')!),
            lootmax: int.parse(c.getAttribute('lootmax')!),
          );
        }),
      );
    }

    return SpawnEvent(
      name: el.getAttribute('name')!,
      nominal: int.parse(_textOf(el, 'nominal')),
      min: int.parse(_textOf(el, 'min')),
      max: int.parse(_textOf(el, 'max')),
      lifetime: int.parse(_textOf(el, 'lifetime')),
      restock: int.parse(_textOf(el, 'restock')),
      saferadius: int.parse(_textOf(el, 'saferadius')),
      distanceradius: int.parse(_textOf(el, 'distanceradius')),
      cleanupradius: int.parse(_textOf(el, 'cleanupradius')),
      flags: SpawnEventFlags(
        deletable: int.parse(flagsEl.getAttribute('deletable')!),
        initRandom: int.parse(flagsEl.getAttribute('init_random')!),
        removeDamaged: int.parse(flagsEl.getAttribute('remove_damaged')!),
      ),
      position: _textOf(el, 'position'),
      limit: _textOf(el, 'limit'),
      active: int.parse(_textOf(el, 'active')),
      children: children,
    );
  }

  @override
  String serializeEvents(List<SpawnEvent> events) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    builder.element('events', nest: () {
      for (final e in events) {
        builder.element('event', nest: () {
          builder.attribute('name', e.name);
          _buildTextElement(builder, 'nominal', e.nominal.toString());
          _buildTextElement(builder, 'min', e.min.toString());
          _buildTextElement(builder, 'max', e.max.toString());
          _buildTextElement(builder, 'lifetime', e.lifetime.toString());
          _buildTextElement(builder, 'restock', e.restock.toString());
          _buildTextElement(builder, 'saferadius', e.saferadius.toString());
          _buildTextElement(builder, 'distanceradius', e.distanceradius.toString());
          _buildTextElement(builder, 'cleanupradius', e.cleanupradius.toString());
          builder.element('flags', nest: () {
            builder.attribute('deletable', e.flags.deletable.toString());
            builder.attribute('init_random', e.flags.initRandom.toString());
            builder.attribute('remove_damaged', e.flags.removeDamaged.toString());
          });
          _buildTextElement(builder, 'position', e.position);
          _buildTextElement(builder, 'limit', e.limit);
          _buildTextElement(builder, 'active', e.active.toString());
          if (e.children.isNotEmpty) {
            builder.element('children', nest: () {
              for (final child in e.children) {
                builder.element('child', nest: () {
                  builder.attribute('type', child.type);
                  builder.attribute('min', child.min.toString());
                  builder.attribute('max', child.max.toString());
                  builder.attribute('lootmin', child.lootmin.toString());
                  builder.attribute('lootmax', child.lootmax.toString());
                });
              }
            });
          }
        });
      }
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  @override
  bool isValidXml(String content) {
    try {
      XmlDocument.parse(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool isValidJson(String content) {
    try {
      json.decode(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _textOf(XmlElement parent, String tag) {
    return parent.findElements(tag).first.innerText;
  }

  void _buildTextElement(XmlBuilder builder, String tag, String text) {
    builder.element(tag, nest: () {
      builder.text(text);
    });
  }
}
