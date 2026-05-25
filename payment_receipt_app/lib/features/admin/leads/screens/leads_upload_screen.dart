import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../bloc/leads_bloc.dart';
import '../models/mapping_result.dart';
import '../services/leads_service.dart';

/// Pantalla de carga y mapeo de archivos Excel para importación de leads.
///
/// Permite al administrador:
/// 1. Seleccionar un archivo Excel (.xlsx/.xls)
/// 2. Visualizar el mapeo automático de columnas
/// 3. Editar manualmente columnas no reconocidas
/// 4. Confirmar la importación y ver el resumen
class LeadsUploadScreen extends StatelessWidget {
  const LeadsUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LeadsBloc(leadsService: LeadsService()),
      child: const _LeadsUploadView(),
    );
  }
}

class _LeadsUploadView extends StatefulWidget {
  const _LeadsUploadView();

  @override
  State<_LeadsUploadView> createState() => _LeadsUploadViewState();
}

class _LeadsUploadViewState extends State<_LeadsUploadView> {
  /// Campos disponibles del sistema para mapeo.
  static const List<String> _availableFields = [
    'nombre',
    'apellido',
    'lastCallStatus',
    'pais',
    'telefono',
    'email',
    'campana',
    'fechaRegistro',
    'comentarios',
  ];

  /// Etiquetas legibles para los campos del sistema.
  static const Map<String, String> _fieldLabels = {
    'nombre': 'Nombre',
    'apellido': 'Apellido',
    'lastCallStatus': 'Estado Llamada',
    'pais': 'País',
    'telefono': 'Teléfono',
    'email': 'Email',
    'campana': 'Campaña',
    'fechaRegistro': 'Fecha Registro',
    'comentarios': 'Comentarios',
  };

  /// Tamaño máximo permitido: 10MB.
  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  /// Extensiones permitidas.
  static const List<String> _allowedExtensions = ['xlsx', 'xls'];

