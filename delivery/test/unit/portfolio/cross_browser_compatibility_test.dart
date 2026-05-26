import 'package:delivery_app/portfolio/models/portfolio_project.dart';
import 'package:delivery_app/portfolio/widgets/interactive_carousel.dart';
import 'package:delivery_app/portfolio/widgets/portfolio_nav_bar.dart';
import 'package:delivery_app/portfolio/widgets/portfolio_responsive_layout.dart';
import 'package:delivery_app/portfolio/widgets/project_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cross-browser compatibility verification tests.
///
/// Since Flutter web renders to Canvas/HTML uniformly across browsers,
/// functional differences are minimal. These tests verify:
/// - No horizontal overflow at any standard breakpoint
/// - Images maintain aspect ratio (BoxFit.contain/cover)
/// - Content width never exceeds screen width
/// - PortfolioResponsiveLayout properly constrains content at all breakpoints
///
/// Browser-specific notes:
/// - Flutter web uses CanvasKit or HTML renderer; both produce consistent output
/// - Touch/pointer events are normalized by the framework
/// - Font rendering may vary slightly but layout dimensions remain consistent
/// - All tested breakpoints cover Chrome, Firefox, Safari, and Edge viewports
///
/// Validates: Requirements 8.4, 8.5
void main() {
  // Standard breakpoints covering mobile, tablet, and desktop viewports
  // These represent common device widths across Chrome, Firefox, Safari, Edge
  const mobileBreakpoints = [320.0, 375.0, 414.0];
  const tabletBreakpoints = [768.0, 1024.0];
  const desktopBreakpoints = [1280.0, 1920.0];
  const allBreakpoints = [...mobileBreakpoints, ...tabletBreakpoints, ...desktopBreakpoints];

  /// Helper to create test projects for widget rendering.
  List<PortfolioProject> createTestProjects(int count) {
    return List.generate(count, (i) {
      return PortfolioProject(
        id: 'project-$i',
        title: 'Project Title $i with some extra text for testing',
        description:
            'This is a description for project $i that is long enough to test '
            'truncation behavior across different viewport sizes and ensure '
            'proper text wrapping without horizontal overflow.',
        mainImageUrl: 'https://example.com/image_$i.png',
        additionalImageUrls: ['https://example.com/extra_$i.png'],
        technologies: ['Flutter', 'Dart', 'Firebase'],
        isFeatured: i < 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });
  }

  group('Cross-browser compatibility - No horizontal overflow', () {
    for (final width in allBreakpoints) {
      testWidgets(
        'PortfolioResponsiveLayout has no overflow at ${width}px width',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: width,
                  height: 800,
                  child: PortfolioResponsiveLayout(
                    builder: (context, layoutData) {
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.blue,
                            child: const Text(
                              'Content that should never overflow horizontally',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 100,
                            color: Colors.green,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          // No overflow errors should be reported by the framework
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final width in allBreakpoints) {
      testWidgets(
        'ProjectCatalog has no overflow at ${width}px width',
        (tester) async {
          final projects = createTestProjects(6);

          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: Size(width, 800)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: SizedBox(
                      width: width,
                      child: ProjectCatalog(
                        projects: projects,
                        onProjectSelected: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          // No overflow errors should be reported
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final width in allBreakpoints) {
      testWidgets(
        'InteractiveCarousel has no overflow at ${width}px width',
        (tester) async {
          final projects = createTestProjects(5)
              .where((p) => p.isFeatured)
              .toList();

          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: width,
                  height: 800,
                  child: InteractiveCarousel(projects: projects),
                ),
              ),
            ),
          );

          // No overflow errors should be reported
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final width in allBreakpoints) {
      testWidgets(
        'PortfolioNavBar has no overflow at ${width}px width',
        (tester) async {
          final scrollController = ScrollController();
          final links = [
            PortfolioNavLink(label: 'Home', sectionKey: GlobalKey()),
            PortfolioNavLink(label: 'Projects', sectionKey: GlobalKey()),
            PortfolioNavLink(label: 'About', sectionKey: GlobalKey()),
            PortfolioNavLink(label: 'Contact', sectionKey: GlobalKey()),
          ];

          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: Size(width, 800)),
                child: Scaffold(
                  body: SizedBox(
                    width: width,
                    child: PortfolioNavBar(
                      links: links,
                      scrollController: scrollController,
                    ),
                  ),
                ),
              ),
            ),
          );

          // No overflow errors should be reported
          expect(tester.takeException(), isNull);

          scrollController.dispose();
        },
      );
    }
  });

  group('Cross-browser compatibility - Content width constraints', () {
    for (final width in allBreakpoints) {
      test(
        'content width never exceeds screen width at ${width}px',
        () {
          final breakpoint = PortfolioBreakpoint.fromWidth(width);
          final contentWidth =
              PortfolioResponsiveLayout.computeContentWidth(width, breakpoint);

          expect(
            contentWidth,
            lessThanOrEqualTo(width),
            reason: 'Content width ($contentWidth) must not exceed '
                'screen width ($width) at ${breakpoint.name} breakpoint',
          );
        },
      );
    }

    for (final width in allBreakpoints) {
      test(
        'content width plus padding equals screen width at ${width}px',
        () {
          final breakpoint = PortfolioBreakpoint.fromWidth(width);
          final contentWidth =
              PortfolioResponsiveLayout.computeContentWidth(width, breakpoint);
          final padding =
              PortfolioResponsiveLayout.computeHorizontalPadding(
                  width, breakpoint);

          final totalWidth = contentWidth + (padding * 2);

          // For desktop, content is capped at 1200px so total may be less
          if (breakpoint == PortfolioBreakpoint.desktop) {
            expect(totalWidth, lessThanOrEqualTo(width));
          } else {
            // For mobile/tablet, content + padding should equal screen width
            expect(totalWidth, closeTo(width, 0.01));
          }
        },
      );
    }

    for (final width in desktopBreakpoints) {
      test(
        'desktop content width capped at 1200px for ${width}px screen',
        () {
          final contentWidth =
              PortfolioResponsiveLayout.computeContentWidth(
                  width, PortfolioBreakpoint.desktop);

          expect(contentWidth, lessThanOrEqualTo(1200.0));
        },
      );
    }
  });

  group('Cross-browser compatibility - Image aspect ratio maintenance', () {
    testWidgets(
      'PortfolioResponsiveImage uses BoxFit.contain by default',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: PortfolioResponsiveImage(
                  imageProvider: AssetImage('assets/test.png'),
                ),
              ),
            ),
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.fit, BoxFit.contain,
            reason: 'Default BoxFit.contain maintains aspect ratio');
      },
    );

    testWidgets(
      'PortfolioResponsiveImage with BoxFit.cover maintains aspect ratio',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: PortfolioResponsiveImage(
                  imageProvider: AssetImage('assets/test.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(
          image.fit,
          anyOf(BoxFit.contain, BoxFit.cover),
          reason: 'BoxFit.contain and BoxFit.cover both maintain aspect ratio',
        );
      },
    );

    testWidgets(
      'PortfolioResponsiveImage with aspectRatio wraps in AspectRatio widget',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: PortfolioResponsiveImage(
                  imageProvider: AssetImage('assets/test.png'),
                  aspectRatio: 16 / 9,
                ),
              ),
            ),
          ),
        );

        final aspectRatioWidget =
            tester.widget<AspectRatio>(find.byType(AspectRatio));
        expect(aspectRatioWidget.aspectRatio, 16 / 9);
      },
    );

    testWidgets(
      'PortfolioResponsiveImage never overflows container width',
      (tester) async {
        for (final width in allBreakpoints) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    height: 300,
                    child: const PortfolioResponsiveImage(
                      imageProvider: AssetImage('assets/test.png'),
                      aspectRatio: 16 / 9,
                    ),
                  ),
                ),
              ),
            ),
          );

          // No overflow errors
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'InteractiveCarousel images use BoxFit.cover for aspect ratio',
      (tester) async {
        final projects = createTestProjects(3)
            .where((p) => p.isFeatured)
            .toList();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: InteractiveCarousel(projects: projects),
              ),
            ),
          ),
        );

        // The carousel uses Image.network with BoxFit.cover
        // Since network images won't load in tests, the errorBuilder
        // will show the fallback. We verify the Image widget's fit property.
        final images = tester.widgetList<Image>(find.byType(Image));
        for (final image in images) {
          expect(
            image.fit,
            anyOf(BoxFit.contain, BoxFit.cover),
            reason: 'Carousel images must use BoxFit that maintains '
                'aspect ratio (contain or cover)',
          );
        }
      },
    );

    testWidgets(
      'ProjectCatalog images use BoxFit.cover for aspect ratio',
      (tester) async {
        final projects = createTestProjects(2);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1024, 800)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: 1024,
                    child: ProjectCatalog(
                      projects: projects,
                      onProjectSelected: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Catalog uses Image.network with BoxFit.cover
        final images = tester.widgetList<Image>(find.byType(Image));
        for (final image in images) {
          expect(
            image.fit,
            anyOf(BoxFit.contain, BoxFit.cover),
            reason: 'Catalog images must use BoxFit that maintains '
                'aspect ratio (contain or cover)',
          );
        }
      },
    );
  });

  group('Cross-browser compatibility - Responsive layout constraints', () {
    for (final width in mobileBreakpoints) {
      testWidgets(
        'mobile layout ($width px) uses single column with proper padding',
        (tester) async {
          PortfolioLayoutData? capturedData;

          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: width,
                  height: 800,
                  child: PortfolioResponsiveLayout(
                    builder: (context, data) {
                      capturedData = data;
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          );

          expect(capturedData, isNotNull);
          expect(capturedData!.breakpoint, PortfolioBreakpoint.mobile);
          expect(capturedData!.horizontalPadding, 16.0);
          expect(capturedData!.contentWidth, width - 32.0);
          expect(capturedData!.contentWidth, lessThanOrEqualTo(width));
        },
      );
    }

    for (final width in tabletBreakpoints) {
      testWidgets(
        'tablet layout ($width px) has margins between 24px and 5%',
        (tester) async {
          PortfolioLayoutData? capturedData;

          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: width,
                  height: 800,
                  child: PortfolioResponsiveLayout(
                    builder: (context, data) {
                      capturedData = data;
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          );

          expect(capturedData, isNotNull);
          expect(capturedData!.breakpoint, PortfolioBreakpoint.tablet);
          expect(
            capturedData!.horizontalPadding,
            greaterThanOrEqualTo(24.0),
          );
          expect(
            capturedData!.horizontalPadding,
            lessThanOrEqualTo(width * 0.05),
          );
          expect(capturedData!.contentWidth, lessThanOrEqualTo(width));
        },
      );
    }

    for (final width in desktopBreakpoints) {
      testWidgets(
        'desktop layout ($width px) caps content at 1200px centered',
        (tester) async {
          // Use physicalSize for desktop widths that exceed default test window
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          PortfolioLayoutData? capturedData;

          await tester.pumpWidget(
            MaterialApp(
              home: PortfolioResponsiveLayout(
                builder: (context, data) {
                  capturedData = data;
                  return const SizedBox();
                },
              ),
            ),
          );

          expect(capturedData, isNotNull);
          expect(capturedData!.breakpoint, PortfolioBreakpoint.desktop);
          expect(capturedData!.contentWidth, lessThanOrEqualTo(1200.0));
          expect(capturedData!.contentWidth, lessThanOrEqualTo(width));
          // Padding should center the content
          final expectedPadding = (width - 1200.0) / 2;
          if (expectedPadding > 0) {
            expect(
              capturedData!.horizontalPadding,
              closeTo(expectedPadding, 0.01),
            );
          }
        },
      );
    }
  });

  group('Cross-browser compatibility - Widget rendering at all breakpoints', () {
    for (final width in allBreakpoints) {
      testWidgets(
        'full page layout renders without overflow at ${width}px',
        (tester) async {
          final projects = createTestProjects(4);
          final scrollController = ScrollController();
          final links = [
            PortfolioNavLink(label: 'Home', sectionKey: GlobalKey()),
            PortfolioNavLink(label: 'Projects', sectionKey: GlobalKey()),
          ];

          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: Size(width, 800)),
                child: Scaffold(
                  body: SizedBox(
                    width: width,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          SizedBox(
                            width: width,
                            child: PortfolioNavBar(
                              links: links,
                              scrollController: scrollController,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            height: 400,
                            child: InteractiveCarousel(
                              projects: projects
                                  .where((p) => p.isFeatured)
                                  .toList(),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: ProjectCatalog(
                              projects: projects,
                              onProjectSelected: (_) {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          // No overflow errors should be reported
          expect(tester.takeException(), isNull);

          scrollController.dispose();
        },
      );
    }
  });
}
