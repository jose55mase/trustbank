// Feature: nitrado-server-manager, Property 10: Round trip de globals.xml
// **Validates: Requirements 7.4**

import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/core/xml/xml_parser_service_impl.dart';
import 'package:nitrado_server_manager/shared/models/models.dart';

/// XML-safe non-empty string generator (avoids <, >, &, ", ')
final _xmlSafeName = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_',
);

/// Generator for GlobalVariable type: 0 (integer) or 1 (decimal).
final _typeGen = any.choose([0, 1]);

/// Generator for a single GlobalVariable.
final _globalVariableGen = any.combine3(
  _xmlSafeName,
  _typeGen,
  _xmlSafeName,
  (String name, int type, String value) => GlobalVariable(
    name: name,
    type: type,
    value: value,
  ),
);

/// Generator for a list of GlobalVariable (0-5 items).
final _globalVariableListGen =
    any.listWithLengthInRange(0, 6, _globalVariableGen);

void main() {
  final service = XmlParserServiceImpl();

  Glados(_globalVariableListGen, ExploreConfig(numRuns: 100)).test(
    'serializeGlobals then parseGlobals produces equivalent list',
    (List<GlobalVariable> original) {
      final xml = service.serializeGlobals(original);
      final parsed = service.parseGlobals(xml);
      expect(parsed, equals(original));
    },
  );
}
