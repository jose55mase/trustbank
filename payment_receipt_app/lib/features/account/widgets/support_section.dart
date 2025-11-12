import 'package:flutter/material.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TBColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(TBSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: TBColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: TBSpacing.sm),
                Text(
                  'Ayuda y Soporte',
                  style: TBTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildSupportItem(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Chat en vivo',
            subtitle: 'Habla con nuestro equipo de soporte',
            onTap: () => _showLiveChat(context),
          ),
          _buildDivider(),
          _buildSupportItem(
            context,
            icon: Icons.phone,
            title: 'Llamar a soporte',
            subtitle: '+1 (800) 123-4567',
            onTap: () => _callSupport(context),
          ),
          _buildDivider(),
          _buildSupportItem(
            context,
            icon: Icons.email_outlined,
            title: 'Enviar email',
            subtitle: 'soporte@trustbank.com',
            onTap: () => _sendEmail(context),
          ),
          _buildDivider(),
          _buildSupportItem(
            context,
            icon: Icons.help_center_outlined,
            title: 'Centro de ayuda',
            subtitle: 'Preguntas frecuentes y guías',
            onTap: () => _showHelpCenter(context),
          ),
          _buildDivider(),
          _buildSupportItem(
            context,
            icon: Icons.info_outline,
            title: 'Acerca de TrustBank',
            subtitle: 'Versión 1.0.0',
            onTap: () => _showAbout(context),
          ),
          _buildDivider(),
          _buildSupportItem(
            context,
            icon: Icons.logout,
            title: 'Cerrar sesión',
            subtitle: 'Salir de tu cuenta de forma segura',
            onTap: () => _logout(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TBSpacing.md,
          vertical: TBSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? TBColors.error.withOpacity(0.1)
                    : TBColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isDestructive ? TBColors.error : TBColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: TBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TBTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? TBColors.error : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TBTypography.bodySmall.copyWith(
                      color: TBColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: TBColors.grey500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TBSpacing.md),
      child: Divider(
        height: 1,
        color: TBColors.grey300.withOpacity(0.5),
      ),
    );
  }

  void _showLiveChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: TBColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(TBSpacing.md),
              decoration: BoxDecoration(
                color: TBColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: TBColors.white),
                  ),
                  const SizedBox(width: TBSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat de Soporte',
                          style: TBTypography.titleMedium.copyWith(
                            color: TBColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'En línea',
                          style: TBTypography.bodySmall.copyWith(
                            color: TBColors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: TBColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TBSpacing.md),
                child: Column(
                  children: [
                    _buildChatMessage(
                      'Hola! Soy Ana, tu asistente de soporte. ¿En qué puedo ayudarte hoy?',
                      isFromSupport: true,
                    ),
                    const SizedBox(height: TBSpacing.md),
                    _buildQuickActions(),
                    const Spacer(),
                    _buildChatInput(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(String message, {bool isFromSupport = false}) {
    return Align(
      alignment: isFromSupport ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(TBSpacing.md),
        decoration: BoxDecoration(
          color: isFromSupport ? TBColors.grey100 : TBColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TBTypography.bodyMedium.copyWith(
            color: isFromSupport ? TBColors.black : TBColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rápidas:',
          style: TBTypography.bodySmall.copyWith(
            color: TBColors.grey600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: TBSpacing.sm),
        Wrap(
          spacing: TBSpacing.sm,
          runSpacing: TBSpacing.sm,
          children: [
            _buildQuickActionChip('Problema con transferencia'),
            _buildQuickActionChip('No puedo acceder'),
            _buildQuickActionChip('Consulta de saldo'),
            _buildQuickActionChip('Reportar fraude'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TBSpacing.md,
        vertical: TBSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TBColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TBColors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TBTypography.bodySmall.copyWith(
          color: TBColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(TBSpacing.sm),
      decoration: BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TBSpacing.md,
                  vertical: TBSpacing.sm,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: TBColors.primary,
              foregroundColor: TBColors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _callSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Llamar a Soporte'),
        content: const Text('¿Deseas llamar a nuestro equipo de soporte?\n\n+1 (800) 123-4567'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abriendo aplicación de teléfono...'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.primary,
              foregroundColor: TBColors.white,
            ),
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  void _sendEmail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Email'),
        content: const Text('¿Deseas enviar un email a soporte?\n\nsoporte@trustbank.com'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abriendo aplicación de email...'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.primary,
              foregroundColor: TBColors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 500,
        decoration: const BoxDecoration(
          color: TBColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TBSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TBColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: TBSpacing.lg),
              Text(
                'Centro de Ayuda',
                style: TBTypography.headlineSmall,
              ),
              const SizedBox(height: TBSpacing.md),
              Expanded(
                child: ListView(
                  children: [
                    _buildHelpItem('¿Cómo enviar dinero?', 'Guía paso a paso para transferencias'),
                    _buildHelpItem('Límites de cuenta', 'Información sobre límites diarios y mensuales'),
                    _buildHelpItem('Seguridad', 'Consejos para mantener tu cuenta segura'),
                    _buildHelpItem('Verificación', 'Proceso de verificación de identidad'),
                    _buildHelpItem('Problemas comunes', 'Soluciones a problemas frecuentes'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.sm),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, color: TBColors.primary),
          const SizedBox(width: TBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TBTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TBTypography.bodySmall.copyWith(color: TBColors.grey600)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: TBColors.grey500),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de TrustBank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión: 1.0.0', style: TBTypography.bodyMedium),
            const SizedBox(height: TBSpacing.sm),
            Text('Build: 2024.01.15', style: TBTypography.bodyMedium),
            const SizedBox(height: TBSpacing.md),
            Text(
              'TrustBank es tu aplicación de confianza para transferencias seguras y gestión financiera.',
              style: TBTypography.bodySmall.copyWith(color: TBColors.grey600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TBColors.error,
              foregroundColor: TBColors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}