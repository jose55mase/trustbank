import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_project.dart';
import '../providers/portfolio_providers.dart';
import '../theme/portfolio_theme.dart';
import '../widgets/interactive_carousel.dart';
import '../widgets/portfolio_nav_bar.dart';
import '../widgets/project_catalog.dart';

/// Public portfolio home page.
class PortfolioHomeScreen extends ConsumerStatefulWidget {
  const PortfolioHomeScreen({super.key});

  @override
  ConsumerState<PortfolioHomeScreen> createState() =>
      _PortfolioHomeScreenState();
}

class _PortfolioHomeScreenState extends ConsumerState<PortfolioHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final _heroKey = GlobalKey();
  final _catalogKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _contactKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProjects = ref.watch(allProjectsProvider);
    final featuredProjects = ref.watch(featuredProjectsProvider);
    final heroContent = ref.watch(editableContentProvider('hero'));
    final aboutContent = ref.watch(editableContentProvider('about'));
    final screenWidth = MediaQuery.sizeOf(context).width;

    final navLinks = [
      PortfolioNavLink(label: 'Inicio', sectionKey: _heroKey),
      PortfolioNavLink(label: 'Proyectos', sectionKey: _catalogKey),
      PortfolioNavLink(label: 'Sobre Mí', sectionKey: _aboutKey),
      PortfolioNavLink(label: 'Contacto', sectionKey: _contactKey),
    ];

    return Theme(
      data: PortfolioTheme.lightTheme,
      child: Scaffold(
        backgroundColor: PortfolioTheme.background,
        body: Column(
          children: [
            // Fixed nav bar
            PortfolioNavBar(
              links: navLinks,
              scrollController: _scrollController,
              title: 'Mi Portafolio',
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ═══ HERO SECTION ═══
                    Container(
                      key: _heroKey,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            PortfolioTheme.primaryBlue.withOpacity(0.15),
                            PortfolioTheme.background,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 1024 ? (screenWidth - 1200) / 2 : 24,
                          vertical: 48,
                        ),
                        child: Column(
                          children: [
                            // Hero text
                            heroContent.when(
                              data: (items) {
                                final title = items
                                    .where((c) => c.key == 'title')
                                    .firstOrNull?.value ?? 'Desarrollador Flutter';
                                final subtitle = items
                                    .where((c) => c.key == 'subtitle')
                                    .firstOrNull?.value ?? 'Creando experiencias excepcionales';
                                return Column(
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: screenWidth > 768 ? 48 : 32,
                                        fontWeight: FontWeight.bold,
                                        color: PortfolioTheme.accentBlack,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: screenWidth > 768 ? 20 : 16,
                                        color: PortfolioTheme.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              },
                              loading: () => Text(
                                'Desarrollador Flutter',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: PortfolioTheme.accentBlack,
                                ),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 40),
                            // Carousel
                            featuredProjects.when(
                              data: (projects) => _buildCarousel(projects, screenWidth),
                              loading: () => _buildCarouselPlaceholder(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ═══ CATALOG SECTION ═══
                    Container(
                      key: _catalogKey,
                      width: double.infinity,
                      color: PortfolioTheme.surface,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 1024 ? (screenWidth - 1200) / 2 : 24,
                          vertical: 48,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: PortfolioTheme.secondaryOrange,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Mis Proyectos',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: PortfolioTheme.accentBlack,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            allProjects.when(
                              data: (projects) => ProjectCatalog(projects: projects),
                              loading: () => SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: PortfolioTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              error: (_, __) => const Text('Error al cargar proyectos'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ═══ ABOUT SECTION ═══
                    Container(
                      key: _aboutKey,
                      width: double.infinity,
                      color: PortfolioTheme.background,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 1024 ? (screenWidth - 1200) / 2 : 24,
                          vertical: 48,
                        ),
                        child: aboutContent.when(
                          data: (items) {
                            final title = items
                                .where((c) => c.key == 'title')
                                .firstOrNull?.value ?? 'Sobre Mí';
                            final description = items
                                .where((c) => c.key == 'description')
                                .firstOrNull?.value ?? '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: PortfolioTheme.primaryBlue,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: PortfolioTheme.accentBlack,
                                      ),
                                    ),
                                  ],
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.7,
                                      color: PortfolioTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ),

                    // ═══ FOOTER ═══
                    Container(
                      key: _contactKey,
                      width: double.infinity,
                      color: PortfolioTheme.accentBlack,
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            'Mi Portafolio',
                            style: TextStyle(
                              color: PortfolioTheme.primaryBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '© 2024 Todos los derechos reservados',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(List<PortfolioProject> projects, double screenWidth) {
    if (projects.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: PortfolioTheme.primaryBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No hay proyectos destacados',
            style: TextStyle(color: PortfolioTheme.textSecondary, fontSize: 16),
          ),
        ),
      );
    }
    return InteractiveCarousel(
      projects: projects,
      height: screenWidth > 768 ? 450 : 300,
    );
  }

  Widget _buildCarouselPlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: PortfolioTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(color: PortfolioTheme.primaryBlue),
      ),
    );
  }
}
