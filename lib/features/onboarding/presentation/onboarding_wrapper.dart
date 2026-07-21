import 'package:flutter/material.dart';
import '../domain/models/onboarding_models.dart';
import '../data/repositories/onboarding_repository.dart';
import 'steps/welcome_step.dart';
import 'steps/company_info_step.dart';
import 'steps/financial_setup_step.dart';
import 'steps/team_setup_step.dart';
import 'steps/funding_step.dart';
import 'steps/treasury_step.dart';
import 'steps/review_step.dart';
import '../../../screens/main_layout.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  final OnboardingData _onboardingData = OnboardingData();
  bool _isSubmitting = false;

  void _nextStep() {
    if (_currentIndex < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _isSubmitting = true;
    });
    
    await OnboardingRepository().completeOnboarding(_onboardingData);
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _previousStep,
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _currentIndex / 6,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  WelcomeStep(onNext: _nextStep),
                  CompanyInfoStep(
                    data: _onboardingData,
                    onNext: _nextStep,
                  ),
                  FinancialSetupStep(
                    data: _onboardingData,
                    onNext: _nextStep,
                  ),
                  TeamSetupStep(
                    data: _onboardingData,
                    onNext: _nextStep,
                  ),
                  FundingStep(
                    data: _onboardingData,
                    onNext: _nextStep,
                  ),
                  TreasuryStep(
                    data: _onboardingData,
                    onNext: _nextStep,
                  ),
                  ReviewStep(
                    data: _onboardingData,
                    isSubmitting: _isSubmitting,
                    onFinish: _finishOnboarding,
                    onEdit: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
