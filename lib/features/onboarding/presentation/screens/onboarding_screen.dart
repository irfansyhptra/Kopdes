import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/theme/theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: AppAnimation.normal,
      curve: AppAnimation.defaultCurve,
    );
  }

  void _completeOnboarding() {
    ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isWelcome = _currentPage == 0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _currentPage < 3 ? 1.0 : 0.0,
                duration: AppAnimation.fast,
                child: IgnorePointer(
                  ignoring: _currentPage >= 3,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: Text(
                      'Lewati',
                      style: AppTypography.buttonSm.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage(
                    context,
                    imagePath: 'assets/images/onboarding/welcome_village.png',
                    title: 'Selamat Datang di Kopdes Merah Putih',
                    description:
                        'Platform Digital Koperasi Desa untuk UMKM, Marketplace, dan Pemberdayaan Ekonomi Masyarakat',
                    isWelcome: true,
                    screenHeight: screenHeight,
                  ),
                  _buildPage(
                    context,
                    imagePath: 'assets/images/onboarding/marketplace_umkm.png',
                    title: 'Marketplace Produk Desa',
                    description:
                        'Jelajahi berbagai produk UMKM lokal dan dukung ekonomi desa secara langsung.',
                    isWelcome: false,
                    screenHeight: screenHeight,
                  ),
                  _buildPage(
                    context,
                    imagePath: 'assets/images/onboarding/ai_coop_assistant.png',
                    title: 'Asisten AI Koperasi',
                    description:
                        'Kelola inventaris, analisis penjualan, rekomendasi produk, dan laporan koperasi dengan bantuan AI.',
                    isWelcome: false,
                    screenHeight: screenHeight,
                  ),
                  _buildPage(
                    context,
                    imagePath: 'assets/images/onboarding/smart_distribution.png',
                    title: 'Distribusi dan Monitoring',
                    description:
                        'Pantau pengiriman barang dengan validasi dua arah antara kurir dan penerima secara real-time.',
                    isWelcome: false,
                    screenHeight: screenHeight,
                  ),
                ],
              ),
            ),

            // Bottom Navigation Area
            Container(
              padding: EdgeInsets.all(screenWidth < 360 ? AppSpacing.md : AppSpacing.lg),
              child: isWelcome
                  ? _buildWelcomeAction(screenHeight)
                  : _buildStepAction(screenHeight, screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required String imagePath,
    required String title,
    required String description,
    required bool isWelcome,
    required double screenHeight,
  }) {
    // Dynamic image height based on screen size to prevent overflows
    final double imageHeight = screenHeight < 600
        ? screenHeight * 0.28
        : (screenHeight < 680 ? screenHeight * 0.32 : screenHeight * 0.4);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration container with soft shadow and high quality rounded layout
            Container(
              height: imageHeight,
              margin: EdgeInsets.only(bottom: screenHeight < 600 ? AppSpacing.md : AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.03),
                    offset: Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Text content
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: screenHeight < 600 ? 22 : 26,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              textAlign: TextAlign.center,
              style: (screenHeight < 600 ? AppTypography.bodyMedium : AppTypography.bodyLarge).copyWith(
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            // Extra spacing at the bottom
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // Large CTA action button for welcome slide
  Widget _buildWelcomeAction(double screenHeight) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(211, 47, 47, 0.15),
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: screenHeight < 600 ? 14 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Rounded 24px
          ),
        ),
        child: const Text(
          'Mulai',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // Stepper bottom layout with "Step X of 3", dot indicators, and buttons
  Widget _buildStepAction(double screenHeight, double screenWidth) {
    // Current step offset (1 to 3)
    final int stepIndex = _currentPage; // Welcome is index 0. Page 1, 2, 3 are step 1, 2, 3.
    final String stepLabel = 'Step $stepIndex of 3';
    final bool isLastStep = _currentPage == 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicator text (Step 1 of 3)
        Text(
          stepLabel,
          style: AppTypography.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Dot indicators and Next button row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dots
            Row(
              children: List.generate(3, (index) {
                // Page 1 matches index 0, Page 2 matches index 1, Page 3 matches index 2
                final isDotActive = (_currentPage - 1) == index;
                return AnimatedContainer(
                  duration: AppAnimation.fast,
                  margin: const EdgeInsets.only(right: 6),
                  height: 8,
                  width: isDotActive ? 18 : 8,
                  decoration: BoxDecoration(
                    color: isDotActive
                        ? AppColors.primary
                        : AppColors.hairline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            // Button (Lanjut or Mulai Sekarang)
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                      AppColors.primary.red,
                      AppColors.primary.green,
                      AppColors.primary.blue,
                      0.12,
                    ),
                    offset: const Offset(0, 6),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLastStep ? _completeOnboarding : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLastStep
                        ? (screenWidth < 360 ? 14 : 24)
                        : (screenWidth < 360 ? 20 : 32),
                    vertical: screenHeight < 600 ? 12 : 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24), // Rounded 24px
                  ),
                ),
                child: Text(
                  isLastStep ? 'Mulai Sekarang' : 'Lanjut',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
