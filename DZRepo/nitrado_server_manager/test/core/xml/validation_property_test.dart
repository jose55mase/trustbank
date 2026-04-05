// Feature: nitrado-server-manager, Property 6: Validación de sintaxis XML y JSON
// **Validates: Requirements 5.4, 5.5, 5.6**

import 'dart:convert';

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/core/xml/xml_parser_service_impl.dart';
import 'package:xml/xml.dart';

/// XML-safe content generator (avoids characters that break XML structure).
final _xmlSafeContent = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?-_',
);

/// XML-safe tag name generator (lowercase letters only).
final _xmlTagName = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyz',
);

/// JSON-safe key/value string generator.
final _jsonSafeString = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _',
);

/// Generator for well-formed XML strings: `<tag>content</tag>`.
final _validXmlGen = any.combine2(
  _xmlTagName,
  _xmlSafeContent,
  (String tag, String content) => '<$tag>$content</$tag>',
);

/// Generator for valid JSON object strings: `{"key": "value"}`.
final _validJsonObjectGen = any.combine2(
  _jsonSafeString,
  _jsonSafeString,
  (String key, String value) =>
      '{"${_escapeJson(key)}": "${_escapeJson(value)}"}',
);

/// Generator for valid JSON array strings: `["a", "b"]`.
final _validJsonArrayGen = any.combine2(
  _jsonSafeString,
  _jsonSafeString,
  (String a, String b) => '["${_escapeJson(a)}", "${_escapeJson(b)}"]',
);

/// Generator for random arbitrary strings (likely invalid XML/JSON).
final _arbitraryStringGen = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyz{}[]<>:,"\'\\/ 0123456789!@#\$%^&*()',
);

/// Escape special JSON characters in a string.
String _escapeJson(String s) {
  return s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}

void main() {
  final service = XmlParserServiceImpl();

  // Property: Well-formed XML is accepted by isValidXml
  Glados(_validXmlGen, ExploreConfig(numRuns: 100)).test(
    'isValidXml returns true for any well-formed XML string',
    (String xml) {
      expect(service.isValidXml(xml), isTrue,
          reason: 'Expected valid XML to be accepted: $xml');
    },
  );

  // Property: Valid JSON objects are accepted by isValidJson
  Glados(_validJsonObjectGen, ExploreConfig(numRuns: 100)).test(
    'isValidJson returns true for any valid JSON object string',
    (String jsonStr) {
      expect(service.isValidJson(jsonStr), isTrue,
          reason: 'Expected valid JSON object to be accepted: $jsonStr');
    },
  );

  // Property: Valid JSON arrays are accepted by isValidJson
  Glados(_validJsonArrayGen, ExploreConfig(numRuns: 100)).test(
    'isValidJson returns true for any valid JSON array string',
    (String jsonStr) {
      expect(service.isValidJson(jsonStr), isTrue,
          reason: 'Expected valid JSON array to be accepted: $jsonStr');
    },
  );

  // Property: isValidXml is consistent with XmlDocument.parse —
  // it returns true only when the string is actually parseable XML.
  Glados(_arbitraryStringGen, ExploreConfig(numRuns: 100)).test(
    'isValidXml returns false for random non-XML strings (consistency check)',
    (String s) {
      final result = service.isValidXml(s);
      bool actuallyValid;
      try {
        XmlDocument.parse(s);
        actuallyValid = true;
      } catch (_) {
        actuallyValid = false;
      }
      expect(result, equals(actuallyValid),
          reason: 'isValidXml($s) = $result but actual parse = $actuallyValid');
    },
  );

  // Property: isValidJson is consistent with json.decode —
  // it returns true only when the string is actually parseable JSON.
  Glados(_arbitraryStringGen, ExploreConfig(numRuns: 100)).test(
    'isValidJson returns false for random non-JSON strings (consistency check)',
    (String s) {
      final result = service.isValidJson(s);
      bool actuallyValid;
      try {
        json.decode(s);
        actuallyValid = true;
      } catch (_) {
        actuallyValid = false;
      }
      expect(result, equals(actuallyValid),
          reason:
              'isValidJson($s) = $result but actual parse = $actuallyValid');
    },
  );
}
