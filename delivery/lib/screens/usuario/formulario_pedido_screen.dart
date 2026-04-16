import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../providers/pedido_providers.dart';

/// Pantalla de formulario para solicitar un nuevo pedido.
/// El usuario completa dirección, nombre, teléfono, descripción,
/// precio del producto y tipo de entrega.
///
/// Requisitos: 1.1, 1.2, 1.3, 1.4, 1.5
class FormularioPedidoScreen extends ConsumerStatefulWidget {
  const FormularioPedidoScreen({super.key});

  @override
  ConsumerState<FormularioPedidoScreen> createState() =>
      _FormularioPedidoScreenState();
}

class _FormularioPedidoScreenState
    extends ConsumerState<FormularioPedidoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _direccionController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  TipoEntrega _tipoEntrega = TipoEntrega.estandar;
  bool _isLoading = false;

  @override
  void dispose() {
    _direccionController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final telefono = _telefonoController.text.trim();
      final repo = ref.read(pedidoRepositoryProvider);

      // Check if user already has an active order (Req 1.4)
      final pedidoExistente =
          await repo.obtenerPedidoActivoPorUsuario(telefono);
      if (pedidoExistente != null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Ya tienes un pedido en curso. Debes esperar a que se complete.',
        );
        return;
      }

      final precio = double.tryParse(_precioController.text.trim()) ?? 0;

      final request = CrearPedidoRequest(
        direccionEntrega: _direccionController.text.trim(),
        nombreUsuario: _nombreController.text.trim(),
        telefonoUsuario: telefono,
        descripcion: _descripcionController.text.trim(),
        precioProducto: precio,
        tipoEntrega: _tipoEntrega,
      );

      final pedido = await repo.crearPedido(request);

      // Invalidate providers so they refresh
      ref.invalidate(pedidosActivosProvider);
      ref.invalidate(pedidoActivoUsuarioProvider(telefono));

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show confirmation code (Req 1.5)
      _showCodigoConfirmacion(pedido.codigoConfirmacion, telefono);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showCodigoConfirmacion(String codigo, String telefono) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          '¡Pedido creado!',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu código de confirmación es:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary),
              ),
              child: Text(
                codigo,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Guárdalo para confirmar tu entrega.',
              style: TextStyle(color: AppTheme.textHint, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/seguimiento?telefono=$telefono');
            },
            child: const Text('Ver seguimiento'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/');
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Error',
          style: TextStyle(color: AppTheme.error),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Pedido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dirección de entrega
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de entrega',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La dirección de entrega es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nombre del usuario
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Número de teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número de teléfono es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del pedido',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción del pedido es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Precio del producto
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio del producto',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El precio del producto es obligatorio';
                  }
                  final precio = double.tryParse(value.trim());
                  if (precio == null || precio <= 0) {
                    return 'Ingresa un precio válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo de entrega
              DropdownButtonFormField<TipoEntrega>(
                value: _tipoEntrega,
                decoration: const InputDecoration(
                  labelText: 'Tipo de entrega',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                dropdownColor: AppTheme.surfaceVariant,
                items: const [
                  DropdownMenuItem(
                    value: TipoEntrega.estandar,
                    child: Text('Estándar'),
                  ),
                  DropdownMenuItem(
                    value: TipoEntrega.express,
                    child: Text('Express'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _tipoEntrega = value);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textPrimary,
                          ),
                        )
                      : const Text('Solicitar Pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
