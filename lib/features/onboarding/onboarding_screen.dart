import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/onboarding/onboarding_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/onboarding_illustrations.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.illustration,
  });

  final String title;
  final String subtitle;
  final OnboardingIllustrationType illustration;
}

const _pages = [
  _OnboardingPage(
    title: 'Factura en segundos',
    subtitle:
        'Crea facturas profesionales, agrega productos y compártelas al instante con tus clientes.',
    illustration: OnboardingIllustrationType.invoices,
  ),
  _OnboardingPage(
    title: 'Controla tu ganancia',
    subtitle:
        'Visualiza márgenes y tendencias para tomar mejores decisiones en tu negocio.',
    illustration: OnboardingIllustrationType.profit,
  ),
  _OnboardingPage(
    title: 'Todo en un solo lugar',
    subtitle:
        'Clientes, productos, usuarios y reportes conectados en una experiencia fluida.',
    illustration: OnboardingIllustrationType.business,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _finish() async {
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          AppColors.darkBackground,
                          AppColors.darkSurface,
                        ]
                      : [
                          AppColors.lightBackground,
                          AppColors.lightSurface,
                        ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    8,
                    AppSpacing.page,
                    0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppDecorations.brandGradient(theme.brightness),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppConfig.appName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Omitir'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutCubic,
                              child: OnboardingIllustration(
                                key: ValueKey(page.illustration),
                                type: page.illustration,
                                size: size.width * 0.68,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              page.subtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.55,
                              ),
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    AppSpacing.section,
                  ),
                  child: Column(
                    children: [
                      _PageIndicator(
                        count: _pages.length,
                        current: _currentPage,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _next,
                        child: Text(_isLastPage ? 'Comenzar' : 'Siguiente'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive
                ? AppColors.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        );
      }),
    );
  }
}
