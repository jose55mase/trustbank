import 'package:delivery_app/portfolio/widgets/portfolio_responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PortfolioBreakpoint', () {
    group('fromWidth', () {
      test('returns mobile for width < 768', () {
        expect(PortfolioBreakpoint.fromWidth(0), PortfolioBreakpoint.mobile);
        expect(PortfolioBreakpoint.fromWidth(320), PortfolioBreakpoint.mobile);
        expect(PortfolioBreakpoint.fromWidth(767), PortfolioBreakpoint.mobile);
        expect(
            PortfolioBreakpoint.fromWidth(767.9), PortfolioBreakpoint.mobile);
      });

      test('returns tablet for width 768-1024', () {
        expect(PortfolioBreakpoint.fromWidth(768), PortfolioBreakpoint.tablet);
        expect(PortfolioBreakpoint.fromWidth(900), PortfolioBreakpoint.tablet);
        expect(PortfolioBreakpoint.fromWidth(1024), PortfolioBreakpoint.tablet);
      });

      test('returns desktop for width > 1024', () {
        expect(
            PortfolioBreakpoint.fromWidth(1025), PortfolioBreakpoint.desktop);
        expect(
            PortfolioBreakpoint.fromWidth(1200), PortfolioBreakpoint.desktop);
        expect(
            PortfolioBreakpoint.fromWidth(1920), PortfolioBreakpoint.desktop);
      });
    });

    test('isMobile/isTablet/isDesktop helpers', () {
      expect(PortfolioBreakpoint.mobile.isMobile, isTrue);
      expect(PortfolioBreakpoint.mobile.isTablet, isFalse);
      expect(PortfolioBreakpoint.mobile.isDesktop, isFalse);

      expect(PortfolioBreakpoint.tablet.isMobile, isFalse);
      expect(PortfolioBreakpoint.tablet.isTablet, isTrue);
      expect(PortfolioBreakpoint.tablet.isDesktop, isFalse);

      expect(PortfolioBreakpoint.desktop.isMobile, isFalse);
      expect(PortfolioBreakpoint.desktop.isTablet, isFalse);
      expect(PortfolioBreakpoint.desktop.isDesktop, isTrue);
    });
  });

  group('PortfolioResponsiveLayout', () {
    Widget buildTestWidget({
      required double width,
      required Widget Function(BuildContext, PortfolioLayoutData) builder,
    }) {
      // Use a constrained box at the root to simulate screen width
      // since LayoutBuilder uses parent constraints, not MediaQuery
      return MaterialApp(
        home: Center(
          child: SizedBox(
            width: width,
            height: 800,
            child: PortfolioResponsiveLayout(builder: builder),
          ),
        ),
      );
    }

    testWidgets('provides mobile breakpoint for narrow screens',
        (tester) async {
      PortfolioLayoutData? capturedData;

      await tester.pumpWidget(buildTestWidget(
        width: 400,
        builder: (context, data) {
          capturedData = data;
          return const SizedBox();
        },
      ));

      expect(capturedData, isNotNull);
      expect(capturedData!.breakpoint, PortfolioBreakpoint.mobile);
      expect(capturedData!.screenWidth, 400);
    });

    testWidgets('provides tablet breakpoint for medium screens',
        (tester) async {
      tester.view.physicalSize = const Size(900, 800);
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
      expect(capturedData!.breakpoint, PortfolioBreakpoint.tablet);
      expect(capturedData!.screenWidth, 900);
    });

    testWidgets('provides desktop breakpoint for wide screens',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
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
      expect(capturedData!.screenWidth, 1440);
    });

    testWidgets('desktop content width does not exceed 1200px',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
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
      expect(capturedData!.contentWidth, lessThanOrEqualTo(1200));
    });

    testWidgets('tablet has at least 24px horizontal padding', (tester) async {
      tester.view.physicalSize = const Size(768, 800);
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
      expect(capturedData!.horizontalPadding, greaterThanOrEqualTo(24.0));
    });

    testWidgets('tablet margin does not exceed 5% of screen width',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
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
      expect(capturedData!.horizontalPadding,
          lessThanOrEqualTo(1000 * 0.05));
    });

    testWidgets('no horizontal overflow - content fits within screen width',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        width: 400,
        builder: (context, data) {
          return Container(
            width: double.infinity,
            height: 100,
            color: Colors.blue,
          );
        },
      ));

      // No overflow errors should be reported
      expect(tester.takeException(), isNull);
    });
  });

  group('computeHorizontalPadding', () {
    test('mobile returns 16px padding', () {
      final padding = PortfolioResponsiveLayout.computeHorizontalPadding(
        400,
        PortfolioBreakpoint.mobile,
      );
      expect(padding, 16.0);
    });

    test('tablet returns at least 24px', () {
      final padding = PortfolioResponsiveLayout.computeHorizontalPadding(
        768,
        PortfolioBreakpoint.tablet,
      );
      expect(padding, greaterThanOrEqualTo(24.0));
    });

    test('tablet returns max 5% of screen width', () {
      final padding = PortfolioResponsiveLayout.computeHorizontalPadding(
        1000,
        PortfolioBreakpoint.tablet,
      );
      expect(padding, lessThanOrEqualTo(1000 * 0.05));
    });

    test('desktop centers content with max 1200px', () {
      final padding = PortfolioResponsiveLayout.computeHorizontalPadding(
        1920,
        PortfolioBreakpoint.desktop,
      );
      // (1920 - 1200) / 2 = 360
      expect(padding, 360.0);
    });

    test('desktop with exactly 1200px width uses minimal padding', () {
      final padding = PortfolioResponsiveLayout.computeHorizontalPadding(
        1200,
        PortfolioBreakpoint.desktop,
      );
      // (1200 - 1200) / 2 = 0, but minimum is 24
      expect(padding, 24.0);
    });
  });

  group('computeContentWidth', () {
    test('desktop never exceeds 1200px', () {
      final width = PortfolioResponsiveLayout.computeContentWidth(
        1920,
        PortfolioBreakpoint.desktop,
      );
      expect(width, lessThanOrEqualTo(1200));
    });

    test('mobile content width is screen minus padding', () {
      final width = PortfolioResponsiveLayout.computeContentWidth(
        400,
        PortfolioBreakpoint.mobile,
      );
      // 400 - (16 * 2) = 368
      expect(width, 368.0);
    });

    test('tablet content width respects margins', () {
      final width = PortfolioResponsiveLayout.computeContentWidth(
        900,
        PortfolioBreakpoint.tablet,
      );
      final padding = PortfolioResponsiveLayout.computeHorizontalPadding(
        900,
        PortfolioBreakpoint.tablet,
      );
      expect(width, 900 - (padding * 2));
    });
  });

  group('PortfolioLayoutData', () {
    test('minTouchTarget is 44 for mobile', () {
      const data = PortfolioLayoutData(
        breakpoint: PortfolioBreakpoint.mobile,
        screenWidth: 400,
        contentWidth: 368,
        horizontalPadding: 16,
      );
      expect(data.minTouchTarget, 44.0);
    });

    test('minTouchTarget is 0 for tablet and desktop', () {
      const tabletData = PortfolioLayoutData(
        breakpoint: PortfolioBreakpoint.tablet,
        screenWidth: 900,
        contentWidth: 810,
        horizontalPadding: 45,
      );
      expect(tabletData.minTouchTarget, 0.0);

      const desktopData = PortfolioLayoutData(
        breakpoint: PortfolioBreakpoint.desktop,
        screenWidth: 1920,
        contentWidth: 1200,
        horizontalPadding: 360,
      );
      expect(desktopData.minTouchTarget, 0.0);
    });
  });

  group('PortfolioResponsiveImage', () {
    testWidgets('renders image with aspect ratio constraint', (tester) async {
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
    });

    testWidgets('uses BoxFit.contain by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: PortfolioResponsiveImage(
                imageProvider: AssetImage('assets/test.png'),
              ),
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });
  });
}
