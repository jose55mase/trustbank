import 'package:nitrado_server_manager/shared/models/models.dart';

/// Abstract interface for XML parsing and serialization of DayZ config files.
abstract class XmlParserService {
  /// Parses types.xml content into a list of [DayzType] objects.
  List<DayzType> parseTypes(String xmlContent);

  /// Serializes a list of [DayzType] objects to valid types.xml content.
  String serializeTypes(List<DayzType> types);

  /// Parses globals.xml content into a list of [GlobalVariable] objects.
  List<GlobalVariable> parseGlobals(String xmlContent);

  /// Serializes a list of [GlobalVariable] objects to valid globals.xml content.
  String serializeGlobals(List<GlobalVariable> globals);

  /// Parses events.xml content into a list of [SpawnEvent] objects.
  List<SpawnEvent> parseEvents(String xmlContent);

  /// Serializes a list of [SpawnEvent] objects to valid events.xml content.
  String serializeEvents(List<SpawnEvent> events);

  /// Returns true if [content] is well-formed XML.
  bool isValidXml(String content);

  /// Returns true if [content] is valid JSON.
  bool isValidJson(String content);
}
