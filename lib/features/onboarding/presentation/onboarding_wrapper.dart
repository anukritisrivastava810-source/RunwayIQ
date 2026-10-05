import 'package:flutter/material.dart';
import '../domain/models/onboarding_models.dart';
import '../data/repositories/onboarding_repository.dart';
import '../../company/data/repositories/company_repository.dart';
import '../../company/domain/models/company.dart';
import '../../investor/data/repositories/investor_repository.dart';
import '../../investor/domain/models/investor.dart';
import '../../funding/data/repositories/funding_round_repository.dart';
import '../../funding/domain/models/funding_round.dart';
import '../../../core/network/api_exceptions.dart';
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

  /// Maps the UI-friendly round string from [FundingStep] to
  /// the backend [FundingRoundType] enum value.
  FundingRoundType _parseFundingRoundType(String? uiRound) {
    switch (uiRound) {
      case 'Pre-seed':
        return FundingRoundType.preSeed;
      case 'Series A':
        return FundingRoundType.seriesA;
      case 'Series B':
        return FundingRoundType.seriesB;
      case 'Series C+':
        return FundingRoundType.seriesC;
      case 'Seed':
      default:
        return FundingRoundType.seed;
    }
  }

  /// Maps the company currency string (e.g. 'USD') to [FundingCurrency].
  FundingCurrency _parseFundingCurrency(String? currency) {
    return FundingCurrency.fromJson(currency);
  }

  Future<void> _finishOnboarding() async {
    // Guard: prevent duplicate submissions while already submitting.
    if (_isSubmitting) return;

    if (_onboardingData.company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company details are required.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ─── Step 1: Create Company ───────────────────────────────────────────
      final companyInput = Company.fromCompanyDetails(_onboardingData.company!);
      final createdCompany = await CompanyRepository().createCompany(companyInput);

      // Ensure the backend returned a valid ID.
      final companyId = createdCompany.id;
      if (companyId == null || companyId.isEmpty) {
        throw UnknownException('Company was created but no ID was returned from the server.');
      }

      // ─── Step 2: Investor + FundingRound (only if hasRaised == true) ──────
      final funding = _onboardingData.funding;
      if (funding != null && funding.hasRaised) {
        // 2a. Create Investor using the real company ID.
        final investorInput = Investor(
          companyId: companyId,
          name: (funding.investorName != null && funding.investorName!.isNotEmpty)
              ? funding.investorName!
              : 'Unknown Investor',
        );
        final createdInvestor = await InvestorRepository().createInvestor(investorInput);

        final investorId = createdInvestor.id;
        if (investorId == null || investorId.isEmpty) {
          throw UnknownException('Investor was created but no ID was returned from the server.');
        }

        // 2b. Create FundingRound using the real company ID + investor ID.
        final fundingRoundInput = FundingRound(
          companyId: companyId,
          investorId: investorId,
          roundType: _parseFundingRoundType(funding.round),
          amountRaised: funding.amount ?? 0.0,
          currency: _parseFundingCurrency(_onboardingData.company?.currency),
          equityPercent: funding.equityPercentage,
          closedAt: funding.investmentDate ?? DateTime.now(),
        );
        await FundingRoundRepository().createFundingRound(fundingRoundInput);
      }

      // ─── Step 3: Mark onboarding complete in local storage ───────────────
      await OnboardingRepository().completeOnboarding(_onboardingData);

      // ─── Step 4: Navigate to main app ────────────────────────────────────
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace created successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