  /// Mapeo editable por el usuario (copia local del mapeo recibido).
  Map<int, String?> _editableMapping = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TBColors.background,
      appBar: AppBar(
        title: Text('Importar Leads desde Excel', style: TBTypography.headlineMedium),
        backgroundColor: TBColors.primary,
        foregroundColor: TBColors.white,
        elevation: 0,
      ),
      body: BlocConsumer<LeadsBloc, LeadsState>(
        listener: _blocListener,
        builder: (context, state) {
          if (state is LeadsLoading) {
            return _buildLoadingView();
          } else if (state is MappingPreviewLoaded) {
            return _buildMappingPreview(state.mapping);
          } else if (state is ImportCompleted) {
            return _buildImportSummary(state.successCount, state.duplicateCount, state.errorCount);
          }
          // Estado inicial o después de un error: mostrar botón de selección
          return _buildFilePickerView();
        },
      ),
    );
  }

  /// Escucha cambios de estado para mostrar errores en SnackBar.
  void _blocListener(BuildContext context, LeadsState state) {
    if (state is LeadsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    if (state is MappingPreviewLoaded) {
      // Inicializar mapeo editable con los valores recibidos
      setState(() {
        _editableMapping = Map<int, String?>.from(state.mapping.columnMapping);
      });
    }
  }

  /// Vista inicial con botón para seleccionar archivo.
  Widget _buildFilePickerView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 80,
              color: TBColors.primary.withOpacity(0.6),
            ),
            const SizedBox(height: TBSpacing.lg),
            Text(
              'Seleccione un archivo Excel',
              style: TBTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TBSpacing.sm),
            Text(
              'Formatos aceptados: .xlsx, .xls\nTamaño máximo: 10MB',
              style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TBSpacing.xl),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Seleccionar Archivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TBColors.primary,
                foregroundColor: TBColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: TBSpacing.xl,
                  vertical: TBSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vista de carga con indicador de progreso.
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: TBSpacing.lg),
          Text('Procesando archivo...'),
        ],
      ),
    );
  }

  /// Vista previa del mapeo automático con tabla editable.
  Widget _buildMappingPreview(MappingResult mapping) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TBSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mapeo de Columnas', style: TBTypography.titleLarge),
          const SizedBox(height: TBSpacing.sm),
          Text(
            'Revise y ajuste la correspondencia entre las columnas del Excel y los campos del sistema.',
            style: TBTypography.bodyMedium.copyWith(color: TBColors.grey600),
          ),
          const SizedBox(height: TBSpacing.md),
          _buildMappingTable(mapping),
          const SizedBox(height: TBSpacing.lg),
          if (mapping.previewRows.isNotEmpty) ...[
            Text('Vista Previa de Datos', style: TBTypography.titleLarge),
            const SizedBox(height: TBSpacing.sm),
            _buildPreviewTable(mapping),
            const SizedBox(height: TBSpacing.lg),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmImport,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirmar Importación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TBColors.primary,
                foregroundColor: TBColors.white,
                padding: const EdgeInsets.symmetric(vertical: TBSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tabla de mapeo: Columna Excel → Campo del Sistema (con dropdown editable).
  Widget _buildMappingTable(MappingResult mapping) {
    return Container(
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            TBColors.primary.withOpacity(0.1),
          ),
          columns: const [
            DataColumn(label: Text('Columna Excel')),
            DataColumn(label: Text('Campo del Sistema')),
          ],
          rows: List.generate(mapping.headers.length, (index) {
            final header = mapping.headers[index];
            final currentField = _editableMapping[index];

            return DataRow(
              cells: [
                DataCell(Text(header, style: TBTypography.bodyMedium)),
                DataCell(
                  DropdownButton<String?>(
                    value: currentField,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: Text(
                      'Sin mapear',
                      style: TBTypography.bodyMedium.copyWith(
                        color: Colors.red.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Sin mapear',
                          style: TBTypography.bodyMedium.copyWith(
                            color: Colors.red.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      ..._availableFields.map((field) {
                        return DropdownMenuItem<String?>(
                          value: field,
                          child: Text(
                            _fieldLabels[field] ?? field,
                            style: TBTypography.bodyMedium,
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _editableMapping[index] = value;
                      });
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Tabla de vista previa con las primeras filas del Excel.
  Widget _buildPreviewTable(MappingResult mapping) {
    return Container(
      decoration: BoxDecoration(
        color: TBColors.surface,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              TBColors.primary.withOpacity(0.05),
            ),
            columns: mapping.headers
                .map((header) => DataColumn(
                      label: Text(
                        header,
                        style: TBTypography.labelMedium,
                      ),
                    ))
                .toList(),
            rows: mapping.previewRows.map((row) {
              return DataRow(
                cells: List.generate(
                  mapping.headers.length,
                  (index) => DataCell(
                    Text(
                      index < row.length ? row[index] : '',
                      style: TBTypography.bodyMedium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Resumen de importación con conteo de éxitos, duplicados omitidos y errores.
  Widget _buildImportSummary(int successCount, int duplicateCount, int errorCount) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TBSpacing.screenPadding),
        child: Container(
          padding: const EdgeInsets.all(TBSpacing.xl),
          decoration: BoxDecoration(
            color: TBColors.surface,
            borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: TBColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                errorCount == 0 && duplicateCount == 0
                    ? Icons.check_circle
                    : Icons.info_outline,
                size: 64,
                color: errorCount == 0 && duplicateCount == 0
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(height: TBSpacing.lg),
              Text(
                'Importación Completada',
                style: TBTypography.titleLarge,
              ),
              const SizedBox(height: TBSpacing.md),
              _buildSummaryRow(
                icon: Icons.check,
                color: Colors.green,
                label: 'Registros exitosos',
                count: successCount,
              ),
              const SizedBox(height: TBSpacing.sm),
              _buildSummaryRow(
                icon: Icons.content_copy,
                color: Colors.orange,
                label: 'Duplicados omitidos',
                count: duplicateCount,
              ),
              const SizedBox(height: TBSpacing.sm),
              _buildSummaryRow(
                icon: Icons.error_outline,
                color: Colors.red,
                label: 'Registros con errores',
                count: errorCount,
              ),
              const SizedBox(height: TBSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TBColors.primary,
                    foregroundColor: TBColors.white,
                    padding: const EdgeInsets.symmetric(vertical: TBSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Volver al Listado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fila del resumen con ícono, etiqueta y conteo.
  Widget _buildSummaryRow({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: TBSpacing.sm),
        Text(label, style: TBTypography.bodyMedium),
        const SizedBox(width: TBSpacing.sm),
        Text(
          '$count',
          style: TBTypography.titleLarge.copyWith(color: color),
        ),
      ],
    );
  }

  /// Abre el selector de archivos y valida extensión y tamaño.
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;

      // Validar extensión
      final extension = pickedFile.extension?.toLowerCase() ?? '';
      if (!_allowedExtensions.contains(extension)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Formato de archivo no soportado. Use .xlsx o .xls',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Validar tamaño
      final fileSize = pickedFile.size;
      if (fileSize > _maxFileSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'El archivo excede el tamaño máximo de 10MB',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Obtener los bytes del archivo (compatible con web y mobile)
      final fileBytes = pickedFile.bytes;
      if (fileBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo acceder al archivo seleccionado'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Despachar evento de carga
      if (!mounted) return;
      context.read<LeadsBloc>().add(UploadExcel(
        fileBytes: fileBytes,
        fileName: pickedFile.name,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar archivo: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Despacha el evento de confirmación de importación con el mapeo actual.
  void _confirmImport() {
    context.read<LeadsBloc>().add(ConfirmImport(mapping: _editableMapping));
  }
}
