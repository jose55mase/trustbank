import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nitrado_server_manager/core/api/api_provider.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/features/config_editor/config_editor_notifier.dart';
import 'package:nitrado_server_manager/features/server_selection/server_selection_notifier.dart';
import 'package:nitrado_server_manager/shared/models/file_entry.dart';
import 'package:nitrado_server_manager/shared/models/game_server.dart';

class MockNitradoApiClient extends Mock implements NitradoApiClient {}

GameServer _server() => const GameServer(
      id: 1,
      name: 'Test Server',
      ip: '1.2.3.4',
      port: 2302,
      status: 'started',
      currentPlayers: 5,
      maxPlayers: 60,
      map: 'chernarusplus',
      gameVersion: '1.24',
    );

void main() {
  late MockNitradoApiClient mockApi;
  late ProviderContainer container;

  setUp(() {
    mockApi = MockNitradoApiClient();
    container = ProviderContainer(
      overrides: [
        nitradoApiClientProvider.overrideWithValue(mockApi),
        selectedServerProvider.overrideWith((ref) => _server()),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('fileTypeFromPath', () {
    test('returns xml for .xml files', () {
      expect(fileTypeFromPath('types.xml'), ConfigFileType.xml);
      expect(fileTypeFromPath('/path/to/config.XML'), ConfigFileType.xml);
    });

    test('returns json for .json files', () {
      expect(fileTypeFromPath('gameplay.json'), ConfigFileType.json);
      expect(fileTypeFromPath('/path/to/CFG.JSON'), ConfigFileType.json);
    });

    test('returns unknown for other extensions', () {
      expect(fileTypeFromPath('readme.txt'), ConfigFileType.unknown);
      expect(fileTypeFromPath('noext'), ConfigFileType.unknown);
    });
  });

  group('ConfigEditorNotifier', () {
    test('initial state is empty', () {
      final state = container.read(configEditorNotifierProvider);
      expect(state.files, isEmpty);
      expect(state.isLoadingFiles, isFalse);
      expect(state.selectedFilePath, isNull);
      expect(state.fileContent, isNull);
    });

    test('fetchFiles populates file list on success (Req 5.1)', () async {
      final files = [
        const FileEntry(name: 'types.xml', path: '/types.xml', type: 'file', size: 1024),
        const FileEntry(name: 'db', path: '/db', type: 'dir'),
      ];
      when(() => mockApi.listFiles(1, '/')).thenAnswer((_) async => files);

      await container
          .read(configEditorNotifierProvider.notifier)
          .fetchFiles();

      final state = container.read(configEditorNotifierProvider);
      expect(state.files, equals(files));
      expect(state.isLoadingFiles, isFalse);
      expect(state.filesError, isNull);
    });

    test('fetchFiles sets error when API fails', () async {
      when(() => mockApi.listFiles(1, '/'))
          .thenThrow(Exception('Network error'));

      await container
          .read(configEditorNotifierProvider.notifier)
          .fetchFiles();

      final state = container.read(configEditorNotifierProvider);
      expect(state.files, isEmpty);
      expect(state.isLoadingFiles, isFalse);
      expect(state.filesError, isNotNull);
      expect(state.filesError, contains('listar archivos'));
    });

    test('selectFile downloads content on success (Req 5.2)', () async {
      const content = '<types><type name="AK101"/></types>';
      when(() => mockApi.downloadFile(1, '/types.xml'))
          .thenAnswer((_) async => content);

      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/types.xml');

      final state = container.read(configEditorNotifierProvider);
      expect(state.selectedFilePath, '/types.xml');
      expect(state.fileContent, content);
      expect(state.isLoadingContent, isFalse);
      expect(state.contentError, isNull);
    });

    test('selectFile sets error when download fails', () async {
      when(() => mockApi.downloadFile(1, '/types.xml'))
          .thenThrow(Exception('Download failed'));

      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/types.xml');

      final state = container.read(configEditorNotifierProvider);
      expect(state.selectedFilePath, '/types.xml');
      expect(state.isLoadingContent, isFalse);
      expect(state.contentError, isNotNull);
    });

    test('saveFile validates XML before upload (Req 5.4, 5.6)', () async {
      // First select an XML file.
      when(() => mockApi.downloadFile(1, '/types.xml'))
          .thenAnswer((_) async => '<valid/>');
      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/types.xml');

      // Try to save invalid XML.
      await container
          .read(configEditorNotifierProvider.notifier)
          .saveFile('not valid xml <<>');

      final state = container.read(configEditorNotifierProvider);
      expect(state.validationError, isNotNull);
      expect(state.validationError, contains('XML'));
      expect(state.isUploading, isFalse);
      // Upload should NOT have been called.
      verifyNever(() => mockApi.uploadFile(any(), any(), any()));
    });

    test('saveFile validates JSON before upload (Req 5.5)', () async {
      when(() => mockApi.downloadFile(1, '/gameplay.json'))
          .thenAnswer((_) async => '{}');
      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/gameplay.json');

      // Try to save invalid JSON.
      await container
          .read(configEditorNotifierProvider.notifier)
          .saveFile('{invalid json}');

      final state = container.read(configEditorNotifierProvider);
      expect(state.validationError, isNotNull);
      expect(state.validationError, contains('JSON'));
      verifyNever(() => mockApi.uploadFile(any(), any(), any()));
    });

    test('saveFile uploads valid XML content (Req 5.3)', () async {
      when(() => mockApi.downloadFile(1, '/types.xml'))
          .thenAnswer((_) async => '<old/>');
      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/types.xml');

      const validXml = '<types><type name="AK101"/></types>';
      when(() => mockApi.uploadFile(1, '/types.xml', validXml))
          .thenAnswer((_) async {});

      await container
          .read(configEditorNotifierProvider.notifier)
          .saveFile(validXml);

      final state = container.read(configEditorNotifierProvider);
      expect(state.isUploading, isFalse);
      expect(state.validationError, isNull);
      expect(state.successMessage, 'Archivo guardado correctamente');
      expect(state.fileContent, validXml);
      verify(() => mockApi.uploadFile(1, '/types.xml', validXml)).called(1);
    });

    test('saveFile uploads valid JSON content', () async {
      when(() => mockApi.downloadFile(1, '/gameplay.json'))
          .thenAnswer((_) async => '{}');
      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/gameplay.json');

      const validJson = '{"key": "value"}';
      when(() => mockApi.uploadFile(1, '/gameplay.json', validJson))
          .thenAnswer((_) async {});

      await container
          .read(configEditorNotifierProvider.notifier)
          .saveFile(validJson);

      final state = container.read(configEditorNotifierProvider);
      expect(state.successMessage, 'Archivo guardado correctamente');
      verify(() => mockApi.uploadFile(1, '/gameplay.json', validJson)).called(1);
    });

    test('saveFile sets upload error when API fails', () async {
      when(() => mockApi.downloadFile(1, '/types.xml'))
          .thenAnswer((_) async => '<old/>');
      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/types.xml');

      const validXml = '<new/>';
      when(() => mockApi.uploadFile(1, '/types.xml', validXml))
          .thenThrow(Exception('Upload failed'));

      await container
          .read(configEditorNotifierProvider.notifier)
          .saveFile(validXml);

      final state = container.read(configEditorNotifierProvider);
      expect(state.uploadError, isNotNull);
      expect(state.uploadError, contains('subir archivo'));
    });

    test('saveFile skips validation for unknown file types', () async {
      when(() => mockApi.downloadFile(1, '/readme.txt'))
          .thenAnswer((_) async => 'hello');
      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/readme.txt');

      when(() => mockApi.uploadFile(1, '/readme.txt', 'updated'))
          .thenAnswer((_) async {});

      await container
          .read(configEditorNotifierProvider.notifier)
          .saveFile('updated');

      final state = container.read(configEditorNotifierProvider);
      expect(state.validationError, isNull);
      expect(state.successMessage, 'Archivo guardado correctamente');
    });

    test('clearSelection resets editor state', () async {
      when(() => mockApi.downloadFile(1, '/types.xml'))
          .thenAnswer((_) async => '<data/>');
      await container
          .read(configEditorNotifierProvider.notifier)
          .selectFile('/types.xml');

      container
          .read(configEditorNotifierProvider.notifier)
          .clearSelection();

      final state = container.read(configEditorNotifierProvider);
      expect(state.selectedFilePath, isNull);
      expect(state.fileContent, isNull);
    });

    test('does nothing when no server is selected', () async {
      final emptyContainer = ProviderContainer(
        overrides: [
          nitradoApiClientProvider.overrideWithValue(mockApi),
        ],
      );

      final notifier =
          emptyContainer.read(configEditorNotifierProvider.notifier);
      await notifier.fetchFiles();
      await notifier.selectFile('/types.xml');
      await notifier.saveFile('<data/>');

      final state = emptyContainer.read(configEditorNotifierProvider);
      expect(state.files, isEmpty);
      expect(state.selectedFilePath, isNull);

      emptyContainer.dispose();
    });
  });
}
