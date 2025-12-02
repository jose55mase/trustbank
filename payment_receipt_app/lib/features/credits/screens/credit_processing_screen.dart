import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../bloc/credits_bloc.dart';
import '../bloc/credits_state.dart';
import 'credit_status_screen.dart';
import '../../../design_system/components/molecules/tb_dialog.dart';
import '../../notifications/bloc/notifications_bloc.dart';

class CreditProcessingScreen extends StatefulWidget {
  const CreditProcessingScreen({super.key});

  @override
  State<CreditProcessingScreen> createState() => _CreditProcessingScreenState();
}

class _CreditProcessingScreenState extends State<CreditProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreditsBloc, CreditsState>(
      listener: (context, state) {
        if (state is CreditApplicationSubmitted) {
          // Agregar notificación
          try {
            NotificationsBloc().add(AddCreditNotification(
              creditType: state.application.creditType,
              amount: state.application.amount,
            ));
          } catch (e) {
            // Error silencioso en notificación
          }
          
          // Éxito - navegar a pantalla de estado
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreditStatusScreen(
                application: state.application,
              ),
            ),
          );
        } else if (state is CreditsError) {
          // Error - mostrar diálogo y volver
          TBDialogHelper.showError(
            context,
            title: 'Error en la solicitud',
            message: state.message,
          );
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: TBColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TBSpacing.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Icono animado
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value * 2 * 3.14159,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: TBColors.primaryGradient,
                                borderRadius: BorderRadius.circular(60),
                                boxShadow: [
                                  BoxShadow(
                                    color: TBColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.hourglass_empty,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: TBSpacing.xl),
                
                // Título
                Text(
                  'Procesando solicitud...',
                  style: TBTypography.displayLarge.copyWith(
                    color: TBColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: TBSpacing.md),
                
                // Descripción
                Text(
                  'Estamos enviando tu solicitud de crédito al administrador para su revisión.',
                  style: TBTypography.bodyLarge.copyWith(
                    color: TBColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: TBSpacing.xl),
                
                // Pasos del proceso
                Container(
                  padding: const EdgeInsets.all(TBSpacing.lg),
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
                    children: [
                      _buildProcessStep(
                        icon: Icons.check_circle,
                        title: 'Datos validados',
                        isCompleted: true,
                      ),
                      const SizedBox(height: TBSpacing.md),
                      _buildProcessStep(
                        icon: Icons.send,
                        title: 'Enviando al administrador',
                        isCompleted: false,
                        isActive: true,
                      ),
                      const SizedBox(height: TBSpacing.md),
                      _buildProcessStep(
                        icon: Icons.schedule,
                        title: 'Esperando aprobación',
                        isCompleted: false,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Mensaje informativo
                Container(
                  padding: const EdgeInsets.all(TBSpacing.md),
                  decoration: BoxDecoration(
                    color: TBColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: TBColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: TBSpacing.sm),
                      Expanded(
                        child: Text(
                          'Este proceso puede tomar unos segundos. No cierres la aplicación.',
                          style: TBTypography.bodyMedium.copyWith(
                            color: TBColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessStep({
    required IconData icon,
    required String title,
    required bool isCompleted,
    bool isActive = false,
  }) {
    Color color;
    if (isCompleted) {
      color = TBColors.success;
    } else if (isActive) {
      color = TBColors.primary;
    } else {
      color = TBColors.grey400;
    }

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : color,
            size: 18,
          ),
        ),
        const SizedBox(width: TBSpacing.md),
        Expanded(
          child: Text(
            title,
            style: TBTypography.bodyMedium.copyWith(
              color: isCompleted || isActive ? color : TBColors.grey600,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}